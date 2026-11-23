import "dotenv/config";
import pg from "pg";
import bcrypt from "bcryptjs";

const email = "paciente.a@wellq.test";

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});

try {
  await client.connect();

  const result = await client.query(
    `SELECT u.password_hash
       FROM public.users u
       JOIN public.clients c ON c.id = u.client_id
      WHERE LOWER(u.email) = LOWER($1)
        AND c.code = 'WELLQ-DEMO'
        AND u.active = true`,
    [email]
  );

  if (result.rows.length !== 1) {
    console.log("No se encontró exactamente una cuenta activa.");
  } else {
    const password = process.env.WELLQ_TEST_PASSWORD;

    if (!password) {
      console.log("No se proporcionó una contraseña de prueba.");
    } else {
      const coincide = await bcrypt.compare(
        password,
        result.rows[0].password_hash
      );

      console.log(
        coincide
          ? "RESULTADO: CONTRASEÑA CORRECTA"
          : "RESULTADO: CONTRASEÑA NO COINCIDE"
      );
    }
  }
} catch (error) {
  console.error("Error durante la verificación:", error.message);
} finally {
  await client.end().catch(() => {});
}
