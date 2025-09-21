/* 05_LOAD_DIMFECHA.sql */

-- Asegura BD/esquema/tabla
IF DB_ID('jardineria_dw') IS NULL EXEC('CREATE DATABASE jardineria_dw');
USE jardineria_dw;
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='dw') EXEC('CREATE SCHEMA dw');

IF OBJECT_ID('dw.DimFecha') IS NULL
BEGIN
  CREATE TABLE dw.DimFecha(
    ClaveFecha     INT         NOT NULL PRIMARY KEY,   -- yyyymmdd
    Fecha          DATE        NOT NULL,
    Dia            TINYINT     NOT NULL,
    Mes            TINYINT     NOT NULL,
    NombreMes      VARCHAR(20) NOT NULL,
    Trimestre      TINYINT     NOT NULL,
    Anio           SMALLINT    NOT NULL,
    SemanaAnio     TINYINT     NOT NULL,
    EsFinDeSemana  BIT         NOT NULL
  );
END;

-- Fila “unknown” (opcional)
IF NOT EXISTS (SELECT 1 FROM dw.DimFecha WHERE ClaveFecha = 19000101)
  INSERT INTO dw.DimFecha(ClaveFecha,Fecha,Dia,Mes,NombreMes,Trimestre,Anio,SemanaAnio,EsFinDeSemana)
  VALUES(19000101,'19000101',1,1,'January',1,1900,1,0);

-- Rango real desde STG (evita NULLs)
DECLARE @min DATE, @max DATE;

SELECT 
  @min = MIN(f),
  @max = MAX(f)
FROM (
  SELECT fecha_pedido   AS f FROM jardineria_stg.stg.pedido WHERE fecha_pedido   IS NOT NULL
  UNION ALL
  SELECT fecha_esperada AS f FROM jardineria_stg.stg.pedido WHERE fecha_esperada IS NOT NULL
  UNION ALL
  SELECT fecha_entrega  AS f FROM jardineria_stg.stg.pedido WHERE fecha_entrega  IS NOT NULL
  UNION ALL
  SELECT fecha_pago     AS f FROM jardineria_stg.stg.pago   WHERE fecha_pago     IS NOT NULL
) S;

IF @min IS NULL SET @min = '2000-01-01';
IF @max IS NULL SET @max = '2005-12-31';

;WITH Dates AS (
  SELECT @min AS dt
  UNION ALL
  SELECT DATEADD(DAY,1,dt) FROM Dates WHERE dt < @max
)
INSERT INTO dw.DimFecha(ClaveFecha,Fecha,Dia,Mes,NombreMes,Trimestre,Anio,SemanaAnio,EsFinDeSemana)
SELECT
  CONVERT(INT,FORMAT(dt,'yyyyMMdd')) AS ClaveFecha,
  dt                                 AS Fecha,
  DATEPART(DAY,dt)                   AS Dia,
  DATEPART(MONTH,dt)                 AS Mes,
  DATENAME(MONTH,dt)                 AS NombreMes,
  DATEPART(QUARTER,dt)               AS Trimestre,
  DATEPART(YEAR,dt)                  AS Anio,
  DATEPART(ISO_WEEK,dt)              AS SemanaAnio,     -- ISO week, más estable
  CASE WHEN DATEPART(WEEKDAY,dt) IN (1,7) THEN 1 ELSE 0 END AS EsFinDeSemana
FROM Dates
WHERE NOT EXISTS (SELECT 1 FROM dw.DimFecha x WHERE x.Fecha = Dates.dt)
OPTION (MAXRECURSION 32767);
