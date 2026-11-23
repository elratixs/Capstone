CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(150) NOT NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  commercial_tier VARCHAR(30) NOT NULL DEFAULT 'basic',
  default_locale VARCHAR(10) NOT NULL DEFAULT 'es-CL',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  name VARCHAR(150) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (client_id, email),
  UNIQUE (client_id, id)
);

CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  name VARCHAR(80) NOT NULL,
  description TEXT,
  UNIQUE (client_id, name),
  UNIQUE (client_id, id)
);

CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(120) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE role_permissions (
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
  client_id UUID NOT NULL REFERENCES clients(id),
  user_id UUID NOT NULL,
  role_id UUID NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (client_id, user_id) REFERENCES users(client_id, id) ON DELETE CASCADE,
  FOREIGN KEY (client_id, role_id) REFERENCES roles(client_id, id) ON DELETE CASCADE
);

CREATE TABLE feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(120) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE client_features (
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  feature_id UUID NOT NULL REFERENCES feature_flags(id) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (client_id, feature_id)
);

CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  identifier VARCHAR(80) NOT NULL,
  name VARCHAR(180) NOT NULL,
  birth_date DATE,
  email VARCHAR(255),
  phone VARCHAR(40),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (client_id, identifier),
  UNIQUE (client_id, id)
);

CREATE TABLE exam_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  name VARCHAR(120) NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (client_id, name),
  UNIQUE (client_id, id)
);

CREATE TABLE exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  patient_id UUID NOT NULL,
  exam_type_id UUID NOT NULL,
  created_by UUID NOT NULL,
  name VARCHAR(180) NOT NULL,
  exam_date DATE NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'available',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (client_id, id),
  FOREIGN KEY (client_id, patient_id) REFERENCES patients(client_id, id),
  FOREIGN KEY (client_id, exam_type_id) REFERENCES exam_types(client_id, id),
  FOREIGN KEY (client_id, created_by) REFERENCES users(client_id, id)
);

CREATE TABLE exam_files (
  exam_id UUID PRIMARY KEY REFERENCES exams(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id),
  object_key TEXT NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  mime_type VARCHAR(120) NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
  sha256 CHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  user_id UUID,
  user_role VARCHAR(80),
  action VARCHAR(120) NOT NULL,
  resource_type VARCHAR(120) NOT NULL,
  resource_id UUID,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  ip_address INET,
  user_agent TEXT,
  status_code INTEGER NOT NULL,
  success BOOLEAN NOT NULL,
  request_id UUID NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_users_client ON users(client_id);
CREATE INDEX idx_patients_client_active ON patients(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_exams_client_patient_active ON exams(client_id, patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_audit_client_time ON audit_logs(client_id, occurred_at DESC);

INSERT INTO permissions (code, description) VALUES
  ('patients:read', 'Consultar pacientes'),
  ('patients:write', 'Crear y modificar pacientes'),
  ('exams:read', 'Consultar exámenes'),
  ('exams:write', 'Cargar y modificar exámenes'),
  ('exams:download', 'Descargar archivos de exámenes'),
  ('audit:read', 'Consultar registros de auditoría')
ON CONFLICT (code) DO NOTHING;

INSERT INTO feature_flags (code, description) VALUES
  ('exam_upload', 'Carga de exámenes'),
  ('exam_preview', 'Vista previa de archivos'),
  ('audit_export', 'Exportación de registros de auditoría')
ON CONFLICT (code) DO NOTHING;
