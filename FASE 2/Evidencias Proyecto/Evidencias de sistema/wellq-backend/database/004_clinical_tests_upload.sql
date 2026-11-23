ALTER TABLE users ADD COLUMN IF NOT EXISTS patient_id UUID;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_patient_client_fk') THEN
    ALTER TABLE users ADD CONSTRAINT users_patient_client_fk
      FOREIGN KEY (client_id, patient_id) REFERENCES patients(client_id, id);
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS clinical_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  patient_id UUID NOT NULL,
  upload_id UUID NOT NULL DEFAULT gen_random_uuid(),
  client_upload_id UUID NOT NULL,
  idempotency_key UUID NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  mime_type VARCHAR(120) NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
  sha256 CHAR(64) NOT NULL,
  test_type VARCHAR(80) NOT NULL,
  title VARCHAR(200) NOT NULL,
  test_date DATE NOT NULL,
  notes VARCHAR(2000),
  object_key TEXT NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'initiated'
    CHECK (status IN ('initiated','object_uploaded','processing','ready_for_review','rejected','failed','deleted')),
  upload_expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (client_id, id),
  UNIQUE (client_id, upload_id),
  UNIQUE (client_id, patient_id, client_upload_id),
  UNIQUE (client_id, patient_id, idempotency_key),
  FOREIGN KEY (client_id, patient_id) REFERENCES patients(client_id, id)
);
CREATE INDEX IF NOT EXISTS idx_clinical_tests_patient_date
  ON clinical_tests(client_id, patient_id, test_date DESC, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_clinical_tests_upload_status
  ON clinical_tests(client_id, status, updated_at DESC);

CREATE TABLE IF NOT EXISTS clinical_validation_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL,
  clinical_test_id UUID NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','running','complete','retry')),
  attempts INTEGER NOT NULL DEFAULT 0,
  available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (client_id, clinical_test_id),
  FOREIGN KEY (client_id, clinical_test_id) REFERENCES clinical_tests(client_id, id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_clinical_validation_jobs_ready
  ON clinical_validation_jobs(status, available_at, created_at);

ALTER TABLE clinical_tests ADD COLUMN IF NOT EXISTS review_status VARCHAR(20) NOT NULL DEFAULT 'not_reviewed';
ALTER TABLE clinical_tests ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
ALTER TABLE clinical_tests ADD COLUMN IF NOT EXISTS reviewed_by UUID;
ALTER TABLE clinical_tests ADD COLUMN IF NOT EXISTS review_note TEXT;

CREATE TABLE IF NOT EXISTS patient_clinician_access (
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL,
  clinician_user_id UUID NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  granted_by UUID,
  PRIMARY KEY (client_id, patient_id, clinician_user_id),
  FOREIGN KEY (client_id, patient_id) REFERENCES patients(client_id, id) ON DELETE CASCADE,
  FOREIGN KEY (client_id, clinician_user_id) REFERENCES users(client_id, id) ON DELETE CASCADE,
  FOREIGN KEY (client_id, granted_by) REFERENCES users(client_id, id)
);

CREATE OR REPLACE FUNCTION prevent_audit_log_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only';
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS audit_logs_immutable_update ON audit_logs;
CREATE TRIGGER audit_logs_immutable_update BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

INSERT INTO feature_flags (code, description)
VALUES ('clinical_test_upload', 'Carga y gestión segura de exámenes clínicos')
ON CONFLICT (code) DO NOTHING;
INSERT INTO client_features (client_id, feature_id, enabled)
SELECT c.id, f.id, (c.commercial_tier <> 'basic')
FROM clients c CROSS JOIN feature_flags f
WHERE f.code = 'clinical_test_upload'
ON CONFLICT (client_id, feature_id) DO UPDATE SET enabled = EXCLUDED.enabled;
