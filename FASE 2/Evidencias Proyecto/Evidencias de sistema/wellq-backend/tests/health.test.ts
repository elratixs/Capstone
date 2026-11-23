import request from "supertest";
import { describe, expect, it } from "@jest/globals";
import { createApp } from "../src/app.js";

describe("GET /api/v1/health/live", () => {
  it("informa que el servicio está activo", async () => {
    const response = await request(createApp()).get("/api/v1/health/live");

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: "ok", service: "wellq-api" });
    expect(response.headers["x-request-id"]).toBeTruthy();
  });
});

describe("GET /api/v1/openapi.json", () => {
  it("publica la especificación OpenAPI con las rutas requeridas", async () => {
    const response = await request(createApp()).get("/api/v1/openapi.json");

    expect(response.status).toBe(200);
    expect(response.body.openapi).toBe("3.0.3");
    expect(response.body.paths["/auth/login"].post).toBeTruthy();
    expect(response.body.paths["/audit"].get).toBeTruthy();
    expect(response.body.paths["/exams/{id}/file"].post).toBeTruthy();
    expect(response.body.paths["/clinical-tests/uploads/initiate"].post).toBeTruthy();
    expect(response.body.paths["/clinical-tests/uploads/{upload_id}/complete"].post).toBeTruthy();
    expect(response.body.paths["/clinical-tests"].get).toBeTruthy();
    expect(response.body.paths["/clinical-tests/{clinical_test_id}/download-url"].post).toBeTruthy();
    expect(response.body.paths["/clinical-tests/{clinical_test_id}/review"].patch).toBeTruthy();
  });
});

describe("Autenticación", () => {
  it("rechaza una solicitud protegida sin token", async () => {
    const response = await request(createApp()).get("/api/v1/auth/me");

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("AUTH_REQUIRED");
  });

  it("valida los datos del inicio de sesión antes de consultar la base", async () => {
    const response = await request(createApp()).post("/api/v1/auth/login").send({});

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe("INVALID_INPUT");
  });

  it("protege el listado de pacientes", async () => {
    const response = await request(createApp()).get("/api/v1/patients");

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("AUTH_REQUIRED");
  });

  it("protege el listado de exámenes", async () => {
    const response = await request(createApp()).get("/api/v1/exams");

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("AUTH_REQUIRED");
  });
});
