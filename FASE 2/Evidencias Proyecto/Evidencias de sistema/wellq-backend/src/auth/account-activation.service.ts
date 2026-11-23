import { randomBytes, createHash } from "node:crypto";
import { database } from "../database/pool.js";

export function hashActivationToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export async function createActivationToken(
  userId: string
): Promise<string> {
  const token = randomBytes(32).toString("hex");
  const tokenHash = hashActivationToken(token);

  const client = await database.connect();

  try {
    await client.query("BEGIN");

    await client.query(
      `UPDATE user_activation_tokens
          SET used_at = NOW()
        WHERE user_id = $1
          AND purpose = 'activation'
          AND used_at IS NULL`,
      [userId]
    );

    await client.query(
      `INSERT INTO user_activation_tokens
         (user_id, token_hash, purpose, expires_at)
       VALUES ($1, $2, 'activation', NOW() + INTERVAL '24 hours')`,
      [userId, tokenHash]
    );

    await client.query("COMMIT");

    return token;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

import bcrypt from "bcryptjs";

export async function activatePatientAccount(
  token: string,
  password: string
): Promise<boolean> {
  if (!/^[a-f0-9]{64}$/.test(token) || password.length < 12 || password.length > 128) {
    return false;
  }

  const tokenHash = hashActivationToken(token);
  const client = await database.connect();

  try {
    await client.query("BEGIN");

    const result = await client.query<{
      id: string;
      user_id: string;
    }>(
      `SELECT id, user_id
         FROM user_activation_tokens
        WHERE token_hash = $1
          AND purpose = 'activation'
          AND used_at IS NULL
          AND expires_at > NOW()
        FOR UPDATE`,
      [tokenHash]
    );

    const activation = result.rows[0];

    if (!activation) {
      await client.query("ROLLBACK");
      return false;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const updated = await client.query(
      `UPDATE users
          SET password_hash = $1,
              active = true,
              updated_at = NOW()
        WHERE id = $2
          AND active = false`,
      [passwordHash, activation.user_id]
    );

    if (updated.rowCount !== 1) {
      await client.query("ROLLBACK");
      return false;
    }

    await client.query(
      `UPDATE user_activation_tokens
          SET used_at = NOW()
        WHERE id = $1`,
      [activation.id]
    );

    await client.query("COMMIT");
    return true;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
