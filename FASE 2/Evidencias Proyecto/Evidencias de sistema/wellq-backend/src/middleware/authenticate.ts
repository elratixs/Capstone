import type { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../auth/auth.service.js";

export function authenticate(request: Request, response: Response, next: NextFunction): void {
  const authorization = request.header("authorization");

  if (!authorization?.startsWith("Bearer ")) {
    response.status(401).json({
      error: { code: "AUTH_REQUIRED", message: "Debes iniciar sesión." }
    });
    return;
  }

  try {
    const payload = verifyAccessToken(authorization.slice(7));
    request.context.auth = {
      userId: payload.sub,
      clientId: payload.clientId,
      clientCode: payload.clientCode,
      commercialTier: payload.commercialTier,
      roles: payload.roles,
      permissions: payload.permissions,
      locale: payload.locale,
      patientId: payload.patientId
    };
    request.context.userId = payload.sub;
    request.context.clientId = payload.clientId;
    next();
  } catch {
    response.status(401).json({
      error: { code: "INVALID_TOKEN", message: "La sesión no es válida o expiró." }
    });
  }
}

export function requirePermission(permission: string) {
  return (request: Request, response: Response, next: NextFunction): void => {
    if (!request.context.auth?.permissions.includes(permission)) {
      response.status(403).json({
        error: { code: "FORBIDDEN", message: "No tienes permiso para realizar esta acción." }
      });
      return;
    }
    next();
  };
}
