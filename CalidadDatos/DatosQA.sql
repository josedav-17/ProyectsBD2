
------------- QA FULL RUN - jardineria_dw (una sola corrida)
USE jardineria_dw;


--Infra de resultados DQ
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='dq') EXEC('CREATE SCHEMA dq');

IF OBJECT_ID('dq.dq_run') IS NULL
BEGIN
  CREATE TABLE dq.dq_run(
    run_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    started_at  DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    finished_at DATETIME2(0) NULL,
    notes       VARCHAR(4000) NULL
  );
END

IF OBJECT_ID('dq.dq_results') IS NULL
BEGIN
  CREATE TABLE dq.dq_results(
    run_id     BIGINT        NOT NULL,
    checked_at DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
    layer      VARCHAR(20)   NOT NULL,
    object_name SYSNAME      NOT NULL,
    check_id   VARCHAR(50)   NOT NULL,
    severity   VARCHAR(10)   NOT NULL,  --TIPOS DE CATEGORIA: INFO | WARN | ERROR
    metric     VARCHAR(100)  NOT NULL,
    value_num  DECIMAL(38,6) NULL,
    value_txt  VARCHAR(4000) NULL
  );
END

DECLARE @run_id BIGINT;
INSERT INTO dq.dq_run (notes) VALUES ('QA FULL RUN - estrella dw');
SET @run_id = SCOPE_IDENTITY();


-- TABLA DimFecha
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimFecha','DFECHA_001','INFO','Total filas',COUNT(*),NULL
FROM dw.DimFecha;

-- rangos básicos
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimFecha','DFECHA_002','ERROR','Rango invalido',COUNT(*),
       'Mes(1-12), Dia(1-31), Trimestre(1-4), SemanaAnio(1-53)'
FROM dw.DimFecha
WHERE Mes NOT BETWEEN 1 AND 12
   OR Dia NOT BETWEEN 1 AND 31
   OR Trimestre NOT BETWEEN 1 AND 4
   OR SemanaAnio NOT BETWEEN 1 AND 53;

-- Mes vs MONTH(Fecha)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimFecha','DFECHA_003','ERROR','Mes no alineado',COUNT(*),
       'Mes <> MONTH(Fecha)'
FROM dw.DimFecha
WHERE Mes <> DATEPART(MONTH, Fecha);

-- fin de semana
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimFecha','DFECHA_004','ERROR','Finde incorrecto',COUNT(*),
       'EsFinDeSemana debe ser 1 para Sat/Sun; 0 para el resto'
FROM dw.DimFecha
WHERE (FORMAT(Fecha,'ddd','en-US') IN ('Sat','Sun') AND EsFinDeSemana=0)
   OR (FORMAT(Fecha,'ddd','en-US') NOT IN ('Sat','Sun') AND EsFinDeSemana=1);


-- DimCliente
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimCliente','DCLI_000','INFO','Total filas',COUNT(*),NULL
FROM dw.DimCliente;

-- NK duplicada
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimCliente','DCLI_001','ERROR','NK duplicada',COUNT(*),'IdCliente NK duplicado'
FROM (SELECT IdClienteNK FROM dw.DimCliente GROUP BY IdClienteNK HAVING COUNT(*)>1) x;

-- requeridos
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimCliente','DCLI_002','ERROR','Requeridos nulos',COUNT(*),
       'IdClienteNK NULL o NombreCliente vacío'
FROM dw.DimCliente
WHERE IdClienteNK IS NULL OR LTRIM(RTRIM(ISNULL(NombreCliente,'')))='';

-- DimCategoria & DimProducto
-- categoría duplicada (NK)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimCategoria','DCAT_001','ERROR','NK duplicada',COUNT(*),'IdCategoria NK duplicada'
FROM (SELECT IdCategoriaNK FROM dw.DimCategoria GROUP BY IdCategoriaNK HAVING COUNT(*)>1) x;

-- producto duplicado (NK)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimProducto','DPROD_001','ERROR','NK duplicada',COUNT(*),'IdProducto NK duplicado'
FROM (SELECT IdProductoNK FROM dw.DimProducto GROUP BY IdProductoNK HAVING COUNT(*)>1) x;

