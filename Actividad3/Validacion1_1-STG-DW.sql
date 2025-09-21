
-- Deja el DW 1-1 con STG
BEGIN TRAN;

-- DELETE DW-only
DELETE fv
FROM jardineria_dw.dw.FactVentas AS fv
WHERE NOT EXISTS (
  SELECT 1
  FROM jardineria_stg.stg.detalle_pedido d
  WHERE d.id_pedido= fv.IdPedido 
  AND d.id_detalle_pedido=fv.NumeroLinea
);

--INSERT STG-only (por si algo faltaba por agregar)
INSERT INTO jardineria_dw.dw.FactVentas(
  ClaveProducto, ClaveCliente, ClaveEmpleado, ClaveOficina,
  ClaveFechaPedido, ClaveFechaEsperada, ClaveFechaEntrega,
  IdPedido, NumeroLinea, Cantidad, PrecioUnitario, EstadoPedido
)
SELECT
  dp.ClaveProducto, dc.ClaveCliente, de.ClaveEmpleado, dof.ClaveOficina,
  COALESCE(dfP.ClaveFecha,19000101), COALESCE(dfE.ClaveFecha,19000101), COALESCE(dfD.ClaveFecha,19000101),
  p.id_pedido, d.id_detalle_pedido, d.cantidad, d.precio_unidad, p.estado
FROM jardineria_stg.stg.detalle_pedido d
JOIN jardineria_stg.stg.pedido p   ON p.id_pedido=d.id_pedido
JOIN jardineria_dw.dw.DimProducto  dp ON dp.IdProductoNK = d.id_producto
JOIN jardineria_dw.dw.DimCliente   dc ON dc.IdClienteNK  = p.id_cliente
LEFT JOIN jardineria_stg.stg.cliente c ON c.id_cliente=p.id_cliente
LEFT JOIN jardineria_dw.dw.DimEmpleado de ON de.IdEmpleadoNK = c.id_empleado_rep_ventas
LEFT JOIN jardineria_stg.stg.empleado se ON se.id_empleado=c.id_empleado_rep_ventas
LEFT JOIN jardineria_dw.dw.DimOficina dof ON dof.IdOficinaNK = se.id_oficina
LEFT JOIN jardineria_dw.dw.DimFecha dfP ON dfP.Fecha = p.fecha_pedido
LEFT JOIN jardineria_dw.dw.DimFecha dfE ON dfE.Fecha = p.fecha_esperada
LEFT JOIN jardineria_dw.dw.DimFecha dfD ON dfD.Fecha = p.fecha_entrega
WHERE d.cantidad>0 AND d.precio_unidad>=0
  AND NOT EXISTS (
    SELECT 1 FROM jardineria_dw.dw.FactVentas fv
    WHERE fv.IdPedido=p.id_pedido AND fv.NumeroLinea=d.id_detalle_pedido
  );

COMMIT TRAN;



-- Conteos
SELECT
  (SELECT COUNT(*) FROM jardineria_stg.stg.detalle_pedido) AS lineas_stg,
  (SELECT COUNT(*) FROM jardineria_dw.dw.FactVentas) AS lineas_dw;

-- Importes
SELECT
  (SELECT SUM(CONVERT(DECIMAL(18,2), cantidad * precio_unidad))
   FROM jardineria_stg.stg.detalle_pedido) AS bruto_stg,
  (SELECT SUM(ImporteLinea) FROM jardineria_dw.dw.FactVentas)AS bruto_dw;

-- Diferencias campo a campo
SELECT
  fv.IdPedido, fv.NumeroLinea,
  fv.Cantidad AS cantidad_dw, d.cantidad AS cantidad_stg,
  fv.PrecioUnitario AS precio_dw, d.precio_unidad AS precio_stg
FROM jardineria_dw.dw.FactVentas fv
JOIN jardineria_stg.stg.detalle_pedido d
  ON d.id_pedido=fv.IdPedido AND d.id_detalle_pedido=fv.NumeroLinea
WHERE fv.Cantidad<>d.cantidad OR fv.PrecioUnitario<>d.precio_unidad;

-- Ventas por día
SELECT df.Fecha, SUM(fv.ImporteLinea) AS VentasDia
FROM jardineria_dw.dw.FactVentas fv
JOIN jardineria_dw.dw.DimFecha df ON df.ClaveFecha = fv.ClaveFechaPedido
GROUP BY df.Fecha
ORDER BY df.Fecha;