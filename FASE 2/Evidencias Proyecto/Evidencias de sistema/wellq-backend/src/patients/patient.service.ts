import { database } from "../database/pool.js";
import type { Patient, PatientInput } from "./patient.types.js";

interface PatientRow {
  id: string;
  client_id: string;
  identifier: string;
  name: string;
  birth_date: string | Date | null;
  email: string | null;
  phone: string | null;
  created_at: Date;
  updated_at: Date;
}

function toPatient(row: PatientRow): Patient {
  return {
    id: row.id,
    clientId: row.client_id,
    identifier: row.identifier,
    name: row.name,
    birthDate: row.birth_date
      ? (row.birth_date instanceof Date ? row.birth_date.toISOString() : row.birth_date).slice(0, 10)
      : null,
    email: row.email,
    phone: row.phone,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString()
  };
}

export async function listPatients(
  clientId: string,
  search: string | undefined,
  page: number,
  pageSize: number
): Promise<{ items: Patient[]; total: number; page: number; pageSize: number }> {
  const term = search ? `%${search}%` : null;
  const offset = (page - 1) * pageSize;

  const [patientsResult, countResult] = await Promise.all([
    database.query<PatientRow>(
      `SELECT id, client_id, identifier, name, birth_date, email, phone, created_at, updated_at
         FROM patients
        WHERE client_id = $1
          AND deleted_at IS NULL
          AND ($2::text IS NULL OR identifier ILIKE $2 OR name ILIKE $2 OR email ILIKE $2)
        ORDER BY name ASC, id ASC
        LIMIT $3 OFFSET $4`,
      [clientId, term, pageSize, offset]
    ),
    database.query<{ total: string }>(
      `SELECT count(*)::text AS total
         FROM patients
        WHERE client_id = $1
          AND deleted_at IS NULL
          AND ($2::text IS NULL OR identifier ILIKE $2 OR name ILIKE $2 OR email ILIKE $2)`,
      [clientId, term]
    )
  ]);

  return {
    items: patientsResult.rows.map(toPatient),
    total: Number(countResult.rows[0]?.total ?? 0),
    page,
    pageSize
  };
}

export async function getPatient(clientId: string, patientId: string): Promise<Patient | null> {
  const result = await database.query<PatientRow>(
    `SELECT id, client_id, identifier, name, birth_date, email, phone, created_at, updated_at
       FROM patients
      WHERE client_id = $1 AND id = $2 AND deleted_at IS NULL`,
    [clientId, patientId]
  );
  return result.rows[0] ? toPatient(result.rows[0]) : null;
}

export async function createPatient(clientId: string, input: PatientInput): Promise<Patient> {
  const result = await database.query<PatientRow>(
    `INSERT INTO patients (client_id, identifier, name, birth_date, email, phone)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, client_id, identifier, name, birth_date, email, phone, created_at, updated_at`,
    [
      clientId,
      input.identifier,
      input.name,
      input.birthDate ?? null,
      input.email ?? null,
      input.phone ?? null
    ]
  );
  return toPatient(result.rows[0]);
}

export async function updatePatient(
  clientId: string,
  patientId: string,
  input: Partial<PatientInput>
): Promise<Patient | null> {
  const fields: string[] = [];
  const values: unknown[] = [clientId, patientId];

  const allowed: Array<[keyof PatientInput, string]> = [
    ["identifier", "identifier"],
    ["name", "name"],
    ["birthDate", "birth_date"],
    ["email", "email"],
    ["phone", "phone"]
  ];

  for (const [property, column] of allowed) {
    if (Object.hasOwn(input, property)) {
      values.push(input[property] ?? null);
      fields.push(`${column} = $${values.length}`);
    }
  }

  if (fields.length === 0) return getPatient(clientId, patientId);

  const result = await database.query<PatientRow>(
    `UPDATE patients
        SET ${fields.join(", ")}, updated_at = now()
      WHERE client_id = $1 AND id = $2 AND deleted_at IS NULL
      RETURNING id, client_id, identifier, name, birth_date, email, phone, created_at, updated_at`,
    values
  );
  return result.rows[0] ? toPatient(result.rows[0]) : null;
}

export async function deletePatient(clientId: string, patientId: string): Promise<boolean> {
  const result = await database.query(
    `UPDATE patients
        SET deleted_at = now(), updated_at = now()
      WHERE client_id = $1 AND id = $2 AND deleted_at IS NULL`,
    [clientId, patientId]
  );
  return (result.rowCount ?? 0) > 0;
}
