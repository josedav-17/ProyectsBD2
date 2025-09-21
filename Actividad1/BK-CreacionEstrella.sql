-- Crea Data Mart y estructura estrella
IF DB_ID('jardineria_dw') IS NULL
  EXEC('CREATE DATABASE jardineria_dw');
GO
USE jardineria_dw;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='dw') EXEC('CREATE SCHEMA dw');
GO

-- DimFecha
IF OBJECT_ID('dw.DimFecha') IS NOT NULL DROP TABLE dw.DimFecha;
CREATE TABLE dw.DimFecha(
  ClaveFecha     INT PRIMARY KEY,
  Fecha          DATE NOT NULL,
  Dia            TINYINT NOT NULL,
  Mes            TINYINT NOT NULL,
  NombreMes      VARCHAR(20) NOT NULL,
  Trimestre      TINYINT NOT NULL,
  Anio           SMALLINT NOT NULL,
  SemanaAnio     TINYINT NOT NULL,
  EsFinDeSemana  BIT NOT NULL
);

-- DimCliente
IF OBJECT_ID('dw.DimCliente') IS NOT NULL DROP TABLE dw.DimCliente;
CREATE TABLE dw.DimCliente(
  ClaveCliente   INT IDENTITY(1,1) PRIMARY KEY,
  IdClienteNK    INT NOT NULL UNIQUE,
  NombreCliente  VARCHAR(50),
  NombreContacto VARCHAR(30),
  ApellidoContacto VARCHAR(30),
  Telefono       VARCHAR(15),
  Ciudad         VARCHAR(50),
  Region         VARCHAR(50),
  Pais           VARCHAR(50),
  CodigoPostal   VARCHAR(10),
  LimiteCredito  DECIMAL(15,2)
);

-- DimCategoria
IF OBJECT_ID('dw.DimCategoria') IS NOT NULL DROP TABLE dw.DimCategoria;
CREATE TABLE dw.DimCategoria(
  ClaveCategoria INT IDENTITY(1,1) PRIMARY KEY,
  IdCategoriaNK  INT NOT NULL UNIQUE,
  NombreCategoria VARCHAR(50)
);

-- DimProducto
IF OBJECT_ID('dw.DimProducto') IS NOT NULL DROP TABLE dw.DimProducto;
CREATE TABLE dw.DimProducto(
  ClaveProducto  INT IDENTITY(1,1) PRIMARY KEY,
  IdProductoNK   INT NOT NULL UNIQUE,
  CodigoProducto VARCHAR(15),
  NombreProducto VARCHAR(70),
  ClaveCategoria INT NULL REFERENCES dw.DimCategoria(ClaveCategoria),
  Proveedor      VARCHAR(50),
  Dimensiones    VARCHAR(25)
);

-- DimOficina
IF OBJECT_ID('dw.DimOficina') IS NOT NULL DROP TABLE dw.DimOficina;
CREATE TABLE dw.DimOficina(
  ClaveOficina  INT IDENTITY(1,1) PRIMARY KEY,
  IdOficinaNK   INT NOT NULL UNIQUE,
  Descripcion   VARCHAR(10),
  Ciudad        VARCHAR(30),
  Pais          VARCHAR(50),
  Region        VARCHAR(50),
  CodigoPostal  VARCHAR(10)
);

-- DimEmpleado
IF OBJECT_ID('dw.DimEmpleado') IS NOT NULL DROP TABLE dw.DimEmpleado;
CREATE TABLE dw.DimEmpleado(
  ClaveEmpleado INT IDENTITY(1,1) PRIMARY KEY,
  IdEmpleadoNK  INT NOT NULL UNIQUE,
  Nombre        VARCHAR(50),
  Apellido1     VARCHAR(50),
  Apellido2     VARCHAR(50),
  Email         VARCHAR(100),
  Puesto        VARCHAR(50),
  IdOficinaNK   INT NULL
);

-- FactVentas (MVF)
IF OBJECT_ID('dw.FactVentas') IS NOT NULL DROP TABLE dw.FactVentas;
CREATE TABLE dw.FactVentas(
  ClaveProducto      INT NOT NULL REFERENCES dw.DimProducto(ClaveProducto),
  ClaveCliente       INT NOT NULL REFERENCES dw.DimCliente(ClaveCliente),
  ClaveEmpleado      INT NULL     REFERENCES dw.DimEmpleado(ClaveEmpleado),
  ClaveOficina       INT NULL     REFERENCES dw.DimOficina(ClaveOficina),
  ClaveFechaPedido   INT NOT NULL REFERENCES dw.DimFecha(ClaveFecha),
  ClaveFechaEsperada INT NULL     REFERENCES dw.DimFecha(ClaveFecha),
  ClaveFechaEntrega  INT NULL     REFERENCES dw.DimFecha(ClaveFecha),
  IdPedido           INT NOT NULL,
  NumeroLinea        INT NOT NULL,
  Cantidad           INT NOT NULL,
  PrecioUnitario     DECIMAL(15,2) NOT NULL,
  ImporteLinea       AS (CAST(Cantidad AS DECIMAL(15,2)) * PrecioUnitario) PERSISTED,
  EstadoPedido       VARCHAR(15) NULL,
  CONSTRAINT PK_FactVentas PRIMARY KEY (IdPedido, NumeroLinea)
);

-- Índices de consulta
CREATE INDEX IX_FV_Fecha    ON dw.FactVentas(ClaveFechaPedido);
CREATE INDEX IX_FV_Producto ON dw.FactVentas(ClaveProducto);
CREATE INDEX IX_FV_Cliente  ON dw.FactVentas(ClaveCliente);
