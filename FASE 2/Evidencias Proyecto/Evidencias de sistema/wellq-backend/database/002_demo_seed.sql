INSERT INTO clients (name, code, commercial_tier, default_locale)
VALUES ('Clínica Demo WellQ', 'WELLQ-DEMO', 'professional', 'es-CL')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
RETURNING id;

WITH selected_client AS (
  SELECT id FROM clients WHERE code = 'WELLQ-DEMO'
)
INSERT INTO roles (client_id, name, description)
SELECT id, 'Administrador', 'Acceso administrativo a la clínica' FROM selected_client
ON CONFLICT (client_id, name) DO NOTHING;

WITH selected_client AS (
  SELECT id FROM clients WHERE code = 'WELLQ-DEMO'
)
INSERT INTO users (client_id, name, email, password_hash)
SELECT id, 'Renato Toro Silva', 'admin@wellq.cl', crypt('WellQ2026!', gen_salt('bf', 12))
FROM selected_client
ON CONFLICT (client_id, email) DO UPDATE SET
  name = EXCLUDED.name,
  password_hash = EXCLUDED.password_hash,
  active = true;

WITH selected_client AS (
  SELECT id FROM clients WHERE code = 'WELLQ-DEMO'
), selected_user AS (
  SELECT u.id, u.client_id FROM users u JOIN selected_client c ON c.id = u.client_id
  WHERE u.email = 'admin@wellq.cl'
), selected_role AS (
  SELECT r.id, r.client_id FROM roles r JOIN selected_client c ON c.id = r.client_id
  WHERE r.name = 'Administrador'
)
INSERT INTO user_roles (client_id, user_id, role_id)
SELECT u.client_id, u.id, r.id FROM selected_user u JOIN selected_role r ON r.client_id = u.client_id
ON CONFLICT DO NOTHING;

WITH selected_client AS (
  SELECT id FROM clients WHERE code = 'WELLQ-DEMO'
), selected_role AS (
  SELECT r.id FROM roles r JOIN selected_client c ON c.id = r.client_id
  WHERE r.name = 'Administrador'
)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM selected_role r CROSS JOIN permissions p
ON CONFLICT DO NOTHING;

WITH selected_client AS (
  SELECT id FROM clients WHERE code = 'WELLQ-DEMO'
)
INSERT INTO client_features (client_id, feature_id, enabled)
SELECT c.id, f.id, true FROM selected_client c CROSS JOIN feature_flags f
ON CONFLICT (client_id, feature_id) DO UPDATE SET enabled = true;

WITH selected_client AS (
  SELECT id FROM clients WHERE code = 'WELLQ-DEMO'
)
INSERT INTO exam_types (client_id, name, description)
SELECT id, 'Examen de laboratorio', 'Resultados generales de laboratorio' FROM selected_client
ON CONFLICT (client_id, name) DO NOTHING;
