-- CARGA DE INFORMACIÓN A LA DB DE STAGING
USE jardineria_stg;
GO

DECLARE @batch_id BIGINT;
INSERT INTO stg.lotes(source_system,status,notes)
VALUES('JARDINERIA','RUNNING','Extracción desde jardineria.dbo → jardineria_stg.stg');
SET @batch_id = SCOPE_IDENTITY();

-- Limpia staging (POR SI ES UNA SEGUNDA O MAS EJECUCIÓNES)
TRUNCATE TABLE stg.oficina;
TRUNCATE TABLE stg.empleado;
TRUNCATE TABLE stg.categoria_producto;
TRUNCATE TABLE stg.producto;
TRUNCATE TABLE stg.cliente;
TRUNCATE TABLE stg.pedido;
TRUNCATE TABLE stg.detalle_pedido;
TRUNCATE TABLE stg.pago;

-- OFICINA
INSERT INTO stg.oficina(
    id_oficina,
    descripcion,
    ciudad,
    pais,
    region,
    codigo_postal,
    telefono,
    linea_direccion1,
    linea_direccion2,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    o.id_oficina,
    LTRIM(RTRIM(o.descripcion)),
    LTRIM(RTRIM(o.ciudad)),
    LTRIM(RTRIM(o.pais)),
    NULLIF(LTRIM(RTRIM(o.region)),''),
    NULLIF(LTRIM(RTRIM(o.codigo_postal)),''),
    LTRIM(RTRIM(o.telefono)),
    LTRIM(RTRIM(o.linea_direccion1)),
    NULLIF(LTRIM(RTRIM(o.linea_direccion2)),''),
    @batch_id,
    SYSDATETIME(),
    'jardineria.oficina'
FROM jardineria.dbo.oficina AS o;

-- EMPLEADO
INSERT INTO stg.empleado(
    id_empleado,
    nombre,
    apellido1,
    apellido2,
    extension,
    email,
    id_oficina,
    id_jefe,
    puesto,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    e.id_empleado,
    LTRIM(RTRIM(e.nombre)),
    LTRIM(RTRIM(e.apellido1)),
    NULLIF(LTRIM(RTRIM(e.apellido2)),''),
    NULLIF(LTRIM(RTRIM(e.extension)),''),
    NULLIF(LTRIM(RTRIM(e.email)),''),
    e.id_oficina,
    e.id_jefe,
    NULLIF(LTRIM(RTRIM(e.puesto)),''),
    @batch_id,
    SYSDATETIME(),
    'jardineria.empleado'
FROM jardineria.dbo.empleado AS e;

-- CATEGORIA_PRODUCTO
INSERT INTO stg.categoria_producto(
    id_categoria,
    desc_categoria,
    descripcion_texto,
    descripcion_html,
    imagen,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    c.id_categoria,
    LTRIM(RTRIM(c.desc_categoria)),
    c.descripcion_texto,
    c.descripcion_html,
    c.imagen,
    @batch_id,
    SYSDATETIME(),
    'jardineria.categoria_producto'
FROM jardineria.dbo.categoria_producto AS c;

-- PRODUCTO
INSERT INTO stg.producto(
    id_producto,
    codigo_producto,
    nombre,
    categoria,
    dimensiones,
    proveedor,
    descripcion,
    cantidad_en_stock,
    precio_venta,
    precio_proveedor,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    p.id_producto,
    p.CodigoProducto,
    LTRIM(RTRIM(p.nombre)),
    p.categoria,
    NULLIF(LTRIM(RTRIM(p.dimensiones)),''),
    LTRIM(RTRIM(p.proveedor)),
    p.descripcion,
    p.cantidad_en_stock,
    p.precio_venta,
    p.precio_proveedor,
    @batch_id,
    SYSDATETIME(),
    'jardineria.producto'
FROM jardineria.dbo.producto AS p;

-- CLIENTE
INSERT INTO stg.cliente(
    id_cliente,
    nombre_cliente,
    nombre_contacto,
    apellido_contacto,
    telefono,
    fax,
    linea_direccion1,
    linea_direccion2,
    ciudad,
    region,
    pais,
    codigo_postal,
    id_empleado_rep_ventas,
    limite_credito,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    c.id_cliente,
    LTRIM(RTRIM(c.nombre_cliente)),
    NULLIF(LTRIM(RTRIM(c.nombre_contacto)),''),
    NULLIF(LTRIM(RTRIM(c.apellido_contacto)),''),
    LTRIM(RTRIM(c.telefono)),
    NULLIF(LTRIM(RTRIM(c.fax)),''),
    LTRIM(RTRIM(c.linea_direccion1)),
    NULLIF(LTRIM(RTRIM(c.linea_direccion2)),''),
    LTRIM(RTRIM(c.ciudad)),
    NULLIF(LTRIM(RTRIM(c.region)),''),
    LTRIM(RTRIM(c.pais)),
    NULLIF(LTRIM(RTRIM(c.codigo_postal)),''),
    c.id_empleado_rep_ventas,
    c.limite_credito,
    @batch_id,
    SYSDATETIME(),
    'jardineria.cliente'
FROM jardineria.dbo.cliente AS c;

-- PEDIDO
INSERT INTO stg.pedido(
    id_pedido,
    fecha_pedido,
    fecha_esperada,
    fecha_entrega,
    estado,
    comentarios,
    id_cliente,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    p.id_pedido,
    p.fecha_pedido,
    p.fecha_esperada,
    p.fecha_entrega,
    LTRIM(RTRIM(p.estado)),
    p.comentarios,
    p.id_cliente,
    @batch_id,
    SYSDATETIME(),
    'jardineria.pedido'
FROM jardineria.dbo.pedido AS p;

-- DETALLE_PEDIDO
INSERT INTO stg.detalle_pedido(
    id_detalle_pedido,
    id_pedido,
    id_producto,
    cantidad,
    precio_unidad,
    numero_linea,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    d.id_detalle_pedido,
    d.id_pedido,
    d.id_producto,
    d.cantidad,
    d.precio_unidad,
    d.numero_linea,
    @batch_id,
    SYSDATETIME(),
    'jardineria.detalle_pedido'
FROM jardineria.dbo.detalle_pedido AS d;

-- PAGO
INSERT INTO stg.pago(
    id_pago,
    id_cliente,
    forma_pago,
    id_transaccion,
    fecha_pago,
    total,
    _batch_id,
    _extract_ts,
    _source
)
SELECT
    pg.id_pago,
    pg.id_cliente,
    NULLIF(LTRIM(RTRIM(pg.forma_pago)),''),
    pg.id_transaccion,
    pg.fecha_pago,
    pg.total,
    @batch_id,
    SYSDATETIME(),
    'jardineria.pago'
FROM jardineria.dbo.pago AS pg;

-- ACTUALIZA Y SE CIERRA EL LOTE
UPDATE stg.lotes
SET status='SUCCESS', ended_at=SYSDATETIME(), rows_loaded =
    (SELECT
        (SELECT COUNT(*) FROM stg.oficina) +
        (SELECT COUNT(*) FROM stg.empleado) +
        (SELECT COUNT(*) FROM stg.categoria_producto) +
        (SELECT COUNT(*) FROM stg.producto) +
        (SELECT COUNT(*) FROM stg.cliente) +
        (SELECT COUNT(*) FROM stg.pedido) +
        (SELECT COUNT(*) FROM stg.detalle_pedido) +
        (SELECT COUNT(*) FROM stg.pago)
    )
WHERE batch_id=@batch_id;