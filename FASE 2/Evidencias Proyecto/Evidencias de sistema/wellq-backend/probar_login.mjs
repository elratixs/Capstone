
import "dotenv/config";
import readline from "node:readline/promises";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const password = await rl.question(
  "Contraseña del paciente A: "
);

rl.close();

try {
  const response = await fetch(
    "http://localhost:3000/api/v1/auth/login",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        clientCode: "WELLQ-DEMO",
        email: "paciente.a@wellq.test",
        password
      })
    }
  );

  console.log("RESULTADO HTTP:", response.status);

  if (response.ok) {
    console.log("LOGIN CORRECTO");
  } else {
    console.log("LOGIN RECHAZADO");
  }
} catch (error) {
  console.log("ERROR DE CONEXIÓN:", error.message);
}
