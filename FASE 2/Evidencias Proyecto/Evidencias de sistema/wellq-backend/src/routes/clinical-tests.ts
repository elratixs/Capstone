import { HeadObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { recordAudit } from "../audit/audit.service.js";
import { env } from "../config/env.js";
import { database } from "../database/pool.js";
import { authenticate } from "../middleware/authenticate.js";

const s3 = new S3Client({ requestChecksumCalculation: "WHEN_REQUIRED", endpoint: env.S3_ENDPOINT, region: env.S3_REGION, forcePathStyle: env.S3_FORCE_PATH_STYLE, credentials: { accessKeyId: env.S3_ACCESS_KEY, secretAccessKey: env.S3_SECRET_KEY } });
const fileTypes: Record<string, string> = { pdf: "application/pdf", jpg: "image/jpeg", jpeg: "image/jpeg", png: "image/png", heic: "image/heic" };
const bodySchema = z.object({
  client_upload_id: z.string().uuid(), file_name: z.string().trim().min(1).max(255),
  mime_type: z.enum(["application/pdf", "image/jpeg", "image/png", "image/heic"]),
  size_bytes: z.number().int().positive().max(env.MAX_CLINICAL_FILE_BYTES), sha256: z.string().regex(/^[a-f0-9]{64}$/),
  test_type: z.string().trim().min(1).max(80), title: z.string().trim().min(1).max(200),
  test_date: z.string().date(), notes: z.string().trim().max(2000).nullable().optional(),
  case_id: z.string().nullable().optional(), appointment_id: z.string().nullable().optional()
}).strict();
const idempotencySchema = z.string().uuid();
export const clinicalTestsRouter = Router();
clinicalTestsRouter.use(authenticate);

function requirePatient(request: Request, response: Response): { clientId: string; patientId: string } | null {
  const auth = request.context.auth;
  if (!auth) { response.status(401).json({ error: { code: "UNAUTHORIZED", message: "Inicia sesión para continuar." } }); return null; }
  if (!auth.patientId || !auth.roles.some((role) => ["patient", "Paciente"].includes(role))) {
    response.status(403).json({ error: { code: "FORBIDDEN", message: "La cuenta no tiene acceso de paciente vinculado." } }); return null;
  }
  return { clientId: auth.clientId, patientId: auth.patientId };
}

async function createUploadUrl(objectKey: string, mimeType: string, checksum: string) {
  const command = new PutObjectCommand({ Bucket: env.S3_BUCKET, Key: objectKey, ContentType: mimeType, Metadata: { sha256: checksum } });
  const signedUrl = await getSignedUrl(s3, command, { expiresIn: 15 * 60, unhoistableHeaders: new Set(["x-amz-meta-sha256"]) });
  return { method: "PUT", signed_url: signedUrl, required_headers: { "Content-Type": mimeType, "x-amz-meta-sha256": checksum }, expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString() };
}

clinicalTestsRouter.post("/uploads/initiate", async (request, response, next) => {
  const identity = requirePatient(request, response); if (!identity) return;
  const parsed = bodySchema.safeParse(request.body);
  const idem = idempotencySchema.safeParse(request.header("Idempotency-Key"));
  if (!parsed.success || !idem.success) { response.status(400).json({ error: { code: "INVALID_METADATA", message: "Revisa los datos, el archivo y la cabecera Idempotency-Key." } }); return; }
  const value = parsed.data;
  if (new Date(value.test_date) > new Date(new Date().toISOString().slice(0, 10))) { response.status(400).json({ error: { code: "INVALID_METADATA", message: "La fecha del examen no puede ser futura." } }); return; }
  const extension = value.file_name.split(".").pop()?.toLowerCase() ?? "";
  if (fileTypes[extension] !== value.mime_type) { response.status(400).json({ error: { code: "INVALID_METADATA", message: "La extensión y el tipo de archivo no coinciden." } }); return; }
  if (value.case_id || value.appointment_id) { response.status(403).json({ error: { code: "ASSOCIATION_NOT_OWNED", message: "No se pudo validar la asociación clínica." } }); return; }
  try {
    const patient = await database.query("SELECT id FROM patients WHERE client_id = $1 AND id = $2 AND deleted_at IS NULL", [identity.clientId, identity.patientId]);
    if (!patient.rowCount) { response.status(403).json({ error: { code: "FORBIDDEN", message: "Paciente no autorizado." } }); return; }
    const existing = await database.query<any>(`SELECT * FROM clinical_tests WHERE client_id = $1 AND patient_id = $2 AND (client_upload_id = $3 OR idempotency_key = $4) AND deleted_at IS NULL LIMIT 1`, [identity.clientId, identity.patientId, value.client_upload_id, idem.data]);
    let row = existing.rows[0];
    if (row) {
      if (row.client_upload_id !== value.client_upload_id || row.idempotency_key !== idem.data || row.sha256.trim() !== value.sha256 || Number(row.size_bytes) !== value.size_bytes || row.mime_type !== value.mime_type) { response.status(409).json({ error: { code: "UPLOAD_CONFLICT", message: "La clave de reintento ya se usó con otro archivo." } }); return; }
      if (!["initiated", "failed"].includes(row.status)) { response.status(409).json({ error: { code: "UPLOAD_NOT_REFRESHABLE", message: "La carga ya fue completada." } }); return; }
    } else {
      const { randomUUID } = await import("node:crypto");
      const uploadId = randomUUID();
      const objectKey = `quarantine/${identity.clientId}/${identity.patientId}/clinical-tests/${uploadId}/original`;
      const inserted = await database.query<any>(`INSERT INTO clinical_tests (client_id, patient_id, upload_id, client_upload_id, idempotency_key, file_name, mime_type, size_bytes, sha256, test_type, title, test_date, notes, object_key, upload_expires_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,now()+interval '15 minutes') RETURNING *`, [identity.clientId, identity.patientId, uploadId, value.client_upload_id, idem.data, value.file_name, value.mime_type, value.size_bytes, value.sha256, value.test_type, value.title, value.test_date, value.notes ?? null, objectKey]);
      row = inserted.rows[0];
    }
    const upload = await createUploadUrl(row.object_key, row.mime_type, row.sha256.trim());
    await recordAudit(request, { action: "CLINICAL_TEST_UPLOAD_INITIATE", resourceType: "clinical_test", resourceId: row.id, statusCode: 201, success: true });
    response.status(existing.rowCount ? 200 : 201).json({ upload_id: row.upload_id, clinical_test_id: row.id, status: row.status, upload });
  } catch (error) { next(error); }
});

clinicalTestsRouter.post("/uploads/:uploadId/refresh-url", async (request, response, next) => {
  const identity = requirePatient(request, response); if (!identity) return;
  const idem = idempotencySchema.safeParse(request.header("Idempotency-Key"));
  const body = z.object({ client_upload_id: z.string().uuid(), sha256: z.string().regex(/^[a-f0-9]{64}$/) }).safeParse(request.body);
  if (!idem.success || !body.success) { response.status(400).json({ error: { code: "INVALID_METADATA", message: "Solicitud de renovación inválida." } }); return; }
  try {
    const result = await database.query<any>(`SELECT * FROM clinical_tests WHERE client_id=$1 AND patient_id=$2 AND upload_id=$3 AND client_upload_id=$4 AND deleted_at IS NULL`, [identity.clientId, identity.patientId, request.params.uploadId, body.data.client_upload_id]);
    const row = result.rows[0];
    if (!row) { response.status(404).json({ error: { code: "UPLOAD_NOT_FOUND", message: "Carga no encontrada." } }); return; }
    if (row.sha256.trim() !== body.data.sha256 || !["initiated", "failed"].includes(row.status)) { response.status(409).json({ error: { code: "UPLOAD_NOT_REFRESHABLE", message: "La carga no se puede renovar." } }); return; }
    const upload = await createUploadUrl(row.object_key, row.mime_type, row.sha256.trim());
    await database.query(`UPDATE clinical_tests SET upload_expires_at=$1, updated_at=now() WHERE client_id=$2 AND id=$3`, [upload.expires_at, identity.clientId, row.id]);
    await recordAudit(request, { action: "CLINICAL_TEST_UPLOAD_REFRESH_URL", resourceType: "clinical_test", resourceId: row.id, statusCode: 200, success: true });
    response.json({ upload_id: row.upload_id, status: row.status, upload });
  } catch (error) { next(error); }
});

clinicalTestsRouter.post("/uploads/:uploadId/complete", async (request, response, next) => {
  const identity = requirePatient(request, response); if (!identity) return;
  const idem = idempotencySchema.safeParse(request.header("Idempotency-Key"));
  const body = z.object({ client_upload_id: z.string().uuid(), sha256: z.string().regex(/^[a-f0-9]{64}$/), size_bytes: z.number().int().positive() }).strict().safeParse(request.body);
  if (!idem.success || !body.success) { response.status(400).json({ error: { code: "INVALID_METADATA", message: "Solicitud de finalización inválida." } }); return; }
  try {
    const result = await database.query<any>(`SELECT * FROM clinical_tests WHERE client_id=$1 AND patient_id=$2 AND upload_id=$3 AND client_upload_id=$4 AND deleted_at IS NULL`, [identity.clientId, identity.patientId, request.params.uploadId, body.data.client_upload_id]);
    const row = result.rows[0];
    if (!row) { response.status(404).json({ error: { code: "UPLOAD_NOT_FOUND", message: "Carga no encontrada." } }); return; }
    if (row.sha256.trim() !== body.data.sha256 || Number(row.size_bytes) !== body.data.size_bytes) { response.status(409).json({ error: { code: "UPLOAD_CONFLICT", message: "El archivo no coincide con lo declarado al iniciar." } }); return; }
    const object = await s3.send(new HeadObjectCommand({ Bucket: env.S3_BUCKET, Key: row.object_key }));
    if (Number(object.ContentLength) !== Number(row.size_bytes) || String(object.Metadata?.sha256 ?? "") !== row.sha256.trim()) { response.status(409).json({ error: { code: "OBJECT_MISMATCH", message: "El archivo almacenado no coincide con la carga iniciada." } }); return; }
    if (row.status === "ready_for_review") { response.json({ clinical_test_id: row.id, upload_id: row.upload_id, status: row.status, local_file_can_be_deleted: true, status_url: `/api/v1/clinical-tests/uploads/${row.upload_id}/status` }); return; }
    const updated = await database.query(`UPDATE clinical_tests SET status='processing', updated_at=now() WHERE client_id=$1 AND id=$2 AND status IN ('initiated','failed') RETURNING id`, [identity.clientId, row.id]);
    if (updated.rowCount) await database.query(`INSERT INTO clinical_validation_jobs (client_id, clinical_test_id) VALUES ($1,$2) ON CONFLICT (client_id, clinical_test_id) DO UPDATE SET status='pending', available_at=now(), locked_at=NULL`, [identity.clientId, row.id]);
    await recordAudit(request, { action: "CLINICAL_TEST_UPLOAD_COMPLETE", resourceType: "clinical_test", resourceId: row.id, statusCode: 202, success: true });
    response.status(202).json({ clinical_test_id: row.id, upload_id: row.upload_id, status: "processing", local_file_can_be_deleted: false, status_url: `/api/v1/clinical-tests/uploads/${row.upload_id}/status` });
  } catch (error: any) {
    if (error?.$metadata?.httpStatusCode === 404) { response.status(409).json({ error: { code: "OBJECT_MISSING", message: "El archivo todavía no está disponible en almacenamiento." } }); return; }
    next(error);
  }
});

clinicalTestsRouter.get("/uploads/:uploadId/status", async (request, response, next) => {
  const identity = requirePatient(request, response); if (!identity) return;
  try {
    const result = await database.query<any>(`SELECT id, upload_id, status, updated_at FROM clinical_tests WHERE client_id=$1 AND patient_id=$2 AND upload_id=$3 AND deleted_at IS NULL`, [identity.clientId, identity.patientId, request.params.uploadId]);
    const row = result.rows[0];
    if (!row) { response.status(404).json({ error: { code: "UPLOAD_NOT_FOUND", message: "Carga no encontrada." } }); return; }
    response.json({ clinical_test_id: row.id, upload_id: row.upload_id, status: row.status, local_file_can_be_deleted: row.status === "ready_for_review", completed_at: row.status === "ready_for_review" ? row.updated_at : null });
  } catch (error) { next(error); }
});
