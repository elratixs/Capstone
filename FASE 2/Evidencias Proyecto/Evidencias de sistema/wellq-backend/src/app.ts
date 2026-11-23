import cors from "cors";
import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";
import { env } from "./config/env.js";
import { errorHandler } from "./middleware/error-handler.js";
import { requestContext } from "./middleware/request-context.js";
import { healthRouter } from "./routes/health.js";
import { authRouter } from "./routes/auth.js";
import { patientsRouter } from "./routes/patients.js";
import { examsRouter } from "./routes/exams.js";
import { openApiDocument } from "./openapi.js";
import { auditRouter } from "./routes/audit.js";
import { clinicalTestsRouter } from "./routes/clinical-tests.js";
import { clinicalTestManagementRouter } from "./routes/clinical-test-management.js";
import { requireFeature } from "./middleware/feature-gating.js";
import { authenticate } from "./middleware/authenticate.js";

export function createApp() {
  const app = express();

  app.disable("x-powered-by");
  app.set("etag", false);
  app.use(helmet());
  app.use(cors());
  // Clinical records must not be cached by the browser. Besides privacy,
  // this avoids empty 304 bodies breaking JSON decoding in the Flutter client.
  app.use((_request, response, next) => {
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, private");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");
    next();
  });
  app.use(express.json({ limit: "1mb" }));
  app.use(pinoHttp({ level: env.LOG_LEVEL }));
  app.use(requestContext);

  app.use("/api/v1/health", healthRouter);
  app.use("/api/v1/auth", authRouter);
  app.use("/api/v1/patients", patientsRouter);
  app.use("/api/v1/exams", examsRouter);
  app.use("/api/v1/audit", auditRouter);
  app.use("/api/v1/clinical-tests", authenticate, requireFeature("clinical_test_upload", ["patient", "Paciente", "clinician", "Clinico", "Clínico", "Profesional"]));
  app.use("/api/v1/clinical-tests", clinicalTestsRouter);
  app.use("/api/v1/clinical-tests", clinicalTestManagementRouter);
  app.get("/api/v1/openapi.json", (_request, response) => response.json(openApiDocument));
  // The schema migration is shipped as database/003_clinical_results.sql.

  app.use((_request, response) => {
    response.status(404).json({
      error: { code: "NOT_FOUND", message: "Recurso no encontrado." }
    });
  });

  app.use(errorHandler);
  return app;
}
