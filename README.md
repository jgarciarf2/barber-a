# Juanjo Barber · reservas

Aplicación inicial con Next.js (frontend), Express (API), Supabase Postgres.

## Desarrollo local

1. Instala Node.js 20 o superior.
2. En Supabase crea un proyecto y ejecuta `server/supabase/migrations/001_bookings.sql` en SQL Editor.
3. Copia `server/.env.example` a `server/.env` y completa URL, service role key, correo/clave del barbero y un JWT secreto aleatorio.
4. Copia `client/.env.local.example` a `client/.env.local`.
5. En la raíz: `npm install`, luego `npm run dev`.
6. Reserva: `http://localhost:3000`. Panel: `http://localhost:3000/admin`.

`SUPABASE_SERVICE_ROLE_KEY` solo vive en el servidor Express. Nunca se agrega al cliente web. La tabla no tiene políticas RLS de acceso público; la API usa la clave de servicio. Asegura los secretos y aplica la migración antes de desplegar.

## Despliegue sugerido

- Supabase: crear proyecto de producción, correr la migración SQL y guardar URL y service role key.
- Express API: desplegar `server/` en Render, Railway o Fly.io como servicio Node. Variables: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `JWT_SECRET`, `CLIENT_ORIGIN` (dominio del frontend) y `PORT` (si el proveedor lo requiere). Health check `/api/health`.
- Next.js: desplegar `client/` en Vercel. Variable `NEXT_PUBLIC_API_URL=https://tu-api/api`.
- Configura CORS `CLIENT_ORIGIN` con el dominio real exacto y HTTPS.

## API

- `GET /api/availability?date=YYYY-MM-DD`: horarios de trabajo libres.
- `POST /api/bookings`: crea una cita, el servidor comprueba horario y Postgres impide duplicados simultáneos.
- `GET /api/bookings/:id`: consulta una reserva por identificador.
- `DELETE /api/bookings/:id`: cancela una reserva por identificador.
- `POST /api/admin/login`: inicio de sesión del barbero.
- `GET /api/admin/bookings?from=&to=&status=`: lista citas, requiere Bearer JWT.
- `DELETE /api/admin/bookings/:id`: cancelación administrativa, requiere Bearer JWT.

## Notas

La pantalla de reserva es un asistente de cuatro pasos, sin scroll en tamaños comunes, adaptable a móvil y escritorio. Los slots usan los horarios conversados: lunes a viernes de 9–12 y 14–19 cada 30 min; sábado 8–19 cada 40 min con pausa 12–12:40; domingo 9–13 cada 40 min. El cliente puede consultar su cita con el UUID recibido por API; añade una vista de consulta más adelante si deseas que lo haga desde la web. Las cancelaciones públicas por UUID deben cambiarse a un enlace/token secreto antes de abrir al público para evitar cancelaciones ajenas.

La confirmación abre acciones de WhatsApp y Google Calendar. El envío automático de WhatsApp no está conectado; requiere WhatsApp Business Platform y plantillas/configuración. El login inicial de admin usa una sola cuenta configurada por variables de entorno; para un uso más robusto, conviene Supabase Auth o guardar credenciales con hash.

## Completar los archivos `.env`

Ya están creados `server/.env` y `client/.env.local` para desarrollo local. Reemplaza los valores indicados en `server/.env`:

- `SUPABASE_URL`: en Supabase abre tu proyecto → **Project Settings → API** (o **Data API**) → Project URL.
- `SUPABASE_SERVICE_ROLE_KEY`: en la misma pantalla, sección **Project API keys**, copia la clave `service_role`/`secret`. Es un secreto de servidor: nunca lo pongas en `client/.env.local`, nunca lo publiques ni lo compartas en capturas. Si la interfaz ofrece claves `sb_secret_...`, usa la clave secreta actual del proyecto.
- `ADMIN_EMAIL`: el correo que usarás para iniciar sesión en `/admin`.
- `ADMIN_PASSWORD`: elige una contraseña larga, única y privada. Es la contraseña inicial del único administrador.
- `JWT_SECRET`: genera una clave aleatoria localmente con `openssl rand -base64 48` y pega el resultado aquí. No reutilices contraseñas.
- `CLIENT_ORIGIN`: deja `http://localhost:3000` para desarrollo. En producción pon el origen exacto del frontend, por ejemplo `https://reservas.tudominio.com` (sin ruta final).
- `PORT`: conserva `4000` localmente. El proveedor de hosting puede asignar este valor en producción.

