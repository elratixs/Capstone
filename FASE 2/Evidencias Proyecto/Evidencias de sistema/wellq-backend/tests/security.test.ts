import request from "supertest";
import jwt from "jsonwebtoken";
import { beforeEach, describe, expect, it, jest } from "@jest/globals";

const query = jest.fn<(...args: any[]) => Promise<any>>();
jest.mock("../src/database/pool.js", () => ({ database: { query: (...args: any[]) => query(...args) } }));

import { createApp } from "../src/app.js";

const clinicId = "11111111-1111-4111-8111-111111111111";
const examId = "22222222-2222-4222-8222-222222222222";
const patientId = "44444444-4444-4444-8444-444444444444";
const uploadId = "55555555-5555-4555-8555-555555555555";
const secret = "wellq_local_secret_change_before_production_2026";
const makeToken = (permissions: string[], expiresIn: string | number = "5m", roles = ["admin"], subjectPatientId?: string) => jwt.sign(
  { clientId: clinicId, clientCode: "CLINIC-A", commercialTier: "basic", roles, permissions, locale: "es-CL", ...(subjectPatientId ? { patientId: subjectPatientId } : {}) },
  secret,
  { subject: "33333333-3333-4333-8333-333333333333", expiresIn: expiresIn as jwt.SignOptions["expiresIn"] }
);

describe("seguridad y aislamiento por clínica", () => {
  beforeEach(() => { query.mockReset(); });

  it("rechaza solicitudes con token ausente, inválido o vencido", async () => {
    const app = createApp();
    const missing = await request(app).get("/api/v1/exams");
    const invalid = await request(app).get("/api/v1/exams").set("Authorization", "Bearer token-invalido");
    const expired = await request(app).get("/api/v1/exams").set("Authorization", `Bearer ${makeToken(["exams:read"], -1)}`);

    expect(missing.status).toBe(401);
    expect(invalid.status).toBe(401);
    expect(expired.status).toBe(401);
    expect(query).not.toHaveBeenCalled();
  });

  it("rechaza las rutas clínicas para cuentas sin identidad de paciente", async () => {
    const response = await request(createApp())
      .get(`/api/v1/clinical-tests/uploads/${uploadId}/status`)
      .set("Authorization", `Bearer ${makeToken([], "5m", ["admin"])}`);

    expect(response.status).toBe(403);
    expect(query).not.toHaveBeenCalled();
  });

  it("limita el estado de carga al paciente del JWT y a su clínica", async () => {
    query.mockResolvedValueOnce({ rows: [{ enabled: true }], rowCount: 1 });
    query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
    const response = await request(createApp())
      .get(`/api/v1/clinical-tests/uploads/${uploadId}/status`)
      .set("Authorization", `Bearer ${makeToken([], "5m", ["patient"], patientId)}`);

    expect(response.status).toBe(404);
    expect(query).toHaveBeenCalledTimes(2);
    expect(query.mock.calls[0][1]).toEqual([clinicId, "clinical_test_upload"]);
    expect(query.mock.calls[1][1]).toEqual([clinicId, patientId, uploadId]);
  });

  it("bloquea el módulo de carga cuando la clínica no tiene habilitada la función", async () => {
    query.mockResolvedValue({ rows: [], rowCount: 0 });
    const response = await request(createApp())
      .get("/api/v1/clinical-tests")
      .set("Authorization", `Bearer ${makeToken([], "5m", ["patient"], patientId)}`);

    expect(response.status).toBe(403);
    expect(response.body.error.code).toBe("FEATURE_NOT_ENABLED");
    expect(query).toHaveBeenCalledTimes(1);
    expect(query.mock.calls[0][1]).toEqual([clinicId, "clinical_test_upload"]);
  });

  it("no revela un examen de otra clínica y aplica el clientId del JWT en SQL", async () => {
    query.mockResolvedValue({ rows: [], rowCount: 0 });
    const response = await request(createApp())
      .get(`/api/v1/exams/${examId}`)
      .set("Authorization", `Bearer ${makeToken(["exams:read"])}`);

    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe("EXAM_NOT_FOUND");
    expect(query).toHaveBeenCalledTimes(1);
    expect(query.mock.calls[0][1]).toEqual([clinicId, examId]);
  });

  it("limita el historial de auditoría a la clínica del token", async () => {
    query.mockResolvedValue({ rows: [], rowCount: 0 });
    const response = await request(createApp())
      .get("/api/v1/audit?page=1&pageSize=20")
      .set("Authorization", `Bearer ${makeToken(["audit:read"])}`);

    expect(response.status).toBe(200);
    expect(query).toHaveBeenCalledTimes(2);
    expect(query.mock.calls[0][1]).toEqual([clinicId, null, null, null, 20, 0]);
    expect(query.mock.calls[1][1]).toEqual([clinicId, null, null, null]);
  });

  it("exige el permiso de auditoría para consultar sus registros", async () => {
    const response = await request(createApp())
      .get("/api/v1/audit")
      .set("Authorization", `Bearer ${makeToken(["exams:read"])}`);

    expect(response.status).toBe(403);
    expect(query).not.toHaveBeenCalled();
  });

  it("rechaza un PDF cuyo contenido no coincide con el MIME declarado", async () => {
    const response = await request(createApp())
      .post(`/api/v1/exams/${examId}/file`)
      .set("Authorization", `Bearer ${makeToken(["exams:write"])}`)
      .attach("file", Buffer.from("esto no es PDF"), { filename: "resultado.pdf", contentType: "application/pdf" });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe("INVALID_FILE");
    expect(query).not.toHaveBeenCalled();
  });
});
