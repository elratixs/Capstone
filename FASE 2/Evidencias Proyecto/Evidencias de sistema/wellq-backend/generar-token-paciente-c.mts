import { writeFileSync } from "node:fs";
import { createActivationToken } from "./src/auth/account-activation.service.js";
import { database } from "./src/database/pool.js";

const userId = "f626d242-dd37-4b25-bf2b-90097d651464";

try {
  const token = await createActivationToken(userId);

  const destination = process.env.WELLQ_TOKEN_FILE;

  if (!destination) {
    throw new Error("Falta la ruta privada del archivo.");
  }

  writeFileSync(destination, token, {
    encoding: "utf8",
    mode: 0o600,
    flag: "w"
  });

  console.log("Token de activación generado y guardado correctamente.");
  console.log("Vigencia: 24 horas.");
} catch {
  console.error("No fue posible generar el token de activación.");
  process.exitCode = 1;
} finally {
  await database.end();
}