Para obtener las variables de Supabase: crea una cuenta en supabase.com, crea un proyecto, espera a que termine la configuración y abre **Project Settings → API**. Ejecuta `server/supabase/migrations/001_bookings.sql` en la opción **SQL Editor → New query → Run**. Mantén el proyecto en privado.

No envíes los contenidos de `.env` por chat ni subas los archivos a Git. `.env` y `.env.local` deben permanecer locales; configura los mismos secretos en la sección Environment Variables del proveedor al desplegar. La clave pública `NEXT_PUBLIC_API_URL` sí es variable del frontend: local es `http://localhost:4000/api`, y en producción debe ser la URL pública del backend terminada en `/api`.

Si Supabase devuelve `42501 permission denied for table bookings`, vuelve a ejecutar al final del SQL Editor los `GRANT` que aparecen al final de `server/supabase/migrations/001_bookings.sql`. Esto concede acceso a `service_role` (la clave secreta del backend); no activa acceso público ni quita RLS.


Corte y barba ocupa 60 minutos (dos espacios de 30 min); los demás servicios ocupan 30. La disponibilidad evita mostrar turnos que se solapen con citas activas. La consulta pública de citas verifica nombre completo y celular juntos.

## Publicar la aplicación (Vercel + Render)

La aplicación vive en un monorepo. Publica cada carpeta como un servicio independiente; no despliegues el workspace raíz como una sola app.

### 1) Antes de publicar

- En GitHub revisa que `server/.env` y `client/.env.local` no estén en el repositorio. El `.gitignore` debe excluirlos. Si una clave secreta ya estuvo en GitHub, rótala antes del lanzamiento.
- Supabase: el proyecto y la tabla deben estar activos. Si la interfaz está consultando datos, verifica que la URL base y la clave secret del servidor estén actualizadas en el hosting de API.

### 2) API Express en Render

1. Render → **New → Web Service** → conecta el repositorio `barber-a`.
2. Configura **Root Directory** como la raíz del repositorio (vacío o `.`), **Runtime** Node, **Build Command** `npm install`, **Start Command** `npm --workspace server start` y **Health Check Path** `/api/health`. No pongas Root Directory `server`: el repositorio usa npm workspaces y el lockfile está en la raíz.
3. Añade estas variables en Environment:
   - `SUPABASE_URL`: URL base de Supabase, sin `/rest/v1/`.
   - `SUPABASE_SERVICE_ROLE_KEY`: clave `sb_secret_...` del proyecto, solo en Render.
   - `ADMIN_EMAIL`: correo de acceso privado al panel.
   - `ADMIN_PASSWORD`: contraseña fuerte del panel.
   - `JWT_SECRET`: secreto aleatorio largo. Genera uno con `openssl rand -base64 48`.
   - `CLIENT_ORIGIN`: temporalmente puedes usar el dominio de producción que asignará Vercel en el paso 3; vuelve a Render y cámbialo después del primer deploy.
   - `NODE_ENV=production`.
4. Crea el servicio. Espera el estado Live y copia su URL HTTPS, por ejemplo `https://juanjo-barber-api.onrender.com`. Comprueba que al abrir `/api/health` responde `{"ok":true}`.

### 3) Frontend Next.js en Vercel

1. Vercel → **Add New → Project** → importa el mismo repositorio.
2. En **Root Directory**, selecciona `client`. Vercel debe detectar Next.js; deja build e instalación automáticos.
3. En Environment Variables agrega `NEXT_PUBLIC_API_URL` con la URL del paso 2 terminada en `/api`, por ejemplo `https://juanjo-barber-api.onrender.com/api`.
4. Despliega y copia el dominio público Vercel.

### 4) CORS y comprobación final

1. Regresa a Render → API → Environment y define `CLIENT_ORIGIN` con el origen exacto Vercel, sin barra final ni rutas, por ejemplo `https://barber-a.vercel.app`. Si usas un dominio personalizado, agrega también ese origen separado por coma.
2. Guarda los cambios y espera que Render reinicie el servicio.
3. En la URL de Vercel verifica: carga inicial, disponibilidad, creación/cancelación de una reserva, consulta por nombre + celular, y acceso al panel `/admin`. El resumen del panel calcula ingresos solo de citas confirmadas.
4. Para cambios futuros, haz push a GitHub. Vercel y Render pueden redeplegar automáticamente sus respectivas carpetas.

### Nota de Render Free

El servicio gratuito puede entrar en suspensión por inactividad y tardar en despertar al primer acceso. Para reservas que deban estar disponibles de forma continua, consulta los planes y limitaciones actuales de Render antes de decidir mantener el servicio gratuito.
