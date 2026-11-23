import { createHash, randomUUID } from "node:crypto";
import { readFile, unlink } from "node:fs/promises";
import { extname, resolve, sep } from "node:path";
import { DeleteObjectCommand, GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { env } from "../config/env.js";

const storageRoot = resolve(env.STORAGE_PATH);
const s3 = new S3Client({
  endpoint: env.S3_ENDPOINT,
  region: env.S3_REGION,
  forcePathStyle: env.S3_FORCE_PATH_STYLE,
  credentials: { accessKeyId: env.S3_ACCESS_KEY, secretAccessKey: env.S3_SECRET_KEY }
});

export async function storeExamFile(
  clientId: string,
  examId: string,
  file: Express.Multer.File
): Promise<{ objectKey: string; sha256: string }> {
  const extension = extname(file.originalname).toLowerCase();
  const storedName = `${randomUUID()}${extension}`;
  const objectKey = `${clientId}/${examId}/${storedName}`;
  const sha256 = createHash("sha256").update(file.buffer).digest("hex");

  await s3.send(new PutObjectCommand({
    Bucket: env.S3_BUCKET,
    Key: objectKey,
    Body: file.buffer,
    ContentType: file.mimetype,
    Metadata: { sha256 }
  }));

  return { objectKey, sha256 };
}

function legacyStoredPath(objectKey: string): string {
  const absolutePath = resolve(storageRoot, objectKey);
  if (absolutePath !== storageRoot && !absolutePath.startsWith(`${storageRoot}${sep}`)) {
    throw new Error("Ruta de archivo inválida.");
  }
  return absolutePath;
}

export async function getStoredFile(objectKey: string): Promise<Buffer> {
  try {
    const result = await s3.send(new GetObjectCommand({ Bucket: env.S3_BUCKET, Key: objectKey }));
    if (!result.Body) throw new Error("El archivo almacenado no tiene contenido.");
    return Buffer.from(await result.Body.transformToByteArray());
  } catch (error) {
    // Compatibilidad con archivos creados antes de habilitar MinIO.
    try {
      return await readFile(legacyStoredPath(objectKey));
    } catch {
      throw error;
    }
  }
}

export async function deleteStoredFile(objectKey: string): Promise<void> {
  await s3.send(new DeleteObjectCommand({ Bucket: env.S3_BUCKET, Key: objectKey }));
  // También retira una posible copia creada antes de la migración a MinIO.
  await unlink(legacyStoredPath(objectKey)).catch(() => undefined);
}
