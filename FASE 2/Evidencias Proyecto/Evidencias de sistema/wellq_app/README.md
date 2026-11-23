# WellQ Flutter

Aplicación web de WellQ para login, pacientes, exámenes, carga de archivos, resultados clínicos y auditoría.

## Ejecutar en Windows

Inicia primero PostgreSQL, MinIO y la API desde una terminal de PowerShell:

```powershell
Set-Location 'C:\Users\renat\Downloads\WellQApp\WellQApp\outputs\wellq-backend'
if (!(Test-Path .env)) { Copy-Item .env.example .env }
docker compose up -d
npm install
npm run db:seed
npm run dev
```

En una segunda terminal, ejecuta Flutter en Chrome:

```powershell
Set-Location 'C:\Users\renat\Downloads\WellQApp\WellQApp\outputs\wellq_app'
& '..\..\work\flutter-sdk\bin\flutter.bat' pub get
& '..\..\work\flutter-sdk\bin\flutter.bat' run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1
```

La API y su documentación OpenAPI quedan en `http://localhost:3000/api/v1` y `http://localhost:3000/api/v1/openapi.json`.

## Usuario local de demostración

- Clínica: `WELLQ-DEMO`
- Correo: `admin@wellq.cl`
- Contraseña: `WellQ2026!`
