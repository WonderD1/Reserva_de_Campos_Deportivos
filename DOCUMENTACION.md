# Documentación Oficial - Sistema de Reserva de Campos Deportivos ("Tu Cancha Perú / El Papu")

Este documento detalla la arquitectura, análisis, diseño de base de datos, backend y desarrollo del frontend implementados para el sistema **Tu Cancha Perú (El Papu)**.

---

## 1. Análisis del Proyecto y Requerimientos
El proyecto consiste en una plataforma web integral para la gestión y reserva de canchas deportivas (fútbol, básquet, vóley) en múltiples sucursales, permitiendo:
- Gestión de clientes, trabajadores (administradores, cajeros, vendedores, personal de mantenimiento).
- Registro, inicio de sesión y autenticación segura con hash de contraseñas (`password_hash` / `password_verify`).
- Búsqueda y filtrado de canchas por deporte, fecha y franja horaria.
- Gestión de reservas, pagos (Yape, efectivo, adelantos), comprobantes (boleta/factura) y puntos de fidelidad.

---

## 2. Base de Datos (`BD_tucanchapeMysql.sql`)
La base de datos relacional en MySQL cuenta con las siguientes tablas principales:
- **Sucursal**: Almacena información de las sedes físicas.
- **Cliente**: Datos de los usuarios finales (DNI, Nombres, Apellidos, Correo, Teléfono, ContrasenaHash, PuntosFidelidad).
- **Trabajador**: Personal con roles restringidos (`Administrador`, `Cajero`, `Vendedor`, `Mantenimiento`).
- **Cancha**: Campos deportivos por sucursal, tipo y estado (`Disponible`, `Reservada`, `Mantenimiento`, etc.).
- **FranjaHoraria**: Bloques horarios (`Mañana`, `Tarde`, `Noche`).
- **Tarifa**: Precios asociados a cada cancha y franja horaria.
- **Reserva**: Solicitudes de reserva realizadas por los clientes con control de montos y estados.
- **Pago & Comprobante**: Registro de transacciones financieras y emisión de comprobantes.
- **MovimientoCaja & Venta**: Control de caja y ventas de productos o servicios adicionales.

---

## 3. Backend (PHP / API REST)
Ubicado en la carpeta `backend/`:
- **`config/db.php`**: Clase `Database` utilizando PDO con codificación UTF-8, manejo de excepciones y conexión segura a MySQL (`localhost:3306`, base de datos `tu_cancha_pe`).
- **`controllers/AuthController.php`**: Controlador que gestiona:
  - `registerCliente($data)`: Valida unicidad de DNI y correo, formato de DNI (8 dígitos) y teléfono (9 dígitos), aplica `password_hash($..., PASSWORD_BCRYPT)` y registra al cliente.
  - `loginCliente($data)`: Verifica credenciales mediante `password_verify` y retorna los datos del cliente.
- **`api/register.php` & `api/login.php`**: Endpoints con cabeceras CORS (`Access-Control-Allow-Origin: *`), validación de método HTTP POST y parseo de entradas JSON.

---

## 4. Frontend (HTML, CSS, JS)
Ubicado en la carpeta `frontend/`:
- **Paleta de Colores**:
  - Color Primario (Verde deportivo): `#10b981` (Hover: `#059669`)
  - Color Secundario (Amarillo/Gold): `#eab308` (Hover: `#ca8a04`)
- **Archivos Desarrollados**:
  1. **`css/styles.css`**: Estilos globales, variables CSS para modo claro y oscuro (`data-theme`), diseño Split-Screen para autenticación, tarjetas de deportes, grillas de canchas y banners de fidelización ("Club El Papu").
  2. **`login.html` & `js/login.js`**: Vista de inicio de sesión de cliente inspirada en los prototipos, con validaciones en tiempo real, alternar visibilidad de contraseña, cambio de tema claro/oscuro y consumo de `../backend/api/login.php`.
  3. **`register.html` & `js/register.js`**: Vista de registro de clientes con validación de DNI (8 dígitos) y teléfono (9 dígitos), conectada a `../backend/api/register.php`.
  4. **`index.html`**: Página principal (Home) que incluye:
     - Barra de navegación superior con logotipo "EP EL PAPU", enlaces de navegación, interruptor de tema y perfil de usuario conectado (`localStorage`).
     - Sección Hero con saludo personalizado y accesos directos.
     - Widget flotante de búsqueda rápida por deporte, fecha y horario.
     - Sección "Elige tu deporte" (Fútbol, Fútbol 7, Fútbol 11, Básquet, Vóley).
     - Grilla de "Nuestras canchas" con estado de disponibilidad, precios por hora y características.
     - Sección de Promociones (20% OFF y promo grupal).
     - Banner de fidelización "Club El Papu" (Acumula puntos, obtén beneficios y promos exclusivas).
