CREATE TABLE IF NOT EXISTS clinical_result_records (
  client_id UUID NOT NULL,
  exam_id UUID NOT NULL,
  entries JSONB NOT NULL DEFAULT '[]'::jsonb,
  status VARCHAR(40) NOT NULL DEFAULT 'awaiting_patient_confirmation'
    CHECK (status IN ('awaiting_patient_confirmation', 'patient_confirmed', 'clinically_validated')),
  patient_confirmed_by UUID,
  patient_confirmed_at TIMESTAMPTZ,
  validated_by UUID,
  validated_at TIMESTAMPTZ,
  created_by UUID NOT NULL,
  updated_by UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (client_id, exam_id),
  FOREIGN KEY (client_id, exam_id) REFERENCES exams(client_id, id) ON DELETE CASCADE,
  FOREIGN KEY (client_id, created_by) REFERENCES users(client_id, id),
  FOREIGN KEY (client_id, updated_by) REFERENCES users(client_id, id),
  FOREIGN KEY (client_id, patient_confirmed_by) REFERENCES users(client_id, id),
  FOREIGN KEY (client_id, validated_by) REFERENCES users(client_id, id)
);

CREATE INDEX IF NOT EXISTS idx_clinical_results_client_status
  ON clinical_result_records(client_id, status, updated_at DESC);
