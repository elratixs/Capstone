import type { NextFunction, Request, Response } from "express";
import { database } from "../database/pool.js";

export function requireFeature(featureCode: string, allowedRoles: string[]) {
  return async (request: Request, response: Response, next: NextFunction): Promise<void> => {
    const auth = request.context.auth;
    if (!auth) { response.status(401).json({ error: { code: "UNAUTHORIZED", message: "Inicia sesión para continuar." } }); return; }
    const roleMatches = auth.roles.some((role) => allowedRoles.includes(role));
    const patientIdentityPresent = !allowedRoles.some((role) => ["patient", "Paciente"].includes(role)) || !auth.roles.some((role) => ["patient", "Paciente"].includes(role)) || Boolean(auth.patientId);
    if (!roleMatches || !patientIdentityPresent) { response.status(403).json({ error: { code: "FORBIDDEN", message: "Tu perfil no puede acceder a este módulo." } }); return; }
    try {
      const result = await database.query<{ enabled: boolean }>(`SELECT cf.enabled FROM client_features cf JOIN feature_flags ff ON ff.id=cf.feature_id WHERE cf.client_id=$1 AND ff.code=$2 LIMIT 1`, [auth.clientId, featureCode]);
      if (!result.rows[0]?.enabled) { response.status(403).json({ error: { code: "FEATURE_NOT_ENABLED", message: "Esta función no está habilitada en el plan de tu clínica.", feature: featureCode } }); return; }
      next();
    } catch (error) { next(error); }
  };
}
