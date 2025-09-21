
-- MERGE del hecho de ventas
MERGE dw.FactVentas AS tgt
USING (
  SELECT
    p.id_pedido AS IdPedido,
    d.id_detalle_pedido AS NumeroLinea,
    dp.ClaveProducto,
    dc.ClaveCliente,
    de.ClaveEmpleado,
    dof.ClaveOficina,
    COALESCE(dfP.ClaveFecha,19000101) AS ClaveFechaPedido,
    COALESCE(dfE.ClaveFecha,19000101) AS ClaveFechaEsperada,
    COALESCE(dfD.ClaveFecha,19000101) AS ClaveFechaEntrega,
    d.cantidad AS Cantidad,
    d.precio_unidad AS PrecioUnitario,
    p.estado AS EstadoPedido
  FROM jardineria_stg.stg.detalle_pedido d
  JOIN jardineria_stg.stg.pedido p   ON p.id_pedido=d.id_pedido
  JOIN dw.DimProducto  dp ON dp.IdProductoNK = d.id_producto
  JOIN dw.DimCliente   dc ON dc.IdClienteNK  = p.id_cliente
  LEFT JOIN jardineria_stg.stg.cliente c ON c.id_cliente=p.id_cliente
  LEFT JOIN dw.DimEmpleado de ON de.IdEmpleadoNK = c.id_empleado_rep_ventas
  LEFT JOIN jardineria_stg.stg.empleado se ON se.id_empleado=c.id_empleado_rep_ventas
  LEFT JOIN dw.DimOficina dof ON dof.IdOficinaNK = se.id_oficina
  LEFT JOIN dw.DimFecha dfP ON dfP.Fecha = p.fecha_pedido
  LEFT JOIN dw.DimFecha dfE ON dfE.Fecha = p.fecha_esperada
  LEFT JOIN dw.DimFecha dfD ON dfD.Fecha = p.fecha_entrega
  WHERE d.cantidad>0 AND d.precio_unidad>=0
) src
ON  tgt.IdPedido   = src.IdPedido
AND tgt.NumeroLinea = src.NumeroLinea
WHEN MATCHED THEN UPDATE SET
  ClaveProducto      = src.ClaveProducto,
  ClaveCliente       = src.ClaveCliente,
  ClaveEmpleado      = src.ClaveEmpleado,
  ClaveOficina       = src.ClaveOficina,
  ClaveFechaPedido   = src.ClaveFechaPedido,
  ClaveFechaEsperada = src.ClaveFechaEsperada,
  ClaveFechaEntrega  = src.ClaveFechaEntrega,
  Cantidad           = src.Cantidad,
  PrecioUnitario     = src.PrecioUnitario,
  EstadoPedido       = src.EstadoPedido
WHEN NOT MATCHED THEN
  INSERT(ClaveProducto,ClaveCliente,ClaveEmpleado,ClaveOficina,
         ClaveFechaPedido,ClaveFechaEsperada,ClaveFechaEntrega,
         IdPedido,NumeroLinea,Cantidad,PrecioUnitario,EstadoPedido)
  VALUES(src.ClaveProducto,src.ClaveCliente,src.ClaveEmpleado,src.ClaveOficina,
         src.ClaveFechaPedido,src.ClaveFechaEsperada,src.ClaveFechaEntrega,
         src.IdPedido,src.NumeroLinea,src.Cantidad,src.PrecioUnitario,src.EstadoPedido);

-- UNIQUE
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_FactVentas_PedidoLinea')
  ALTER TABLE dw.FactVentas ADD CONSTRAINT UQ_FactVentas_PedidoLinea UNIQUE (IdPedido, NumeroLinea);
