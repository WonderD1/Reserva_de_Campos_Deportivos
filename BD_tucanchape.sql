CREATE DATABASE TUCANCHAPE;
GO

USE TUCANCHAPE;
GO

CREATE TABLE Sucursal (
    IdSucursal INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(30) NOT NULL,
    Direccion NVARCHAR(50) NOT NULL,
    UbicacionMapa NVARCHAR(50) NULL
);

CREATE TABLE Cliente (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    DNI CHAR(8) NOT NULL UNIQUE,
    Nombres NVARCHAR(30) NOT NULL,
    Apellidos NVARCHAR(30) NOT NULL,
    Correo NVARCHAR(50) NOT NULL UNIQUE,
    Telefono NVARCHAR(9) NOT NULL,
    ContrasenaHash NVARCHAR(50) NOT NULL,
    PuntosFidelidad INT NOT NULL DEFAULT 0,

    CONSTRAINT CK_Cliente_Puntos
        CHECK (PuntosFidelidad >= 0)
);

CREATE TABLE Autenticacion (
    IdAutenticacion INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    CodigoOTP NVARCHAR(10) NOT NULL,
    CorreoVerificacion NVARCHAR(50) NOT NULL,

    CONSTRAINT FK_Autenticacion_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente)
);

CREATE TABLE Trabajador (
    IdTrabajador INT IDENTITY(1,1) PRIMARY KEY,
    DNI CHAR(8) NOT NULL UNIQUE,
    Nombres NVARCHAR(30) NOT NULL,
    Apellidos NVARCHAR(30) NOT NULL,
    PinHash NVARCHAR(4) NOT NULL,
    Rol NVARCHAR(25) NOT NULL,

    CONSTRAINT CK_Trabajador_Rol
        CHECK (Rol IN (
            N'Administrador',
            N'Cajero',
            N'Vendedor',
            N'Mantenimiento'
        ))
);

CREATE TABLE Cancha (
    IdCancha INT IDENTITY(1,1) PRIMARY KEY,
    IdSucursal INT NOT NULL,
    Nombre NVARCHAR(25) NOT NULL,
    Tipo NVARCHAR(20) NOT NULL,
    Estado NVARCHAR(20) NOT NULL DEFAULT N'Disponible',

    CONSTRAINT FK_Cancha_Sucursal
        FOREIGN KEY (IdSucursal)
        REFERENCES Sucursal(IdSucursal),

    CONSTRAINT UQ_Cancha_Sucursal_Nombre
        UNIQUE (IdSucursal, Nombre),

    CONSTRAINT CK_Cancha_Tipo
        CHECK (Tipo IN (
            N'Fútbol 8',
            N'Vóley 5',
            N'Minifútbol 6'
        )),

    CONSTRAINT CK_Cancha_Estado
        CHECK (Estado IN (
            N'Disponible',
            N'Reservada',
            N'Ocupada',
            N'Mantenimiento',
            N'No disponible'
        ))
);

CREATE TABLE FranjaHoraria (
    IdFranjaHoraria INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(20) NOT NULL UNIQUE,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL,

    CONSTRAINT CK_Franja_Horas
        CHECK (HoraInicio < HoraFin),

    CONSTRAINT CK_Franja_Nombre
        CHECK (Nombre IN (N'Mañana', N'Tarde', N'Noche'))
);

CREATE TABLE Tarifa (
    IdTarifa INT IDENTITY(1,1) PRIMARY KEY,
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
    IdReserva INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    IdCancha INT NOT NULL,
    IdFranjaHoraria INT NOT NULL,
    FechaReserva DATE NOT NULL,
    FechaCreacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    MontoTotal DECIMAL(10,2) NOT NULL,
    SaldoPendiente DECIMAL(10,2) NOT NULL,
    EstadoReserva NVARCHAR(25) NOT NULL DEFAULT N'Pendiente de pago',

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
            N'Pendiente de pago',
            N'Confirmada',
            N'Cancelada',
            N'Completada',
            N'Expirada'
        ))
);
GO

-- Impide dos reservas activas de una misma cancha,
-- en la misma fecha y franja horaria.
CREATE UNIQUE INDEX UX_Reserva_Cancha_Fecha_Franja
ON Reserva (IdCancha, FechaReserva, IdFranjaHoraria)
WHERE EstadoReserva IN (N'Pendiente de pago', N'Confirmada');
GO

