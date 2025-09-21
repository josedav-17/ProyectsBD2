
-- NMERGE PARA LAS DEMAS DIMENSIONES
MERGE dw.DimCliente AS T
USING (
  SELECT DISTINCT id_cliente AS IdClienteNK, nombre_cliente AS NombreCliente,
    nombre_contacto, apellido_contacto, telefono, ciudad, region, pais,
    codigo_postal, limite_credito
  FROM jardineria_stg.stg.cliente
) S
ON T.IdClienteNK = S.IdClienteNK
WHEN MATCHED THEN UPDATE SET
  NombreCliente=S.NombreCliente, NombreContacto=S.nombre_contacto, ApellidoContacto=S.apellido_contacto,
  Telefono=S.telefono, Ciudad=S.ciudad, Region=S.region, Pais=S.pais, CodigoPostal=S.codigo_postal,
  LimiteCredito=S.limite_credito
WHEN NOT MATCHED THEN
  INSERT(IdClienteNK,NombreCliente,NombreContacto,ApellidoContacto,Telefono,Ciudad,Region,Pais,CodigoPostal,LimiteCredito)
  VALUES(S.IdClienteNK,S.NombreCliente,S.nombre_contacto,S.apellido_contacto,S.telefono,S.ciudad,S.region,S.pais,S.codigo_postal,S.limite_credito);

MERGE dw.DimCategoria AS T
USING (
  SELECT DISTINCT id_categoria AS IdCategoriaNK, desc_categoria AS NombreCategoria
  FROM jardineria_stg.stg.categoria_producto
) S
ON T.IdCategoriaNK=S.IdCategoriaNK
WHEN MATCHED THEN UPDATE SET NombreCategoria=S.NombreCategoria
WHEN NOT MATCHED THEN INSERT(IdCategoriaNK,NombreCategoria) VALUES(S.IdCategoriaNK,S.NombreCategoria);

MERGE dw.DimProducto AS T
USING (
  SELECT DISTINCT
    p.id_producto AS IdProductoNK, p.codigo_producto, p.nombre AS NombreProducto,
    p.categoria AS IdCategoriaNK, p.proveedor, p.dimensiones
  FROM jardineria_stg.stg.producto p
) S
ON T.IdProductoNK=S.IdProductoNK
WHEN MATCHED THEN UPDATE SET
  CodigoProducto=S.codigo_producto, NombreProducto=S.NombreProducto,
  ClaveCategoria=(SELECT ClaveCategoria FROM dw.DimCategoria c WHERE c.IdCategoriaNK=S.IdCategoriaNK),
  Proveedor=S.proveedor, Dimensiones=S.dimensiones
WHEN NOT MATCHED THEN
  INSERT(IdProductoNK,CodigoProducto,NombreProducto,ClaveCategoria,Proveedor,Dimensiones)
  VALUES(
    S.IdProductoNK, S.codigo_producto, S.NombreProducto,
    (SELECT ClaveCategoria FROM dw.DimCategoria c WHERE c.IdCategoriaNK=S.IdCategoriaNK),
    S.proveedor, S.dimensiones
  );

MERGE dw.DimOficina AS T
USING (
  SELECT DISTINCT id_oficina AS IdOficinaNK, descripcion, ciudad, pais, region, codigo_postal
  FROM jardineria_stg.stg.oficina
) S
ON T.IdOficinaNK=S.IdOficinaNK
WHEN MATCHED THEN UPDATE SET
  Descripcion=S.descripcion, Ciudad=S.ciudad, Pais=S.pais, Region=S.region, CodigoPostal=S.codigo_postal
WHEN NOT MATCHED THEN
  INSERT(IdOficinaNK,Descripcion,Ciudad,Pais,Region,CodigoPostal)
  VALUES(S.IdOficinaNK,S.descripcion,S.ciudad,S.pais,S.region,S.codigo_postal);

MERGE dw.DimEmpleado AS T
USING (
  SELECT DISTINCT
    e.id_empleado AS IdEmpleadoNK, e.nombre, e.apellido1, e.apellido2, e.email, e.puesto,
    e.id_oficina  AS IdOficinaNK
  FROM jardineria_stg.stg.empleado e
) S
ON T.IdEmpleadoNK=S.IdEmpleadoNK
WHEN MATCHED THEN UPDATE SET
  Nombre=S.nombre, Apellido1=S.apellido1, Apellido2=S.apellido2, Email=S.email, Puesto=S.puesto, IdOficinaNK=S.IdOficinaNK
WHEN NOT MATCHED THEN
  INSERT(IdEmpleadoNK,Nombre,Apellido1,Apellido2,Email,Puesto,IdOficinaNK)
  VALUES(S.IdEmpleadoNK,S.nombre,S.apellido1,S.apellido2,S.email,S.puesto,S.IdOficinaNK);
