import { CopyObjectCommand, DeleteObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { randomUUID } from "node:crypto";
import { env } from "../config/env.js";
import { database } from "../database/pool.js";
import { getStoredFile } from "./file-storage.service.js";
import { scanWithClamAv, verifyClinicalFile } from "./clinical-file-validation.service.js";

let running = false;
const s3 = new S3Client({ endpoint: env.S3_ENDPOINT, region: env.S3_REGION, forcePathStyle: env.S3_FORCE_PATH_STYLE, credentials: { accessKeyId: env.S3_ACCESS_KEY, secretAccessKey: env.S3_SECRET_KEY } });

async function auditValidation(clientId: string, testId: string, success: boolean, result: string): Promise<void> {
  await database.query(`INSERT INTO audit_logs (client_id,user_role,action,resource_type,resource_id,status_code,success,request_id,metadata) VALUES ($1,'system','CLINICAL_TEST_VALIDATION','clinical_test',$2,$3,$4,$5,$6)`, [clientId,testId,success ? 200 : 422,success,randomUUID(),{ result }]);
}

async function processNextClinicalValidation(): Promise<void> {
  if (running) return;
  running = true;
  let job: { id: string; client_id: string; clinical_test_id: string } | undefined;
  try {
    const client = await database.connect();
    try {
      await client.query("BEGIN");
      const selected = await client.query<{ id: string; client_id: string; clinical_test_id: string }>(
        `SELECT id, client_id, clinical_test_id FROM clinical_validation_jobs
          WHERE (status IN ('pending','retry') OR (status='running' AND locked_at < now()-interval '60 seconds')) AND available_at <= now()
          ORDER BY created_at FOR UPDATE SKIP LOCKED LIMIT 1`
      );
      job = selected.rows[0];
      if (job) await client.query(
        `UPDATE clinical_validation_jobs SET status='running', attempts=attempts+1, locked_at=now()
          WHERE id=$1`, [job.id]
      );
      await client.query("COMMIT");
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
    if (!job) return;

    const selectedTest = await database.query<{ object_key: string; mime_type: string; sha256: string }>(
      `SELECT object_key, mime_type, sha256 FROM clinical_tests WHERE client_id=$1 AND id=$2 AND deleted_at IS NULL`,
      [job.client_id, job.clinical_test_id]
    );
    const test = selectedTest.rows[0];
    if (!test) {
      await database.query(`UPDATE clinical_validation_jobs SET status='complete', locked_at=NULL WHERE id=$1`, [job.id]);
      return;
    }
    const contents = await getStoredFile(test.object_key);
    if (!verifyClinicalFile(contents, test.mime_type, test.sha256.trim())) {
      await database.query(`UPDATE clinical_tests SET status='rejected', updated_at=now() WHERE client_id=$1 AND id=$2`, [job.client_id, job.clinical_test_id]);
      await database.query(`UPDATE clinical_validation_jobs SET status='complete', locked_at=NULL, last_error='file_validation_failed' WHERE id=$1`, [job.id]);
      await auditValidation(job.client_id, job.clinical_test_id, false, "file_validation_failed");
      return;
    }
    const clean = await scanWithClamAv(contents);
    if (clean) {
      const destinationKey = test.object_key.replace(/^quarantine\//, "private/");
      const copySource = `${env.S3_BUCKET}/${test.object_key.split("/").map(encodeURIComponent).join("/")}`;
      await s3.send(new CopyObjectCommand({ Bucket: env.S3_BUCKET, Key: destinationKey, CopySource: copySource }));
      await database.query(`UPDATE clinical_tests SET object_key=$1,status='ready_for_review',updated_at=now() WHERE client_id=$2 AND id=$3`, [destinationKey,job.client_id,job.clinical_test_id]);
      await s3.send(new DeleteObjectCommand({ Bucket: env.S3_BUCKET, Key: test.object_key })).catch(() => undefined);
    } else {
      await database.query(`UPDATE clinical_tests SET status='rejected', updated_at=now() WHERE client_id=$1 AND id=$2`, [job.client_id, job.clinical_test_id]);
    }
    await database.query(`UPDATE clinical_validation_jobs SET status='complete', locked_at=NULL, last_error=$1 WHERE id=$2`, [clean ? null : "malware_detected", job.id]);
    await auditValidation(job.client_id, job.clinical_test_id, clean, clean ? "passed" : "malware_detected");
  } catch (error) {
    if (job) await database.query(
      `UPDATE clinical_validation_jobs SET status='retry', locked_at=NULL, available_at=now()+interval '30 seconds', last_error=$1 WHERE id=$2`,
      [error instanceof Error ? error.name : "validation_failed", job.id]
    ).catch(() => undefined);
  } finally {
    running = false;
  }
}

export function startClinicalValidationWorker(): NodeJS.Timeout {
  void processNextClinicalValidation();
  return setInterval(() => void processNextClinicalValidation(), 3_000);
}
