export const openApiDocument = {
  openapi: "3.0.3",
  info: {
    title: "WellQ API",
    version: "1.0.0",
    description: "API del MVP WellQ para acceso multi clínica a pacientes y exámenes."
  },
  servers: [{ url: "http://localhost:3000/api/v1", description: "Desarrollo local" }],
  tags: [{ name: "Auth" }, { name: "Patients" }, { name: "Exams" }, { name: "ClinicalTests" }, { name: "Health" }],
  components: {
    securitySchemes: {
      bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" }
    },
    schemas: {
      Error: { type: "object", properties: { error: { type: "object", properties: { code: { type: "string" }, message: { type: "string" } }, required: ["code", "message"] } }, required: ["error"] },
      ExamInput: {
        type: "object",
        required: ["patientId", "examTypeId", "name", "examDate"],
        properties: {
          patientId: { type: "string", format: "uuid" }, examTypeId: { type: "string", format: "uuid" },
          name: { type: "string", minLength: 3, maxLength: 180 }, examDate: { type: "string", format: "date" },
          notes: { type: "string", nullable: true, maxLength: 3000 }
        }
      }
    }
  },
  paths: {
    "/health/live": { get: { tags: ["Health"], summary: "Estado de la API", responses: { "200": { description: "API disponible" } } } },
    "/health/ready": { get: { tags: ["Health"], summary: "Estado de la conexión a PostgreSQL", responses: { "200": { description: "Base de datos disponible" }, "503": { description: "Base de datos no disponible" } } } },
    "/auth/login": {
      post: {
        tags: ["Auth"], summary: "Iniciar sesión",
        requestBody: { required: true, content: { "application/json": { schema: { type: "object", required: ["clientCode", "email", "password"], properties: { clientCode: { type: "string" }, email: { type: "string", format: "email" }, password: { type: "string", minLength: 8, maxLength: 128 } } } } } },
        responses: { "200": { description: "JWT y perfil" }, "400": { description: "Entrada inválida" }, "401": { description: "Credenciales inválidas" } }
      }
    },
    "/auth/me": { get: { tags: ["Auth"], security: [{ bearerAuth: [] }], summary: "Perfil de la sesión", responses: { "200": { description: "Usuario autenticado" }, "401": { description: "Token ausente o inválido" } } } },
    "/patients": {
      get: { tags: ["Patients"], security: [{ bearerAuth: [] }], summary: "Listar pacientes de la clínica del token", responses: { "200": { description: "Página de pacientes" }, "401": { description: "No autenticado" }, "403": { description: "Permiso insuficiente" } } },
      post: { tags: ["Patients"], security: [{ bearerAuth: [] }], summary: "Crear paciente", responses: { "201": { description: "Paciente creado" }, "400": { description: "Entrada inválida" }, "403": { description: "Permiso insuficiente" } } }
    },
    "/patients/{id}": {
      parameters: [{ name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" } }],
      get: { tags: ["Patients"], security: [{ bearerAuth: [] }], summary: "Consultar paciente", responses: { "200": { description: "Paciente" }, "404": { description: "No encontrado en esta clínica" } } },
      patch: { tags: ["Patients"], security: [{ bearerAuth: [] }], summary: "Actualizar paciente", responses: { "200": { description: "Paciente actualizado" }, "404": { description: "No encontrado en esta clínica" } } },
      delete: { tags: ["Patients"], security: [{ bearerAuth: [] }], summary: "Eliminar paciente lógicamente", responses: { "204": { description: "Eliminado" }, "404": { description: "No encontrado en esta clínica" } } }
    },
    "/exams/types": { get: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Tipos de examen habilitados para la clínica", responses: { "200": { description: "Tipos disponibles" } } } },
    "/exams": {
      get: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Listar exámenes de la clínica del token", responses: { "200": { description: "Página de exámenes" }, "401": { description: "No autenticado" }, "403": { description: "Permiso insuficiente" } } },
      post: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Crear examen", requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/ExamInput" } } } }, responses: { "201": { description: "Examen creado" }, "422": { description: "Paciente o tipo no válido para la clínica" } } }
    },
    "/exams/{id}": {
      parameters: [{ name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" } }],
      get: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Consultar examen", responses: { "200": { description: "Examen" }, "404": { description: "No encontrado en esta clínica" } } },
      put: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Actualizar examen", requestBody: { required: true, content: { "application/json": { schema: { $ref: "#/components/schemas/ExamInput" } } } }, responses: { "200": { description: "Examen actualizado" }, "404": { description: "No encontrado en esta clínica" } } },
      delete: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Eliminar examen y archivo lógicamente", responses: { "204": { description: "Eliminado" }, "404": { description: "No encontrado en esta clínica" } } }
    },
    "/exams/{id}/file": {
      parameters: [{ name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" } }],
      post: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Cargar PDF, JPG o PNG", requestBody: { required: true, content: { "multipart/form-data": { schema: { type: "object", required: ["file"], properties: { file: { type: "string", format: "binary" } } } } } }, responses: { "201": { description: "Archivo guardado" }, "400": { description: "Archivo inválido" }, "413": { description: "Archivo supera el límite" }, "415": { description: "Tipo no permitido" } } },
      get: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Vista previa protegida del archivo", responses: { "200": { description: "Contenido del examen" }, "404": { description: "Archivo no encontrado" } } }
    },
    "/exams/{id}/file/download": { parameters: [{ name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" } }], get: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Descargar archivo de examen", responses: { "200": { description: "Archivo descargado" }, "403": { description: "Permiso insuficiente" }, "404": { description: "Archivo no encontrado" } } } },
    "/exams/{id}/results": {
      parameters: [{ name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" } }],
      get: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Consultar transcripción de resultados", responses: { "200": { description: "Estado y resultados" }, "404": { description: "No encontrado en esta clínica" } } },
      put: { tags: ["Exams"], security: [{ bearerAuth: [] }], summary: "Guardar propuesta de transcripción", responses: { "200": { description: "Propuesta guardada para confirmación del paciente" }, "400": { description: "Resultados inválidos" } } }
    },
    "/clinical-tests/uploads/initiate": { post: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Iniciar carga idempotente de examen clínico", parameters: [{ name: "Idempotency-Key", in: "header", required: true, schema: { type: "string", format: "uuid" } }], responses: { "201": { description: "Sesión creada con URL firmada privada" }, "400": { description: "Metadatos inválidos" }, "401": { description: "No autenticado" }, "403": { description: "Se requiere cuenta de paciente vinculada" }, "409": { description: "Conflicto de idempotencia" } } } },
    "/clinical-tests/uploads/{upload_id}/refresh-url": { post: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Renovar URL sin duplicar carga", parameters: [{ name: "upload_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }, { name: "Idempotency-Key", in: "header", required: true, schema: { type: "string", format: "uuid" } }], responses: { "200": { description: "URL firmada renovada" }, "403": { description: "No autorizado" }, "404": { description: "Sesión inexistente" }, "409": { description: "Carga no renovable" } } } },
    "/clinical-tests/uploads/{upload_id}/complete": { post: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Verificar transferencia y encolar validación", parameters: [{ name: "upload_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }, { name: "Idempotency-Key", in: "header", required: true, schema: { type: "string", format: "uuid" } }], responses: { "202": { description: "Validación en proceso; conservar archivo local" }, "404": { description: "Sesión inexistente" }, "409": { description: "Objeto ausente o distinto" } } } },
    "/clinical-tests/uploads/{upload_id}/status": { get: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Consultar validación y permiso de borrado local", parameters: [{ name: "upload_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }], responses: { "200": { description: "Estado y permiso de borrado local" }, "403": { description: "No autorizado" }, "404": { description: "Sesión inexistente" } } } },
    "/clinical-tests": { get: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Listar resultados propios con cursor", responses: { "200": { description: "Resultados paginados" }, "401": { description: "No autenticado" }, "403": { description: "Se requiere cuenta de paciente vinculada" } } } },
    "/clinical-tests/{clinical_test_id}": { parameters: [{ name: "clinical_test_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }], get: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Consultar metadatos y revisión", responses: { "200": { description: "Resultado" }, "403": { description: "No autorizado" }, "404": { description: "No encontrado" } } }, patch: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Editar metadatos antes de revisión", responses: { "200": { description: "Metadatos actualizados" }, "409": { description: "Ya revisado" } } }, delete: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Borrar lógicamente un resultado", responses: { "200": { description: "Resultado retirado" }, "404": { description: "No encontrado o no eliminable" } } } },
    "/clinical-tests/{clinical_test_id}/download-url": { parameters: [{ name: "clinical_test_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }], post: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Emitir URL privada de descarga por cinco minutos", responses: { "200": { description: "URL privada y vencimiento" }, "403": { description: "No autorizado" }, "404": { description: "Resultado no disponible" } } } },
    "/clinical-tests/{clinical_test_id}/review": { parameters: [{ name: "clinical_test_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }], patch: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Registrar revisión clínica autorizada", responses: { "200": { description: "Revisión registrada" }, "403": { description: "Clínico no autorizado" }, "409": { description: "Resultado no listo" } } } },
    "/patients/{patient_id}/clinical-tests": { parameters: [{ name: "patient_id", in: "path", required: true, schema: { type: "string", format: "uuid" } }], get: { tags: ["ClinicalTests"], security: [{ bearerAuth: [] }], summary: "Listar resultados de paciente autorizado", responses: { "200": { description: "Resultados clínicos" }, "403": { description: "Sin relación clínica autorizada" } } } },
    "/audit": { get: { tags: ["Auth"], security: [{ bearerAuth: [] }], summary: "Consultar auditoría limitada a la clínica del token", parameters: [{ name: "action", in: "query", schema: { type: "string" } }, { name: "since", in: "query", schema: { type: "string", format: "date-time" } }, { name: "until", in: "query", schema: { type: "string", format: "date-time" } }, { name: "page", in: "query", schema: { type: "integer", minimum: 1 } }, { name: "pageSize", in: "query", schema: { type: "integer", minimum: 1, maximum: 100 } }], responses: { "200": { description: "Eventos de auditoría paginados" }, "401": { description: "No autenticado" }, "403": { description: "Permiso audit:read requerido" } } } }
  }
} as const;
