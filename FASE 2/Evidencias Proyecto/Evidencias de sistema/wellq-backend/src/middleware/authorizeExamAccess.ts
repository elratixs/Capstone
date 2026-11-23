import type { RequestHandler } from "express";
import { z } from "zod";
import { canAccessExam } from "../exams/exam-access.service.js";

const examIdSchema = z.string().uuid();

export const authorizeExamAccess: RequestHandler =
  async (request, response, next) => {
    const parsed = examIdSchema.safeParse(request.params.id);

    if (!parsed.success) {
      response.status(400).json({
        error: {
          code: "INVALID_ID",
          message: "Identificador de examen invalido."
        }
      });
      return;
    }

    const auth = request.context.auth;

    if (!auth) {
      response.status(401).json({
        error: {
          code: "AUTH_REQUIRED",
          message: "Autenticacion requerida."
        }
      });
      return;
    }

    try {
      const allowed = await canAccessExam({
        clientId: auth.clientId,
        examId: parsed.data,
        patientId: auth.patientId,
        roles: auth.roles
      });

      if (!allowed) {
        response.status(404).json({
          error: {
            code: "EXAM_NOT_FOUND",
            message: "Examen no encontrado."
          }
        });
        return;
      }

      next();
    } catch (error) {
      next(error);
    }
  };
