const bcrypt = require("bcryptjs");
const { Client } = require("pg");

async function main() {
  const password = process.env.WELLQ_PASSWORD_CHECK;
  if (!password) {
    console.log("Falta la contraseña de prueba");
    return;
  }

  const db = new Client({
    connectionString: process.env.DATABASE_URL
  });

  try {
    await db.connect();

    const result = await db.query(
      `SELECT u.password_hash
       FROM users u
       JOIN clients c ON c.id = u.client_id
       WHERE c.code = $1
         AND lower(u.email) = lower($2)
         AND u.active = true`,
      ["WELLQ-DEMO", "fuentealex@gmail.com"]
    );

    console.log("Usuarios encontrados:", result.rows.length);

    if (result.rows.length !== 1) return;

    const coincide = await bcrypt.compare(
      password,
      result.rows[0].password_hash
    );

    console.log("Bcrypt coincide:", coincide);

    const response = await fetch(
      "http://localhost:3000/api/v1/auth/login",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          clientCode: "WELLQ-DEMO",
          email: "fuentealex@gmail.com",
          password
        })
      }
    );

    console.log("HTTP login:", response.status);
  } finally {
    await db.end();
  }
}

main().catch(() => {
  console.log("Error durante la prueba");
  process.exitCode = 1;
});
