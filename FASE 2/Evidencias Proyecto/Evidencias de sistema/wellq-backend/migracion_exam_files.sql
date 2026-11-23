BEGIN;

ALTER TABLE exam_files
ADD COLUMN id uuid;

ALTER TABLE exam_files
ADD COLUMN uploaded_by uuid;

UPDATE exam_files
SET id = gen_random_uuid()
WHERE id IS NULL;

ALTER TABLE exam_files
ALTER COLUMN id SET DEFAULT gen_random_uuid();

ALTER TABLE exam_files
ALTER COLUMN id SET NOT NULL;

ALTER TABLE exam_files
DROP CONSTRAINT exam_files_pkey;

ALTER TABLE exam_files
ADD CONSTRAINT exam_files_pkey PRIMARY KEY (id);

CREATE INDEX idx_exam_files_client_exam
ON exam_files (client_id, exam_id);

ALTER TABLE exam_files
ADD CONSTRAINT exam_files_uploaded_by_fkey
FOREIGN KEY (client_id, uploaded_by)
REFERENCES users (client_id, id);

COMMIT;
