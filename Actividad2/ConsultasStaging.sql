-- CONSULTAS PARA VERIFICAR LA INTEGRIDAD DE DATOS ENTRE DB ORIGINAL Y STAGING
-- AGREGO WITH (NOLOCK) PARA QUE LEA LOS DATOS SIN RESPETAR BLOQUEOS DE LECTURA
	SELECT 'oficina' entidad, 
		(SELECT COUNT(*) FROM jardineria.dbo.oficina WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.oficina WITH (NOLOCK)) AS destino;

	SELECT 'empleado', 
		(SELECT COUNT(*) FROM jardineria.dbo.empleado WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.empleado WITH (NOLOCK)) AS destino;


	SELECT 'categoria_producto', 
		(SELECT COUNT(*) FROM jardineria.dbo.categoria_producto WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.categoria_producto WITH (NOLOCK)) AS destino;


	SELECT 'producto', 
		(SELECT COUNT(*) FROM jardineria.dbo.producto WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.producto WITH (NOLOCK)) AS destino;


	SELECT 'cliente', 
		(SELECT COUNT(*) FROM jardineria.dbo.cliente WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.cliente WITH (NOLOCK)) AS destino;


	SELECT 'pedido', 
		(SELECT COUNT(*) FROM jardineria.dbo.pedido WITH (NOLOCK))AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.pedido WITH (NOLOCK)) AS destino;

	SELECT 'detalle_pedido', 
		(SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.detalle_pedido WITH (NOLOCK)) AS destino;


	SELECT 'pago', 
		(SELECT COUNT(*) FROM jardineria.dbo.pago WITH (NOLOCK)) AS origen,
		(SELECT COUNT(*) FROM jardineria_stg.stg.pago WITH (NOLOCK)) AS destino;

-- VALIDAMOS POR RANGO DE FECHA O PEDIDO NULO
	SELECT 
		MIN(fecha_pedido) AS min_fp,
		MAX(fecha_pedido) AS max_fp 
	FROM jardineria_stg.stg.pedido WITH (NOLOCK);

	SELECT 
		COUNT(*) AS null_estado 
	FROM jardineria_stg.stg.pedido WITH (NOLOCK)
	WHERE estado IS NULL;

	-- VALIDAMOS ORFANDADES
	SELECT 
		p.id_pedido
	FROM jardineria_stg.stg.pedido AS p WITH (NOLOCK)
	LEFT JOIN jardineria_stg.stg.cliente AS c WITH (NOLOCK) 
		ON c.id_cliente = p.id_cliente
	WHERE c.id_cliente IS NULL;

	SELECT 
		d.id_detalle_pedido
	FROM jardineria_stg.stg.detalle_pedido AS d WITH (NOLOCK)
	LEFT JOIN jardineria_stg.stg.pedido AS p  WITH (NOLOCK)
		ON p.id_pedido = d.id_pedido
	LEFT JOIN jardineria_stg.stg.producto AS pr WITH (NOLOCK)
		ON pr.id_producto = d.id_producto
	WHERE p.id_pedido IS NULL OR pr.id_producto IS NULL;

	-- VALIDAMOS DUPLICADOS POR CLAVE NATUIRAL (POR SI EXISTEN)
	SELECT 
		id_cliente, COUNT(*) AS c 
	FROM jardineria_stg.stg.cliente WITH (NOLOCK)
	GROUP BY id_cliente HAVING COUNT(*)>1;

	SELECT 
		id_producto, COUNT(*) AS c 
	FROM jardineria_stg.stg.producto WITH (NOLOCK)
	GROUP BY id_producto HAVING COUNT(*)>1;
