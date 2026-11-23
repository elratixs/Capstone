export interface Exam {
  id: string;
  clientId: string;
  patientId: string;
  patientName: string;
  examTypeId: string;
  examTypeName: string;
  createdBy: string;
  name: string;
  examDate: string;
  status: string;
  notes: string | null;
  hasFile: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ExamInput {
  patientId: string;
  examTypeId: string;
  name: string;
  examDate: string;
  notes?: string | null;
}

export interface ExamFile {
  id: string;
  examId: string;
  clientId: string;
  uploadedBy: string | null;
  objectKey: string;
  originalName: string;
  mimeType: string;
  sizeBytes: number;
  sha256: string;
  createdAt: string;
}

