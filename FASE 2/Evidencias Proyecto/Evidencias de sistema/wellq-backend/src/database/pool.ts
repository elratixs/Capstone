import { Pool } from "pg";
import { env } from "../config/env.js";

export const database = new Pool({
  connectionString: env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000
});

database.on("connect", async (client) => {
  await client.query("SET TIME ZONE 'UTC'");
});
