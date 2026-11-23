import "dotenv/config";
import pg from "pg";

const url = process.env.DATABASE_URL;

if (!url) {
  console.log("DATABASE_URL no está definida en este proceso.");
  process.exit(1);
}

const config = new URL(url);

console.log("Host:", config.hostname);
console.log("Puerto:", config.port || "5432");
console.log("Base configurada:", config.pathname.slice(1));
console.log("Usuario:", decodeURIComponent(config.username));

const client = new pg.Client({
  connectionString: url,
});

try {
  await client.connect();

  const result = await client.query(`
    SELECT
      current_database() AS base,
      current_user AS usuario,
      inet_server_port() AS puerto,
      (
        SELECT COUNT(*)
        FROM public.users
        WHERE LOWER(email) IN (
          'paciente.a@wellq.test',
          'paciente.b@wellq.test',
          'paciente.c@wellq.test'
        )
      ) AS pacientes_encontrados
  `);

  console.table(result.rows);
} catch (error) {
  console.error("No fue posible verificar la conexión:", error.message);
} finally {
  await client.end().catch(() => {});
}
