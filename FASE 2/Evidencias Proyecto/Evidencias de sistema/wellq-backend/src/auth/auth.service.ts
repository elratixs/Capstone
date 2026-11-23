import bcrypt from "bcryptjs";
import jwt, { type SignOptions } from "jsonwebtoken";
import { database } from "../database/pool.js";
import { env } from "../config/env.js";
import type { AccessTokenPayload, AuthenticatedUser } from "./auth.types.js";

interface UserRow {
  id: string;
  client_id: string;
  client_code: string;
  commercial_tier: string;
  default_locale: string;
  name: string;
  email: string;
  password_hash: string;
  patient_id: string | null;
}

export async function authenticateUser(
  clientCode: string,
  email: string,
  password: string
): Promise<{ user: AuthenticatedUser; token: string } | null> {
  const result = await database.query<UserRow>(
    `SELECT u.id, u.client_id, c.code AS client_code,
            c.commercial_tier, c.default_locale,
            u.name, u.email, u.password_hash, u.patient_id
       FROM users u
       JOIN clients c ON c.id = u.client_id
      WHERE c.code = $1
        AND lower(u.email) = lower($2)
        AND u.active = true
      LIMIT 1`,
    [clientCode, email]
  );

  const row = result.rows[0];
  if (!row || !(await bcrypt.compare(password, row.password_hash))) {
    return null;
  }

  const rolesResult = await database.query<{ name: string }>(
    `SELECT r.name
       FROM roles r
       JOIN user_roles ur ON ur.role_id = r.id
      WHERE ur.client_id = $1 AND ur.user_id = $2
      ORDER BY r.name`,
    [row.client_id, row.id]
  );

  const permissionsResult = await database.query<{ code: string }>(
    `SELECT DISTINCT p.code
       FROM permissions p
       JOIN role_permissions rp ON rp.permission_id = p.id
       JOIN user_roles ur ON ur.role_id = rp.role_id
      WHERE ur.client_id = $1 AND ur.user_id = $2
      ORDER BY p.code`,
    [row.client_id, row.id]
  );

  const user: AuthenticatedUser = {
    sub: row.id,
    clientId: row.client_id,
    clientCode: row.client_code,
    commercialTier: row.commercial_tier,
    roles: rolesResult.rows.map((role) => role.name),
    permissions: permissionsResult.rows.map((permission) => permission.code),
    locale: row.default_locale,
    patientId: row.patient_id ?? undefined,
    name: row.name,
    email: row.email
  };

  const token = jwt.sign(
    {
      clientId: user.clientId,
      clientCode: user.clientCode,
      commercialTier: user.commercialTier,
      roles: user.roles,
      permissions: user.permissions,
      locale: user.locale,
      patientId: user.patientId
    },
    env.JWT_SECRET,
    { subject: user.sub, expiresIn: env.JWT_EXPIRES_IN } as SignOptions
  );

  return { user, token };
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const decoded = jwt.verify(token, env.JWT_SECRET);

  if (typeof decoded === "string" || !decoded.sub) {
    throw new Error("Token sin identidad de usuario.");
  }

  return {
    sub: decoded.sub,
    clientId: String(decoded.clientId),
    clientCode: String(decoded.clientCode),
    commercialTier: String(decoded.commercialTier),
    roles: Array.isArray(decoded.roles) ? decoded.roles.map(String) : [],
    permissions: Array.isArray(decoded.permissions) ? decoded.permissions.map(String) : [],
    locale: String(decoded.locale ?? "es-CL"),
    patientId: decoded.patientId ? String(decoded.patientId) : undefined
  };
}
