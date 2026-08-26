CREATE DATABASE IF NOT EXISTS TUCANCHAPE;
USE TUCANCHAPE;

CREATE TABLE Sucursal (
    IdSucursal INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(30) NOT NULL,
    Direccion VARCHAR(50) NOT NULL,
    UbicacionMapa VARCHAR(50) NULL
);

CREATE TABLE Cliente (
    IdCliente INT AUTO_INCREMENT PRIMARY KEY,
    DNI CHAR(8) NOT NULL UNIQUE,
    Nombres VARCHAR(30) NOT NULL,
    Apellidos VARCHAR(30) NOT NULL,
    Correo VARCHAR(50) NOT NULL UNIQUE,
    Telefono VARCHAR(9) NOT NULL,
    ContrasenaHash VARCHAR(255) NOT NULL,
    PuntosFidelidad INT NOT NULL DEFAULT 0,

    CONSTRAINT CK_Cliente_DNI 
        CHECK (DNI REGEXP '^[0-9]{8}$'),

    CONSTRAINT CK_Cliente_Telefono 
        CHECK (Telefono REGEXP '^9[0-9]{8}$'),

    CONSTRAINT CK_Cliente_Puntos
        CHECK (PuntosFidelidad >= 0)
);

CREATE TABLE Autenticacion (
    IdAutenticacion INT AUTO_INCREMENT PRIMARY KEY,
    IdCliente INT NOT NULL,
    CodigoOTP VARCHAR(10) NOT NULL,
    CorreoVerificacion VARCHAR(50) NOT NULL,

    CONSTRAINT FK_Autenticacion_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente)
);

CREATE TABLE Trabajador (
    IdTrabajador INT AUTO_INCREMENT PRIMARY KEY,
    DNI CHAR(8) NOT NULL UNIQUE,
    Nombres VARCHAR(30) NOT NULL,
    Apellidos VARCHAR(30) NOT NULL,
    PinHash VARCHAR(255) NOT NULL,
    Rol VARCHAR(25) NOT NULL,
    Correo VARCHAR(50) NOT NULL,
    Telefono VARCHAR(9) NOT NULL,

    CONSTRAINT CK_Trabajador_DNI 
        CHECK (DNI REGEXP '^[0-9]{8}$'),

    CONSTRAINT CK_Trabajador_Telefono 
        CHECK (Telefono REGEXP '^9[0-9]{8}$'),

    CONSTRAINT CK_Trabajador_Rol
        CHECK (Rol IN (
            'Administrador',
            'Cajero',
            'Vendedor',
            'Mantenimiento'
        ))
);

CREATE TABLE Cancha (
    IdCancha INT AUTO_INCREMENT PRIMARY KEY,
    IdSucursal INT NOT NULL,
    Nombre VARCHAR(25) NOT NULL,
    Tipo VARCHAR(20) NOT NULL,
    Estado VARCHAR(20) NOT NULL DEFAULT 'Disponible',

    CONSTRAINT FK_Cancha_Sucursal
        FOREIGN KEY (IdSucursal)
        REFERENCES Sucursal(IdSucursal),

    CONSTRAINT UQ_Cancha_Sucursal_Nombre
        UNIQUE (IdSucursal, Nombre),

    CONSTRAINT CK_Cancha_Tipo
        CHECK (Tipo IN (
            'Fútbol 8',
            'Vóley 5',
            'Minifútbol 6'
        )),

    CONSTRAINT CK_Cancha_Estado
        CHECK (Estado IN (
            'Disponible',
            'Reservada',
            'Ocupada',
            'Mantenimiento',
            'No disponible'
        ))
);

CREATE TABLE FranjaHoraria (
    IdFranjaHoraria INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(20) NOT NULL UNIQUE,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL,

    CONSTRAINT CK_Franja_Horas
        CHECK (HoraInicio < HoraFin),

    CONSTRAINT CK_Franja_Nombre
        CHECK (Nombre IN ('Mañana', 'Tarde', 'Noche'))
);

CREATE TABLE Tarifa (
    IdTarifa INT AUTO_INCREMENT PRIMARY KEY,
    IdCancha INT NOT NULL,
    IdFranjaHoraria INT NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Tarifa_Cancha
        FOREIGN KEY (IdCancha)
        REFERENCES Cancha(IdCancha),

    CONSTRAINT FK_Tarifa_Franja
        FOREIGN KEY (IdFranjaHoraria)
        REFERENCES FranjaHoraria(IdFranjaHoraria),

    CONSTRAINT UQ_Tarifa_Cancha_Franja
        UNIQUE (IdCancha, IdFranjaHoraria),

    CONSTRAINT CK_Tarifa_Monto
        CHECK (Monto > 0)
);

CREATE TABLE Reserva (
    IdReserva INT AUTO_INCREMENT PRIMARY KEY,
    IdCliente INT NOT NULL,
    IdCancha INT NOT NULL,
    IdFranjaHoraria INT NOT NULL,
    FechaReserva DATE NOT NULL,
    FechaCreacion DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    MontoTotal DECIMAL(10,2) NOT NULL,
    SaldoPendiente DECIMAL(10,2) NOT NULL,
    EstadoReserva VARCHAR(25) NOT NULL DEFAULT 'Pendiente de pago',

    CONSTRAINT FK_Reserva_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente),

    CONSTRAINT FK_Reserva_Cancha
        FOREIGN KEY (IdCancha)
        REFERENCES Cancha(IdCancha),

    CONSTRAINT FK_Reserva_Franja
        FOREIGN KEY (IdFranjaHoraria)
        REFERENCES FranjaHoraria(IdFranjaHoraria),

    CONSTRAINT CK_Reserva_Montos
        CHECK (
            MontoTotal > 0
            AND SaldoPendiente >= 0
            AND SaldoPendiente <= MontoTotal
        ),

    CONSTRAINT CK_Reserva_Estado
        CHECK (EstadoReserva IN (
            'Pendiente de pago',
            'Confirmada',
            'Cancelada',
            'Completada',
            'Expirada'
        ))
);

