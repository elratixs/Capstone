import type { RequestHandler } from "express";

export const denyPatientWrite: RequestHandler =
  (request, response, next) => {
    const auth = request.context.auth;

    if (
      !auth ||
      auth.roles.includes("Paciente") ||
      !auth.roles.includes("Administrador")
    ) {
      response.status(403).json({
        error: {
          code: "FORBIDDEN",
          message: "No tiene autorizacion para modificar o eliminar informacion clinica."
        }
      });
      return;
    }

    next();
  };
