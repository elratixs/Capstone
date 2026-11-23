import { database } from "../database/pool.js";

interface ExamAccessInput {
  clientId: string;
  examId: string;
  patientId?: string;
  roles: string[];
}

export async function canAccessExam(
  input: ExamAccessInput
): Promise<boolean> {
  const { clientId, examId, patientId, roles } = input;

  const result = await database.query<{ patient_id: string }>(
    `SELECT patient_id
       FROM exams
      WHERE client_id = $1
        AND id = $2
        AND deleted_at IS NULL`,
    [clientId, examId]
  );

  const exam = result.rows[0];

  if (!exam) return false;

  if (roles.includes("Paciente")) {
    return Boolean(patientId && exam.patient_id === patientId);
  }

  if (roles.includes("Administrador")) {
    return true;
  }

  // Acceso profesional pendiente de autorización por paciente.
  return false;
}
