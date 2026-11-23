import { Router } from "express";
import { z } from "zod";
import { listAuditEvents } from "../audit/audit.service.js";
import { authenticate, requirePermission } from "../middleware/authenticate.js";

const querySchema = z.object({
  action: z.string().trim().min(1).max(120).optional(),
  since: z.string().datetime({ offset: true }).optional(),
  until: z.string().datetime({ offset: true }).optional(),
  page: z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(50)
}).refine((value) => !value.since || !value.until || value.since < value.until, "La fecha inicial debe ser anterior a la final.");

export const auditRouter = Router();
auditRouter.use(authenticate);
auditRouter.get("/", requirePermission("audit:read"), async (request, response, next) => {
  const parsed = querySchema.safeParse(request.query);
  if (!parsed.success) {
    response.status(400).json({ error: { code: "INVALID_QUERY", message: "Filtros de auditoría inválidos." } });
    return;
  }
  try {
    response.json(await listAuditEvents(request.context.auth!.clientId, parsed.data));
  } catch (error) {
    next(error);
  }
});
