import type { ErrorRequestHandler } from "express";
import multer from "multer";

export const errorHandler: ErrorRequestHandler = (error, request, response, _next) => {
  if (error instanceof multer.MulterError && error.code === "LIMIT_FILE_SIZE") {
    response.status(413).json({ error: { code: "FILE_TOO_LARGE", message: "El archivo supera el tamaño permitido." } });
    return;
  }
  if (error instanceof Error && error.message === "UNSUPPORTED_FILE_TYPE") {
    response.status(415).json({ error: { code: "UNSUPPORTED_FILE_TYPE", message: "Solo se permiten archivos PDF, JPG y PNG." } });
    return;
  }
  request.log?.error({ error, requestId: request.context?.requestId }, "Error no controlado");

  response.status(500).json({
    error: {
      code: "INTERNAL_ERROR",
      message: "Ocurrió un error interno.",
      requestId: request.context?.requestId
    }
  });
};
