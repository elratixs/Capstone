import type { NextFunction, Request, Response } from "express";

declare global {
  namespace Express {
    interface Request {
      context: {
        requestId: string;
        clientId?: string;
        userId?: string;
        auth?: {
          userId: string;
          clientId: string;
          clientCode: string;
          commercialTier: string;
          roles: string[];
          permissions: string[];
          locale: string;
          patientId?: string;
        };
      };
    }
  }
}

export function requestContext(request: Request, response: Response, next: NextFunction): void {
  const requestId = request.header("x-request-id") ?? crypto.randomUUID();
  const clientId = request.header("x-client-id") ?? undefined;
  const userId = request.header("x-user-id") ?? undefined;

  request.context = { requestId, clientId, userId };
  response.setHeader("x-request-id", requestId);
  next();
}



