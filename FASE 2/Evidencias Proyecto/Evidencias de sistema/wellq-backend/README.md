# WellQ Backend

Base inicial de la API de WellQ para la primera etapa del Capstone.

## Incluye

- API Node.js con TypeScript y Express.
- PostgreSQL ejecutable mediante Docker.
- Aislamiento multiempresa mediante `client_id`.
- Esquema inicial de usuarios, RBAC, planes comerciales, pacientes, exámenes, archivos y auditoría.
- Rutas de salud para comprobar aplicación y base de datos.
- Configuración validada mediante variables de entorno.

## Puesta en marcha

1. Copiar `.env.example` como `.env`.
2. Ejecutar `docker compose up -d`.
3. Ejecutar `npm install`.
4. Ejecutar `npm run dev`.
5. Abrir `http://localhost:3000/api/v1/health/live`.

La comprobación de PostgreSQL está disponible en `http://localhost:3000/api/v1/health/ready`.

La especificación OpenAPI está disponible en `http://localhost:3000/api/v1/openapi.json`.

## Inicio de sesión local

Si PostgreSQL ya estaba funcionando antes de agregar la autenticación:

1. Ejecutar `docker compose up -d --force-recreate` para montar los scripts actualizados.
2. Ejecutar `npm run db:seed`.

Usuario de demostración:

- Código de clínica: `WELLQ-DEMO`
- Correo: `admin@wellq.cl`
- Contraseña: `WellQ2026!`

Enviar `POST http://localhost:3000/api/v1/auth/login` con:

```json
{
  "clientCode": "WELLQ-DEMO",
  "email": "admin@wellq.cl",
  "password": "WellQ2026!"
}
```

## Próximo módulo

El módulo de pacientes ya permite listar, buscar, consultar, crear, actualizar y eliminar lógicamente registros mediante `/api/v1/patients`.

El módulo de exámenes permite registrar, listar, consultar, actualizar y eliminar lógicamente exámenes mediante `/api/v1/exams`.

Los archivos se cargan con `multipart/form-data`, usando el campo `file`, en `/api/v1/exams/:id/file`. Se permiten PDF, JPG y PNG, con un máximo local de 10 MB. La vista previa y descarga requieren JWT y permisos.

La auditoría registra `LOGIN`, `VIEW_EXAM`, `UPLOAD_EXAM`, `DOWNLOAD_EXAM` y `DELETE_EXAM`, además de operaciones de creación y actualización. La API usa el `clientId` firmado en el JWT para limitar cada consulta al tenant autenticado.

El historial se puede revisar con `GET /api/v1/audit`; requiere el permiso `audit:read` y siempre queda limitado a la clínica del JWT.

## Carga clínica de Alloxentric

La API implementa los once endpoints de carga, consulta, edición, eliminación lógica, descarga firmada y revisión clínica bajo `/api/v1/clinical-tests` y `/api/v1/patients/:patient_id/clinical-tests`. El paciente se obtiene del JWT; las cuentas clínicas solo acceden a pacientes con una relación registrada en `patient_clinician_access`. El módulo exige que `clinical_test_upload` esté habilitado en `client_features`.

Las cargas usan URLs MinIO firmadas por 15 minutos y se almacenan en cuarentena. El endpoint `complete` verifica el objeto y lo encola en PostgreSQL; un worker valida SHA-256 y firma real, consulta ClamAV y solo entonces promueve el objeto a `private/` y permite el borrado local. Si ClamAV no está disponible, el worker reintenta y la app debe conservar su archivo local.

Las cuentas de paciente deben tener el rol `Paciente` y un `users.patient_id` asociado a un paciente de la misma clínica. El acceso de un clínico se configura mediante `patient_clinician_access`. El login local actual sigue sirviendo para el portal de la clínica; no convierte por sí solo una cuenta administrativa en cuenta de paciente.

Para una base PostgreSQL existente, aplicar las migraciones aditivas desde PowerShell:

```powershell
Set-Location C:\Users\renat\Downloads\WellQApp\WellQApp\outputs\wellq-backend
docker compose exec -T postgres psql -U wellq -d wellq -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/004_clinical_tests_upload.sql
```

En una instalación nueva, `docker compose up -d` crea los servicios PostgreSQL, MinIO, el inicializador del bucket y ClamAV. El análisis antimalware puede tardar al primer arranque mientras ClamAV prepara sus firmas.

La app Flutter aún requiere la pantalla de paciente y la cola local duradera con Drift para consumir este flujo en segundo plano; la carga directa de la pantalla de exámenes existente corresponde al portal y no reemplaza esa cola móvil.