-- producto requeridos
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimProducto','DPROD_002','ERROR','Requeridos nulos',COUNT(*),
       'IdProductoNK NULL o NombreProducto vacío'
FROM dw.DimProducto
WHERE IdProductoNK IS NULL OR LTRIM(RTRIM(ISNULL(NombreProducto,'')))='';

-- FK categoría
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimProducto','DPROD_003','ERROR','Categoria invalida',COUNT(*),
       'ClaveCategoria no existe en DimCategoria'
FROM dw.DimProducto p
LEFT JOIN dw.DimCategoria c ON c.ClaveCategoria = p.ClaveCategoria
WHERE p.ClaveCategoria IS NOT NULL AND c.ClaveCategoria IS NULL;

-- DimOficina & DimEmpleado
-- oficina duplicada (NK)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimOficina','DOFI_001','ERROR','NK duplicada',COUNT(*),'IdOficina NK duplicada'
FROM (SELECT IdOficinaNK FROM dw.DimOficina GROUP BY IdOficinaNK HAVING COUNT(*)>1) x;

-- empleado duplicada (NK)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimEmpleado','DEMP_001','ERROR','NK duplicada',COUNT(*),'IdEmpleado NK duplicado'
FROM (SELECT IdEmpleadoNK FROM dw.DimEmpleado GROUP BY IdEmpleadoNK HAVING COUNT(*)>1) x;

-- requeridos empleado
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimEmpleado','DEMP_002','ERROR','Requeridos nulos',COUNT(*),
       'IdEmpleadoNK NULL o Nombre/Apellido1 vacíos'
FROM dw.DimEmpleado
WHERE IdEmpleadoNK IS NULL
   OR LTRIM(RTRIM(ISNULL(Nombre,'')))=''
   OR LTRIM(RTRIM(ISNULL(Apellido1,'')))='';

-- email simple inválido
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimEmpleado','DEMP_003','WARN','Email invalido',COUNT(*),
       'No coincide con _@_._ o contiene espacios'
FROM dw.DimEmpleado
WHERE Email IS NOT NULL AND (Email NOT LIKE '%_@_%._%' OR Email LIKE '% %');

-- oficina debe existir
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.DimEmpleado','DEMP_004','ERROR','Oficina invalida',COUNT(*),
       'IdOficinaNK informado no existe en DimOficina'
FROM dw.DimEmpleado e
LEFT JOIN dw.DimOficina o ON o.IdOficinaNK = e.IdOficinaNK
WHERE e.IdOficinaNK IS NOT NULL AND o.IdOficinaNK IS NULL;


-- FactVentas - Integridad & Granularidad
-- total
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_000','INFO','Total filas',COUNT(*),NULL
FROM dw.FactVentas;

-- PK duplicada (IdPedido, NumeroLinea)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_001','ERROR','(IdPedido, NumeroLinea) PK duplicada',COUNT(*),
       'IdPedido+NumeroLinea duplicados'
FROM (SELECT IdPedido, NumeroLinea FROM dw.FactVentas GROUP BY IdPedido, NumeroLinea HAVING COUNT(*)>1) x;

-- orfandades obligatorias
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_002','ERROR','Orfanos producto',COUNT(*),'ClaveProducto sin DimProducto'
FROM dw.FactVentas f LEFT JOIN dw.DimProducto p ON p.ClaveProducto=f.ClaveProducto
WHERE p.ClaveProducto IS NULL;

INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_003','ERROR','Orfanos cliente',COUNT(*),'ClaveCliente sin DimCliente'
FROM dw.FactVentas f LEFT JOIN dw.DimCliente c ON c.ClaveCliente=f.ClaveCliente
WHERE c.ClaveCliente IS NULL;

INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_006','ERROR','Orfanos fecha pedido',COUNT(*),'ClaveFechaPedido sin DimFecha'
FROM dw.FactVentas f LEFT JOIN dw.DimFecha d ON d.ClaveFecha=f.ClaveFechaPedido
WHERE d.ClaveFecha IS NULL;

