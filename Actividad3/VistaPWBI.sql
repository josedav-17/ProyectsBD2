
IF OBJECT_ID('dw.v_Ventas') IS NOT NULL DROP VIEW dw.v_Ventas;
GO
CREATE VIEW dw.v_Ventas AS
SELECT
  fv.IdPedido, fv.NumeroLinea, fv.Cantidad, fv.PrecioUnitario, fv.ImporteLinea,
  fv.EstadoPedido,
  df.Fecha AS FechaPedido,
  dp.ClaveProducto, dp.IdProductoNK, dp.NombreProducto, dp.CodigoProducto, dp.Proveedor, dp.Dimensiones,
  dc.ClaveCliente, dc.IdClienteNK, dc.NombreCliente, dc.Pais, dc.Ciudad,
  de.ClaveEmpleado, de.IdEmpleadoNK, de.Nombre AS NombreEmpleado,
  dof.ClaveOficina, dof.IdOficinaNK, dof.Ciudad AS CiudadOficina
FROM dw.FactVentas fv
JOIN dw.DimFecha    df  ON df.ClaveFecha    = fv.ClaveFechaPedido
JOIN dw.DimProducto dp  ON dp.ClaveProducto = fv.ClaveProducto
JOIN dw.DimCliente  dc  ON dc.ClaveCliente  = fv.ClaveCliente
LEFT JOIN dw.DimEmpleado de ON de.ClaveEmpleado = fv.ClaveEmpleado
LEFT JOIN dw.DimOficina  dof ON dof.ClaveOficina = fv.ClaveOficina;
GO
