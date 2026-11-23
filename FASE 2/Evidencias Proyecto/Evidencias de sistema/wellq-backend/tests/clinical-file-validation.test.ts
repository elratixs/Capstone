import { createHash } from "node:crypto";
import { describe, expect, it } from "@jest/globals";
import { verifyClinicalFile } from "../src/exams/clinical-file-validation.service.js";

function checksum(value: Buffer): string { return createHash("sha256").update(value).digest("hex"); }

describe("validación de archivos clínicos", () => {
  it("verifica firma PDF y checksum antes de aceptar el objeto", () => {
    const pdf = Buffer.from("%PDF-1.7\ncontenido de prueba");
    expect(verifyClinicalFile(pdf, "application/pdf", checksum(pdf))).toBe(true);
    expect(verifyClinicalFile(pdf, "application/pdf", "0".repeat(64))).toBe(false);
  });

  it("rechaza bytes PDF declarados como imagen y firmas desconocidas", () => {
    const fake = Buffer.from("%PDF-1.7\nfalso");
    expect(verifyClinicalFile(fake, "image/png", checksum(fake))).toBe(false);
    expect(verifyClinicalFile(Buffer.from("ejecutable"), "application/pdf", checksum(Buffer.from("ejecutable")))).toBe(false);
  });

  it("reconoce el encabezado HEIC ISO-BMFF", () => {
    const heic = Buffer.from([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63, 0, 0, 0, 0]);
    expect(verifyClinicalFile(heic, "image/heic", checksum(heic))).toBe(true);
  });
});
