import { createApp } from "./app.js";
import { env } from "./config/env.js";
import { database } from "./database/pool.js";
import { startClinicalValidationWorker } from "./exams/clinical-validation-worker.js";

const app = createApp();
const clinicalValidationWorker = startClinicalValidationWorker();
const server = app.listen(env.PORT, () => {
  console.log(`WellQ API disponible en http://localhost:${env.PORT}`);
});

async function shutdown(signal: string): Promise<void> {
  console.log(`${signal} recibido; cerrando WellQ API.`);
  clearInterval(clinicalValidationWorker);
  server.close(async () => {
    await database.end();
    process.exit(0);
  });
}

process.on("SIGINT", () => void shutdown("SIGINT"));
process.on("SIGTERM", () => void shutdown("SIGTERM"));
