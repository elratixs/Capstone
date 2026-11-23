import type { Request } from "express";
import { database } from "../database/pool.js";

interface AuditEvent {
  action: string;
  resourceType: string;
  resourceId?: string;
  statusCode: number;
  success: boolean;
  metadata?: Record<string, unknown>;
}

type AuditIdentity = { userId?: string; clientId: string; roles?: string[] };

export async function recordAudit(request: Request, event: AuditEvent, identity?: AuditIdentity): Promise<void> {
  const auth = request.context.auth ?? (identity ? {
    userId: identity.userId ?? "", clientId: identity.clientId, roles: identity.roles ?? []
  } : undefined);
  if (!auth) return;

  await database.query(
    `INSERT INTO audit_logs (
       client_id, user_id, user_role, action, resource_type, resource_id,
       ip_address, user_agent, status_code, success, request_id, metadata
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
    [
      auth.clientId,
      auth.userId || null,
      auth.roles.join(","),
      event.action,
      event.resourceType,
      event.resourceId ?? null,
      request.ip,
      request.header("user-agent") ?? null,
      event.statusCode,
      event.success,
      request.context.requestId,
      event.metadata ?? {}
    ]
  );
}

export async function recordLoginAttempt(request: Request, clientCode: string, identity?: { userId: string; clientId: string; roles: string[] }): Promise<void> {
  const client = await database.query<{ id: string }>("SELECT id FROM clients WHERE code = $1 LIMIT 1", [clientCode]);
  const clientId = identity?.clientId ?? client.rows[0]?.id;
  if (!clientId) return;
  await recordAudit(request, {
    action: "LOGIN", resourceType: "session", statusCode: identity ? 200 : 401,
    success: Boolean(identity), metadata: { clientCode }
  }, identity ?? { clientId });
}

export async function listAuditEvents(clientId: string, filters: {
  action?: string; since?: string; until?: string; page: number; pageSize: number;
}) {
  const offset = (filters.page - 1) * filters.pageSize;
  const values = [clientId, filters.action ?? null, filters.since ?? null, filters.until ?? null];
  const [events, count] = await Promise.all([
    database.query(
      `SELECT id, user_id, user_role, action, resource_type, resource_id, occurred_at,
              ip_address, user_agent, status_code, success, request_id, metadata
         FROM audit_logs
        WHERE client_id = $1
          AND ($2::text IS NULL OR action = $2)
          AND ($3::timestamptz IS NULL OR occurred_at >= $3)
          AND ($4::timestamptz IS NULL OR occurred_at < $4)
        ORDER BY occurred_at DESC, id DESC
        LIMIT $5 OFFSET $6`,
      [...values, filters.pageSize, offset]
    ),
    database.query<{ total: string }>(
      `SELECT count(*)::text AS total FROM audit_logs
        WHERE client_id = $1
          AND ($2::text IS NULL OR action = $2)
          AND ($3::timestamptz IS NULL OR occurred_at >= $3)
          AND ($4::timestamptz IS NULL OR occurred_at < $4)`,
      values
    )
  ]);
  return { items: events.rows, total: Number(count.rows[0]?.total ?? 0), page: filters.page, pageSize: filters.pageSize };
}