CREATE TABLE Pago (
    IdPago INT IDENTITY(1,1) PRIMARY KEY,
    IdReserva INT NOT NULL,
    MontoPagado DECIMAL(10,2) NOT NULL,
    TipoPago NVARCHAR(25) NOT NULL,
    ReferenciaAPI NVARCHAR(100) NULL,
    FechaPago DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Pago_Reserva
        FOREIGN KEY (IdReserva)
        REFERENCES Reserva(IdReserva),

    CONSTRAINT CK_Pago_Monto
        CHECK (MontoPagado > 0),

    CONSTRAINT CK_Pago_Tipo
        CHECK (TipoPago IN (N'Yape', N'Adelanto', N'Efectivo'))
);

CREATE TABLE Comprobante (
    IdComprobante INT IDENTITY(1,1) PRIMARY KEY,
    IdPago INT NOT NULL UNIQUE,
    TipoComprobante NVARCHAR(10) NOT NULL,
    NumeroComprobante NVARCHAR(30) NOT NULL UNIQUE,
    DatosCliente NVARCHAR(300) NOT NULL,
    FechaEmision DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Comprobante_Pago
        FOREIGN KEY (IdPago)
        REFERENCES Pago(IdPago),

    CONSTRAINT CK_Comprobante_Tipo
        CHECK (TipoComprobante IN (N'Boleta', N'Factura'))
);

CREATE TABLE AsignacionMantenimiento (
    IdAsignacion INT IDENTITY(1,1) PRIMARY KEY,
    IdCancha INT NOT NULL,
    IdPersonalMantenimiento INT NOT NULL,
    IdAdministrador INT NOT NULL,
    FechaAsignacion DATE NOT NULL,
    Descripcion NVARCHAR(500) NOT NULL,

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
    IdEvento INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    Descripcion NVARCHAR(500) NOT NULL,
    FechaSolicitada DATE NOT NULL,

    CONSTRAINT FK_Evento_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente)
);

CREATE TABLE Beneficio (
    IdBeneficio INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(500) NOT NULL,
    PuntosRequeridos INT NOT NULL,

    CONSTRAINT CK_Beneficio_Puntos
        CHECK (PuntosRequeridos >= 0)
);

CREATE TABLE ClienteBeneficio (
    IdCliente INT NOT NULL,
    IdBeneficio INT NOT NULL,
    FechaCanje DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    PRIMARY KEY (IdCliente, IdBeneficio),

    CONSTRAINT FK_ClienteBeneficio_Cliente
        FOREIGN KEY (IdCliente)
        REFERENCES Cliente(IdCliente),

    CONSTRAINT FK_ClienteBeneficio_Beneficio
        FOREIGN KEY (IdBeneficio)
        REFERENCES Beneficio(IdBeneficio)
);

CREATE TABLE Venta (
    IdVenta INT IDENTITY(1,1) PRIMARY KEY,
    IdVendedor INT NOT NULL,
    FechaVenta DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Total DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Venta_Vendedor
        FOREIGN KEY (IdVendedor)
        REFERENCES Trabajador(IdTrabajador),

    CONSTRAINT CK_Venta_Total
        CHECK (Total > 0)
);

CREATE TABLE MovimientoCaja (
    IdMovimientoCaja INT IDENTITY(1,1) PRIMARY KEY,
    IdCajero INT NOT NULL,
    IdReserva INT NULL,
    IdVenta INT NULL,
    FechaMovimiento DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    TipoMovimiento NVARCHAR(10) NOT NULL,
    Importe DECIMAL(10,2) NOT NULL,
    Concepto NVARCHAR(250) NOT NULL,

    CONSTRAINT FK_Movimiento_Cajero
        FOREIGN KEY (IdCajero)
        REFERENCES Trabajador(IdTrabajador),

    CONSTRAINT FK_Movimiento_Reserva
        FOREIGN KEY (IdReserva)
        REFERENCES Reserva(IdReserva),

    CONSTRAINT FK_Movimiento_Venta
        FOREIGN KEY (IdVenta)
        REFERENCES Venta(IdVenta),

    CONSTRAINT CK_Movimiento_Tipo
        CHECK (TipoMovimiento IN (N'Ingreso', N'Egreso')),

    CONSTRAINT CK_Movimiento_Importe
        CHECK (Importe > 0),

    CONSTRAINT CK_Movimiento_Origen
        CHECK (IdReserva IS NOT NULL OR IdVenta IS NOT NULL)
);
GO

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;