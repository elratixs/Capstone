export interface Patient {
  id: string;
  clientId: string;
  identifier: string;
  name: string;
  birthDate: string | null;
  email: string | null;
  phone: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PatientInput {
  identifier: string;
  name: string;
  birthDate?: string | null;
  email?: string | null;
  phone?: string | null;
}
