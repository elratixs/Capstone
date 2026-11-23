# WellQ MVP para revisión del equipo

Este paquete contiene el código fuente de la aplicación Flutter y la API local de WellQ. No incluye dependencias descargables, compilaciones, bases de datos, archivos clínicos ni el `.env` local de la máquina original.

## Requisitos

- Windows 10/11
- Git opcional
- Node.js LTS y npm
- Docker Desktop iniciado (Docker Compose v2)
- Flutter SDK compatible con el `pubspec.yaml` del proyecto
- Google Chrome

## Iniciar API y servicios

Abre PowerShell en esta carpeta y ejecuta:

```powershell
Set-Location .\wellq-backend
Copy-Item .env.example .env
docker compose up -d
npm ci
npm run db:seed
npm run dev
```

La API queda en `http://localhost:3000/api/v1`. Estado: `http://localhost:3000/api/v1/health/ready`. OpenAPI: `http://localhost:3000/api/v1/openapi.json`. Mantén esta terminal abierta.

## Iniciar la web

Abre una segunda ventana de PowerShell en la carpeta del ZIP y ejecuta:

```powershell
Set-Location .\wellq_app
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1
```

Flutter abrirá WellQ en Chrome. El puerto local puede cambiar según Flutter lo indique.

## Acceso de demostración local

- Clínica: `WELLQ-DEMO`
- Correo: `admin@wellq.cl`
- Contraseña: `WellQ2026!`

La cuenta y las credenciales son únicamente para la demostración local; no usar en producción. El paciente demo puede requerir creación/configuración separada en la base de datos local.

## Contenido

- `wellq_app/`: interfaz Flutter, portal paciente, fuentes web, pruebas y dependencias declaradas.
- `wellq-backend/`: API Node.js/TypeScript, migraciones SQL, pruebas, OpenAPI, Docker Compose y `.env.example`.

## Antes de compartir o desplegar

El archivo `.env.example` contiene secretos de desarrollo para ejecutar servicios locales; cámbialos antes de usar en cualquier entorno compartido. No copies el `.env` personal ni la base de datos/archivos locales. Este paquete representa el estado de desarrollo para revisión del equipo, no una entrega de producción ni una declaración de cumplimiento completo de las especificaciones de Alloxentric.
