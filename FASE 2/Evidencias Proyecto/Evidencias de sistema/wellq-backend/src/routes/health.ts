import { Router } from "express";
import { database } from "../database/pool.js";

export const healthRouter = Router();

healthRouter.get("/live", (_request, response) => {
  response.json({ status: "ok", service: "wellq-api" });
});

healthRouter.get("/ready", async (_request, response, next) => {
  try {
    await database.query("SELECT 1");
    response.json({ status: "ready", database: "connected" });
  } catch (error) {
    next(error);
  }
});
