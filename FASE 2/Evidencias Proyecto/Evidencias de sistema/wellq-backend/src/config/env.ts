import "dotenv/config";
import { z } from "zod";

const environmentSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z
    .string()
    .min(1)
    .default("postgresql://wellq:wellq_local@localhost:5432/wellq"),
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace", "silent"]).default("info"),
  JWT_SECRET: z.string().min(32).default("wellq_local_secret_change_before_production_2026"),
  JWT_EXPIRES_IN: z.string().default("8h"),
  STORAGE_PATH: z.string().min(1).default("storage"),
  S3_ENDPOINT: z.string().url().default("http://localhost:9000"),
  S3_REGION: z.string().min(1).default("us-east-1"),
  S3_ACCESS_KEY: z.string().min(1).default("wellq"),
  S3_SECRET_KEY: z.string().min(8).default("wellq_local_secret"),
  S3_BUCKET: z.string().min(3).default("wellq-exams"),
  S3_FORCE_PATH_STYLE: z.coerce.boolean().default(true),
  MAX_EXAM_FILE_MB: z.coerce.number().positive().max(50).default(10),
  MAX_CLINICAL_FILE_BYTES: z.coerce.number().int().positive().max(50 * 1024 * 1024).default(20 * 1024 * 1024),
  CLAMAV_HOST: z.string().min(1).default("127.0.0.1"),
  CLAMAV_PORT: z.coerce.number().int().positive().max(65535).default(3310)
}).superRefine((value, context) => {
  if (value.NODE_ENV === "production") {
    if (value.JWT_SECRET === "wellq_local_secret_change_before_production_2026") {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ["JWT_SECRET"], message: "Configura un secreto JWT propio en producción." });
    }
    if (value.DATABASE_URL.includes("wellq_local@")) {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ["DATABASE_URL"], message: "Configura credenciales de PostgreSQL propias en producción." });
    }
    if (value.S3_SECRET_KEY === "wellq_local_secret") {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ["S3_SECRET_KEY"], message: "Configura credenciales S3 propias en producción." });
    }
  }
});

const parsed = environmentSchema.safeParse(process.env);

if (!parsed.success) {
  throw new Error(`Configuración inválida: ${parsed.error.message}`);
}

export const env = parsed.data;
