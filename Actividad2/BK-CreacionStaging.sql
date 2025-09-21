-- Se crea base de datos de STAGING y tablas
IF DB_ID('jardineria_stg') IS NULL
BEGIN
  EXEC('CREATE DATABASE jardineria_stg');
END;
GO

USE jardineria_stg;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='stg') EXEC('CREATE SCHEMA stg');
GO

-- Auditoría por lote
IF OBJECT_ID('stg.lotes') IS NOT NULL DROP TABLE stg.lotes;
CREATE TABLE stg.lotes (
  batch_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
  source_system  VARCHAR(50) NOT NULL DEFAULT('JARDINERIA'),
  started_at     DATETIME2(0) NOT NULL DEFAULT(SYSDATETIME()),
  ended_at       DATETIME2(0) NULL,
  status         VARCHAR(20)  NOT NULL DEFAULT('RUNNING'),
  rows_loaded    INT          NOT NULL DEFAULT(0),
  notes          VARCHAR(4000) NULL
);

-- MAESTROS
IF OBJECT_ID('stg.oficina') IS NOT NULL DROP TABLE stg.oficina;
CREATE TABLE stg.oficina (
  id_oficina        INT           NULL,
  descripcion       VARCHAR(10)   NULL,
  ciudad            VARCHAR(30)   NULL,
  pais              VARCHAR(50)   NULL,
  region            VARCHAR(50)   NULL,
  codigo_postal     VARCHAR(10)   NULL,
  telefono          VARCHAR(20)   NULL,
  linea_direccion1  VARCHAR(50)   NULL,
  linea_direccion2  VARCHAR(50)   NULL,
  _batch_id         BIGINT        NOT NULL,
  _extract_ts       DATETIME2(0)  NOT NULL,
  _source           VARCHAR(50)   NOT NULL DEFAULT('jardineria.oficina')
);

IF OBJECT_ID('stg.empleado') IS NOT NULL DROP TABLE stg.empleado;
CREATE TABLE stg.empleado (
  id_empleado       INT           NULL,
  nombre            VARCHAR(50)   NULL,
  apellido1         VARCHAR(50)   NULL,
  apellido2         VARCHAR(50)   NULL,
  extension         VARCHAR(10)   NULL,
  email             VARCHAR(100)  NULL,
  id_oficina        INT           NULL,
  id_jefe           INT           NULL,
  puesto            VARCHAR(50)   NULL,
  _batch_id         BIGINT        NOT NULL,
  _extract_ts       DATETIME2(0)  NOT NULL,
  _source           VARCHAR(50)   NOT NULL DEFAULT('jardineria.empleado')
);

IF OBJECT_ID('stg.categoria_producto') IS NOT NULL DROP TABLE stg.categoria_producto;
CREATE TABLE stg.categoria_producto (
  id_categoria      INT           NULL,
  desc_categoria    VARCHAR(50)   NULL,
  descripcion_texto VARCHAR(MAX)  NULL,
  descripcion_html  VARCHAR(MAX)  NULL,
  imagen            VARCHAR(256)  NULL,
  _batch_id         BIGINT        NOT NULL,
  _extract_ts       DATETIME2(0)  NOT NULL,
  _source           VARCHAR(50)   NOT NULL DEFAULT('jardineria.categoria_producto')
);

IF OBJECT_ID('stg.producto') IS NOT NULL DROP TABLE stg.producto;
CREATE TABLE stg.producto (
  id_producto       INT           NULL,
  codigo_producto   VARCHAR(15)   NULL,
  nombre            VARCHAR(70)   NULL,
  categoria         INT           NULL,
  dimensiones       VARCHAR(25)   NULL,
  proveedor         VARCHAR(50)   NULL,
  descripcion       VARCHAR(MAX)  NULL,
  cantidad_en_stock SMALLINT      NULL,
  precio_venta      DECIMAL(15,2) NULL,
  precio_proveedor  DECIMAL(15,2) NULL,
  _batch_id         BIGINT        NOT NULL,
  _extract_ts       DATETIME2(0)  NOT NULL,
  _source           VARCHAR(50)   NOT NULL DEFAULT('jardineria.producto')
);

IF OBJECT_ID('stg.cliente') IS NOT NULL DROP TABLE stg.cliente;
CREATE TABLE stg.cliente (
  id_cliente              INT           NULL,
  nombre_cliente          VARCHAR(50)   NULL,
  nombre_contacto         VARCHAR(30)   NULL,
  apellido_contacto       VARCHAR(30)   NULL,
  telefono                VARCHAR(15)   NULL,
  fax                     VARCHAR(15)   NULL,
  linea_direccion1        VARCHAR(50)   NULL,
  linea_direccion2        VARCHAR(50)   NULL,
  ciudad                  VARCHAR(50)   NULL,
  region                  VARCHAR(50)   NULL,
  pais                    VARCHAR(50)   NULL,
  codigo_postal           VARCHAR(10)   NULL,
  id_empleado_rep_ventas  INT           NULL,
  limite_credito          DECIMAL(15,2) NULL,
  _batch_id               BIGINT        NOT NULL,
  _extract_ts             DATETIME2(0)  NOT NULL,
  _source                 VARCHAR(50)   NOT NULL DEFAULT('jardineria.cliente')
);

-- TRANSACCIONALES
IF OBJECT_ID('stg.pedido') IS NOT NULL DROP TABLE stg.pedido;
CREATE TABLE stg.pedido (
  id_pedido        INT           NULL,
  fecha_pedido     DATE          NULL,
  fecha_esperada   DATE          NULL,
  fecha_entrega    DATE          NULL,
  estado           VARCHAR(15)   NULL,
  comentarios      VARCHAR(MAX)  NULL,
  id_cliente       INT           NULL,
  _batch_id        BIGINT        NOT NULL,
  _extract_ts      DATETIME2(0)  NOT NULL,
  _source          VARCHAR(50)   NOT NULL DEFAULT('jardineria.pedido')
);

IF OBJECT_ID('stg.detalle_pedido') IS NOT NULL DROP TABLE stg.detalle_pedido;
CREATE TABLE stg.detalle_pedido (
  id_detalle_pedido INT           NULL,
  id_pedido         INT           NULL,
  id_producto       INT           NULL,
  cantidad          INT           NULL,
  precio_unidad     DECIMAL(15,2) NULL,
  numero_linea      SMALLINT      NULL,
  _batch_id         BIGINT        NOT NULL,
  _extract_ts       DATETIME2(0)  NOT NULL,
  _source           VARCHAR(50)   NOT NULL DEFAULT('jardineria.detalle_pedido')
);

IF OBJECT_ID('stg.pago') IS NOT NULL DROP TABLE stg.pago;
CREATE TABLE stg.pago (
  id_pago      INT           NULL,
  id_cliente   INT           NULL,
  forma_pago   VARCHAR(40)   NULL,
  id_transaccion VARCHAR(50) NULL,
  fecha_pago   DATE          NULL,
  total        DECIMAL(15,2) NULL,
  _batch_id    BIGINT        NOT NULL,
  _extract_ts  DATETIME2(0)  NOT NULL,
  _source      VARCHAR(50)   NOT NULL DEFAULT('jardineria.pago')
);
