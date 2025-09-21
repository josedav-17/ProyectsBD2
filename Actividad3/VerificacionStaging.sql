USE jardineria_stg;
	-- Valores inválidos
	SELECT 
		TOP 50 * 
	FROM stg.detalle_pedido WITH (NOLOCK) 
	WHERE cantidad<=0 OR precio_unidad<0;

	-- Conteos por tabla
	SELECT 
		'oficina'AS t,
		COUNT(*) AS n 
	FROM stg.oficina WITH (NOLOCK) 
	UNION ALL
	SELECT 
		'empleado', 
		COUNT(*) 
	FROM stg.empleado WITH (NOLOCK) 
	UNION ALL
	SELECT 
		'categoria_producto',
		COUNT(*) 
	FROM stg.categoria_producto  WITH (NOLOCK)
	UNION ALL
	SELECT 
		'producto', 
		COUNT(*)
	FROM stg.producto WITH (NOLOCK)
	UNION ALL
	SELECT 
		'cliente', 
		COUNT(*) 
	FROM stg.cliente WITH (NOLOCK)
	UNION ALL
	SELECT 
		'pedido', 
		COUNT(*) 
	FROM stg.pedido WITH (NOLOCK)
	UNION ALL
	SELECT 
		'detalle_pedido',
		COUNT(*) 
	FROM stg.detalle_pedido WITH (NOLOCK)
	UNION ALL
	SELECT 
		'pago', 
		COUNT(*) 
	FROM stg.pago;
