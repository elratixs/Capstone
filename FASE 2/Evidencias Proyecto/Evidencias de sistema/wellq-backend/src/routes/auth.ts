import { Router } from "express";
import { z } from "zod";
import { authenticateUser } from "../auth/auth.service.js";
import { activatePatientAccount } from "../auth/account-activation.service.js";
import { authenticate } from "../middleware/authenticate.js";
import { recordLoginAttempt } from "../audit/audit.service.js";

const loginSchema = z.object({
  clientCode: z.string().trim().min(2).max(50),
  email: z.string().trim().email(),
  password: z.string().min(8).max(128)
});

export const authRouter = Router();

authRouter.post("/login", async (request, response, next) => {
  const parsed = loginSchema.safeParse(request.body);
  if (!parsed.success) {
    response.status(400).json({
      error: {
        code: "INVALID_INPUT",
        message: "Revisa el cÃ³digo de clÃ­nica, correo y contraseÃ±a.",
        details: parsed.error.flatten().fieldErrors
      }
    });
    return;
  }

  try {
    const session = await authenticateUser(
      parsed.data.clientCode,
      parsed.data.email,
      parsed.data.password
    );

    if (!session) {
      await recordLoginAttempt(request, parsed.data.clientCode);
      response.status(401).json({
        error: { code: "INVALID_CREDENTIALS", message: "Credenciales incorrectas." }
      });
      return;
    }

    await recordLoginAttempt(request, parsed.data.clientCode, {
      userId: session.user.sub,
      clientId: session.user.clientId,
      roles: session.user.roles
    });

    response.json({
      accessToken: session.token,
      tokenType: "Bearer",
      user: {
        id: session.user.sub,
        name: session.user.name,
        email: session.user.email,
        clientCode: session.user.clientCode,
        commercialTier: session.user.commercialTier,
        roles: session.user.roles,
        permissions: session.user.permissions,
        locale: session.user.locale
      }
    });
  } catch (error) {
    next(error);
  }
});

authRouter.get("/me", authenticate, (request, response) => {
  response.json({ user: request.context.auth });
});

authRouter.post("/activate", async (request, response, next) => {
  const parsed = z.object({
    token: z.string().regex(/^[a-f0-9]{64}$/),
    password: z.string().min(12).max(128)
  }).safeParse(request.body);

  if (!parsed.success) {
    response.status(400).json({
      error: {
        code: "INVALID_INPUT",
        message: "Enlace o contraseÃ±a invÃ¡lidos."
      }
    });
    return;
  }

  try {
    const activated = await activatePatientAccount(
      parsed.data.token,
      parsed.data.password
    );

    if (!activated) {
      response.status(400).json({
        error: {
          code: "INVALID_ACTIVATION",
          message: "El enlace es invÃ¡lido, expirÃ³ o ya fue utilizado."
        }
      });
      return;
    }

    response.json({
      success: true,
      message: "Cuenta activada correctamente."
    });
  } catch (error) {
    next(error);
  }
});