-- cliente por pedido
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_007','ERROR','Varios clientes X pedido',COUNT(*),
       'Más de un cliente por IdPedido'
FROM (SELECT IdPedido FROM dw.FactVentas GROUP BY IdPedido HAVING COUNT(DISTINCT ClaveCliente)>1) x;

-- fecha de pedido por pedido
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_008','ERROR','Varias fechas pedido',COUNT(*),
       'Más de una ClaveFechaPedido por IdPedido'
FROM (SELECT IdPedido FROM dw.FactVentas GROUP BY IdPedido HAVING COUNT(DISTINCT ClaveFechaPedido)>1) x;


-- FactVentas - Temporal (Esta separado en 2 posibles errores + 1 warn)

-- Pedido > Entrega
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_T_PED_GT_ENT','ERROR','Pedido mayor que entrega',
       SUM(CASE WHEN f.ClaveFechaEntrega IS NOT NULL AND fp.Fecha > fe.Fecha THEN 1 ELSE 0 END),
       'FechaPedido > FechaEntrega'
FROM dw.FactVentas f
JOIN dw.DimFecha fp ON fp.ClaveFecha=f.ClaveFechaPedido
LEFT JOIN dw.DimFecha fe ON fe.ClaveFecha=f.ClaveFechaEntrega;

-- Pedido > Esperada
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_T_PED_GT_EXP','ERROR','Pedido mayor que esperada',
       SUM(CASE WHEN f.ClaveFechaEsperada IS NOT NULL AND fp.Fecha > fx.Fecha THEN 1 ELSE 0 END),
       'FechaPedido > FechaEsperada'
FROM dw.FactVentas f
JOIN dw.DimFecha fp ON fp.ClaveFecha=f.ClaveFechaPedido
LEFT JOIN dw.DimFecha fx ON fx.ClaveFecha=f.ClaveFechaEsperada;

-- Entrega > Esperada (retraso)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_T_ENT_GT_EXP','WARN','Entrega mayor que esperada',
       SUM(CASE WHEN f.ClaveFechaEntrega IS NOT NULL AND f.ClaveFechaEsperada IS NOT NULL AND fe.Fecha > fx.Fecha THEN 1 ELSE 0 END),
       'FechaEntrega > FechaEsperada'
FROM dw.FactVentas f
LEFT JOIN dw.DimFecha fe ON fe.ClaveFecha=f.ClaveFechaEntrega
LEFT JOIN dw.DimFecha fx ON fx.ClaveFecha=f.ClaveFechaEsperada;


-- FactVentas - Valores & Reconciliación

-- cantidad/precio no positivos
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_V_001','ERROR','Cantidad precio no positivos',COUNT(*),
       'Cantidad<=0 o PrecioUnitario<=0'
FROM dw.FactVentas
WHERE Cantidad <= 0 OR PrecioUnitario <= 0;

-- importe negativo
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_V_002','ERROR','Importe negativo',COUNT(*),
       'ImporteLinea<0'
FROM dw.FactVentas
WHERE ImporteLinea < 0;

-- SUM calculado vs persistido (Reconciliacion)
INSERT INTO dq.dq_results (run_id,layer,object_name,check_id,severity,metric,value_num,value_txt)
SELECT @run_id,'DW','dw.FactVentas','FV_V_004','ERROR','Reconciliacion',
       CAST(ABS(SUM(ImporteLinea) - SUM(CAST(Cantidad AS DECIMAL(15,2))*PrecioUnitario)) AS DECIMAL(38,6)),
       'ABS(SUM(ImporteLinea) - SUM(Cantidad*PrecioUnitario))'
FROM dw.FactVentas;


-- mostrams resultados
UPDATE dq.dq_run SET finished_at = SYSDATETIME() WHERE run_id=@run_id;

SELECT layer, object_name, check_id, severity, metric, value_num, value_txt, checked_at
FROM dq.dq_results
WHERE run_id = @run_id
ORDER BY severity DESC, object_name, check_id;
