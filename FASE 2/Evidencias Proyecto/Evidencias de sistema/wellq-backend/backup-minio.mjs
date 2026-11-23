import fs from "node:fs";
import path from "node:path";
import { S3Client, ListObjectsV2Command, GetObjectCommand } from "@aws-sdk/client-s3";

const env = Object.fromEntries(
  fs.readFileSync(".env", "utf8")
    .split(/\r?\n/)
    .filter(line => line.trim() && !line.trim().startsWith("#"))
    .map(line => {
      const index = line.indexOf("=");
      return [line.slice(0, index), line.slice(index + 1).trim()];
    })
    .filter(([key]) => key)
);

const bucket = env.S3_BUCKET;
const destination = path.resolve("respaldos", "minio-wellq-exams");

const s3 = new S3Client({
  endpoint: env.S3_ENDPOINT,
  region: env.S3_REGION || "us-east-1",
  credentials: {
    accessKeyId: env.S3_ACCESS_KEY,
    secretAccessKey: env.S3_SECRET_KEY
  },
  forcePathStyle: true
});

let continuationToken;
let total = 0;
let bytes = 0;

do {
  const result = await s3.send(new ListObjectsV2Command({
    Bucket: bucket,
    ContinuationToken: continuationToken
  }));

  for (const object of result.Contents || []) {
    const key = object.Key;
    if (!key || key.endsWith("/")) continue;

    const target = path.resolve(destination, ...key.split("/"));

    if (!target.startsWith(destination + path.sep)) {
      throw new Error("Ruta de archivo no permitida");
    }

    fs.mkdirSync(path.dirname(target), { recursive: true });

    const response = await s3.send(new GetObjectCommand({
      Bucket: bucket,
      Key: key
    }));

    const content = Buffer.from(await response.Body.transformToByteArray());
    if (content.length !== Number(object.Size)) {
      throw new Error(`Tamaño incorrecto: ${key}`);
    }

    fs.writeFileSync(target, content, { flag: "wx" });

    total++;
    bytes += content.length;
    console.log(`Respaldado: ${key}`);
  }

  continuationToken = result.NextContinuationToken;
} while (continuationToken);

console.log(`Respaldo finalizado: ${total} archivos, ${bytes} bytes`);
console.log(`Ubicación: ${destination}`);