CREATE TABLE Pago (
    IdPago INT AUTO_INCREMENT PRIMARY KEY,
    IdReserva INT NOT NULL,
    MontoPagado DECIMAL(10,2) NOT NULL,
    TipoPago VARCHAR(25) NOT NULL,
    ReferenciaAPI VARCHAR(100) NULL,
    FechaPago DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_Pago_Reserva
        FOREIGN KEY (IdReserva)
        REFERENCES Reserva(IdReserva),

    CONSTRAINT CK_Pago_Monto
        CHECK (MontoPagado > 0),

    CONSTRAINT CK_Pago_Tipo
        CHECK (TipoPago IN ('Yape', 'Adelanto', 'Efectivo'))
);

CREATE TABLE Comprobante (
    IdComprobante INT AUTO_INCREMENT PRIMARY KEY,
    IdPago INT NOT NULL UNIQUE,
    TipoComprobante VARCHAR(10) NOT NULL,
    NumeroComprobante VARCHAR(30) NOT NULL UNIQUE,
    DatosCliente VARCHAR(300) NOT NULL,
    FechaEmision DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_Comprobante_Pago
        FOREIGN KEY (IdPago)
        REFERENCES Pago(IdPago),

    CONSTRAINT CK_Comprobante_Tipo
        CHECK (TipoComprobante IN ('Boleta', 'Factura'))
);

CREATE TABLE AsignacionMantenimiento (
    IdAsignacion INT AUTO_INCREMENT PRIMARY KEY,
    IdCancha INT NOT NULL,
    IdPersonalMantenimiento INT NOT NULL,
    IdAdministrador INT NOT NULL,
    FechaAsignacion DATE NOT NULL,
    Descripcion VARCHAR(500) NOT NULL,

    CONSTRAINT FK_Asignacion_Cancha
        FOREIGN KEY (IdCancha)
        REFERENCES Cancha(IdCancha),

    CONSTRAINT FK_Asignacion_Personal
        FOREIGN KEY (IdPersonalMantenimiento)
        REFERENCES Trabajador(IdTrabajador),

    CONSTRAINT FK_Asignacion_Administrador
        FOREIGN KEY (IdAdministrador)
        REFERENCES Trabajador(IdTrabajador)
);

CREATE TABLE Evento (
    IdEvento INT AUTO_INCREMENT PRIMARY KEY,
    IdCliente INT NOT NULL,
    Descripcion VARCHAR(500) NOT NULL,
    FechaSolicitada DATE NOT NULL,

    CONSTRAINT FK_Evento_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente)
);

CREATE TABLE Beneficio (
    IdBeneficio INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(500) NOT NULL,
    PuntosRequeridos INT NOT NULL,

    CONSTRAINT CK_Beneficio_Puntos
        CHECK (PuntosRequeridos >= 0)
);

CREATE TABLE ClienteBeneficio (
    IdCliente INT NOT NULL,
    IdBeneficio INT NOT NULL,
    FechaCanje DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (IdCliente, IdBeneficio),

    CONSTRAINT FK_ClienteBeneficio_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente),

    CONSTRAINT FK_ClienteBeneficio_Beneficio
        FOREIGN KEY (IdBeneficio)
        REFERENCES Beneficio(IdBeneficio)
);

CREATE TABLE Venta (
    IdVenta INT AUTO_INCREMENT PRIMARY KEY,
    IdTrabajador INT NOT NULL,
    FechaVenta DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Total DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Venta_Trabajador
        FOREIGN KEY (IdTrabajador)
        REFERENCES Trabajador(IdTrabajador),

    CONSTRAINT CK_Venta_Total
        CHECK (Total > 0)
);

CREATE TABLE MovimientoCaja (
    IdMovimientoCaja INT AUTO_INCREMENT PRIMARY KEY,
    IdTrabajador INT NOT NULL,
    IdReserva INT NULL,
    IdVenta INT NULL,
    FechaMovimiento DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TipoMovimiento VARCHAR(10) NOT NULL, -- 'Apertura', 'Cierre', 'Ingreso', 'Gasto'
    Importe DECIMAL(10,2) NOT NULL,
    Concepto VARCHAR(250) NOT NULL,

    CONSTRAINT FK_Movimiento_Trabajador
        FOREIGN KEY (IdTrabajador)
        REFERENCES Trabajador(IdTrabajador),

    CONSTRAINT FK_Movimiento_Reserva
        FOREIGN KEY (IdReserva)
        REFERENCES Reserva(IdReserva),

    CONSTRAINT FK_Movimiento_Venta
        FOREIGN KEY (IdVenta)
        REFERENCES Venta(IdVenta),

    CONSTRAINT CK_Movimiento_Tipo
        CHECK (TipoMovimiento IN ('Apertura', 'Cierre', 'Ingreso', 'Gasto')),

    CONSTRAINT CK_Movimiento_Importe
        CHECK (Importe >= 0),

    CONSTRAINT CK_Movimiento_Origen
        CHECK (IdReserva IS NOT NULL OR IdVenta IS NOT NULL OR TipoMovimiento IN ('Apertura', 'Cierre', 'Gasto'))
);