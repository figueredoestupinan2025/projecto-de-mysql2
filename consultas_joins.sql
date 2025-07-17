-- =====================================================
-- PROYECTO: PLATAFORMA DE COMERCIALIZACIÓN DIGITAL MULTINIVEL
-- ARCHIVO: Consultas JOIN (20 Historias de Usuario)
-- DESCRIPCIÓN: Consultas SQL utilizando diferentes tipos de JOINs
-- =====================================================

USE plataforma_comercial;

-- =====================================================
-- 1. VER PRODUCTOS CON LA EMPRESA QUE LOS VENDE (INNER JOIN)
-- Historia: Como analista, quiero consultar todas las empresas junto con los productos que ofrecen, mostrando el nombre del producto y el precio.
-- =====================================================

SELECT 
    c.name AS nombre_empresa,
    p.name AS nombre_producto,
    cp.price AS precio_producto,
    cat.name AS categoria_producto
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN products p ON cp.product_id = p.id
INNER JOIN categories cat ON p.category_id = cat.id
ORDER BY c.name, p.name;

-- =====================================================
-- 2. MOSTRAR PRODUCTOS FAVORITOS CON SU EMPRESA Y CATEGORÍA (Múltiples INNER JOINs)
-- Historia: Como cliente, deseo ver mis productos favoritos junto con la categoría y el nombre de la empresa que los ofrece.
-- =====================================================

SELECT 
    cu.first_name AS nombre_cliente,
    p.name AS producto_favorito,
    cat.name AS categoria,
    comp.name AS empresa_vendedora,
    df.added_date AS fecha_agregado
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN products p ON df.product_id = p.id
INNER JOIN categories cat ON p.category_id = cat.id
LEFT JOIN companyproducts cp ON p.id = cp.product_id -- Usamos LEFT JOIN aquí para asegurar que el producto tenga una empresa asociada
LEFT JOIN companies comp ON cp.company_id = comp.id
WHERE cu.id = 1 -- Ejemplo: para un cliente específico
ORDER BY cu.first_name, p.name;

-- =====================================================
-- 3. VER EMPRESAS AUNQUE NO TENGAN PRODUCTOS (LEFT JOIN)
-- Historia: Como supervisor, quiero ver todas las empresas aunque no tengan productos asociados.
-- =====================================================

SELECT 
    c.name AS nombre_empresa,
    c.status AS estado_empresa,
    COUNT(cp.product_id) AS total_productos_ofrecidos
FROM companies c
LEFT JOIN companyproducts cp ON c.id = cp.company_id
GROUP BY c.id, c.name, c.status
ORDER BY c.name;

-- =====================================================
-- 4. VER PRODUCTOS QUE FUERON CALIFICADOS (O NO) (RIGHT JOIN)
-- Historia: Como técnico, deseo obtener todas las calificaciones de productos incluyendo aquellos productos que aún no han sido calificados.
-- =====================================================

SELECT 
    p.name AS nombre_producto,
    cat.name AS categoria,
    r.rating AS calificacion,
    r.comment AS comentario_calificacion,
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente_calificador
FROM rates r
RIGHT JOIN products p ON r.product_id = p.id
LEFT JOIN categories cat ON p.category_id = cat.id
LEFT JOIN customers cu ON r.customer_id = cu.id
ORDER BY p.name, r.created_at DESC;

-- =====================================================
-- 5. VER PRODUCTOS CON PROMEDIO DE CALIFICACIÓN Y EMPRESA (INNER JOIN + Agregación)
-- Historia: Como gestor, quiero ver productos con su promedio de calificación y nombre de la empresa.
-- =====================================================

SELECT 
    p.name AS nombre_producto,
    c.name AS empresa_vendedora,
    ROUND(AVG(r.rating), 2) AS promedio_calificacion,
    COUNT(r.id) AS total_calificaciones
FROM products p
INNER JOIN companyproducts cp ON p.id = cp.product_id
INNER JOIN companies c ON cp.company_id = c.id
INNER JOIN rates r ON p.id = r.product_id AND c.id = r.company_id -- Asegurar que la calificación sea para el producto de esa empresa
GROUP BY p.id, p.name, c.name
ORDER BY promedio_calificacion DESC, total_calificaciones DESC;

-- =====================================================
-- 6. VER CLIENTES Y SUS CALIFICACIONES (SI LAS TIENEN) (LEFT JOIN)
-- Historia: Como operador, deseo obtener todos los clientes y sus calificaciones si existen.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    cu.email,
    p.name AS producto_calificado,
    r.rating AS calificacion,
    r.created_at AS fecha_calificacion
FROM customers cu
LEFT JOIN rates r ON cu.id = r.customer_id
LEFT JOIN products p ON r.product_id = p.id
ORDER BY cu.first_name, r.created_at DESC;

-- =====================================================
-- 7. VER FAVORITOS CON LA ÚLTIMA CALIFICACIÓN DEL CLIENTE (INNER JOIN + Subconsulta/Agregación)
-- Historia: Como cliente, quiero consultar todos mis favoritos junto con la última calificación que he dado.
-- =====================================================

SELECT 
    cu.first_name AS nombre_cliente,
    p.name AS producto_favorito,
    r.rating AS ultima_calificacion,
    r.created_at AS fecha_ultima_calificacion
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN products p ON df.product_id = p.id
LEFT JOIN rates r ON p.id = r.product_id AND cu.id = r.customer_id
WHERE r.created_at = (
    SELECT MAX(r2.created_at)
    FROM rates r2
    WHERE r2.product_id = p.id AND r2.customer_id = cu.id
) OR r.id IS NULL -- Incluir favoritos sin calificación
ORDER BY cu.first_name, p.name;

-- =====================================================
-- 8. VER BENEFICIOS INCLUIDOS EN CADA PLAN DE MEMBRESÍA (INNER JOINs)
-- Historia: Como administrador, quiero unir membershipbenefits, benefits y memberships.
-- =====================================================

SELECT 
    m.name AS nombre_membresia,
    b.name AS nombre_beneficio,
    b.description AS descripcion_beneficio,
    b.type AS tipo_beneficio
FROM memberships m
INNER JOIN membershipbenefits mb ON m.id = mb.membership_id
INNER JOIN benefits b ON mb.benefit_id = b.id
ORDER BY m.name, b.name;

-- =====================================================
-- 9. VER CLIENTES CON MEMBRESÍA ACTIVA Y SUS BENEFICIOS (Múltiples INNER JOINs)
-- Historia: Como gerente, deseo ver todos los clientes con membresía activa y sus beneficios actuales.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    cu.email,
    m.name AS tipo_membresia,
    mp.start_date AS inicio_membresia,
    mp.end_date AS fin_membresia,
    b.name AS nombre_beneficio,
    b.description AS descripcion_beneficio
FROM customers cu
INNER JOIN membershipperiods mp ON cu.id = mp.customer_id
INNER JOIN memberships m ON mp.membership_id = m.id
INNER JOIN membershipbenefits mb ON m.id = mb.membership_id
INNER JOIN benefits b ON mb.benefit_id = b.id
WHERE mp.status = 'active' AND mp.end_date >= CURRENT_DATE
ORDER BY cu.first_name, m.name, b.name;

-- =====================================================
-- 10. VER CIUDADES CON CANTIDAD DE EMPRESAS (LEFT JOIN + Agregación)
-- Historia: Como operador, quiero obtener todas las ciudades junto con la cantidad de empresas registradas.
-- =====================================================

SELECT 
    ci.name AS nombre_ciudad,
    sr.name AS nombre_departamento,
    co.name AS nombre_pais,
    COUNT(c.id) AS total_empresas_en_ciudad
FROM citiesormunicipalities ci
LEFT JOIN companies c ON ci.id = c.city_id
LEFT JOIN stateregions sr ON ci.stateregion_id = sr.id
LEFT JOIN countries co ON sr.country_id = co.id
GROUP BY ci.id, ci.name, sr.name, co.name
ORDER BY total_empresas_en_ciudad DESC, ci.name;

-- =====================================================
-- 11. VER ENCUESTAS CON CALIFICACIONES (INNER JOIN)
-- Historia: Como analista, deseo unir polls y rates.
-- =====================================================

SELECT 
    po.title AS titulo_encuesta,
    po.type AS tipo_encuesta,
    r.rating AS calificacion,
    r.comment AS comentario,
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente_calificador,
    p.name AS producto_calificado
FROM polls po
INNER JOIN rates r ON po.id = r.poll_id
INNER JOIN customers cu ON r.customer_id = cu.id
LEFT JOIN products p ON r.product_id = p.id
ORDER BY po.title, r.created_at DESC;

-- =====================================================
-- 12. VER PRODUCTOS EVALUADOS CON DATOS DEL CLIENTE (INNER JOINs)
-- Historia: Como técnico, quiero consultar todos los productos evaluados con su fecha y cliente.
-- =====================================================

SELECT 
    p.name AS nombre_producto,
    cat.name AS categoria,
    r.rating AS calificacion,
    r.comment AS comentario,
    r.created_at AS fecha_calificacion,
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    cu.email AS email_cliente
FROM products p
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN customers cu ON r.customer_id = cu.id
INNER JOIN categories cat ON p.category_id = cat.id
ORDER BY p.name, r.created_at DESC;

-- =====================================================
-- 13. VER PRODUCTOS CON AUDIENCIA DE LA EMPRESA (INNER JOINs)
-- Historia: Como supervisor, deseo obtener todos los productos con la audiencia objetivo de la empresa.
-- =====================================================

SELECT 
    p.name AS nombre_producto,
    cat.name AS categoria,
    c.name AS nombre_empresa,
    a.name AS audiencia_objetivo_empresa,
    a.description AS descripcion_audiencia
FROM products p
INNER JOIN companyproducts cp ON p.id = cp.product_id
INNER JOIN companies c ON cp.company_id = c.id
INNER JOIN audiences a ON c.audience_id = a.id
INNER JOIN categories cat ON p.category_id = cat.id
ORDER BY p.name, c.name;

-- =====================================================
-- 14. VER CLIENTES CON SUS PRODUCTOS FAVORITOS (INNER JOINs)
-- Historia: Como auditor, quiero unir customers y favorites.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    cu.email,
    f.name AS nombre_lista_favoritos,
    p.name AS producto_favorito,
    df.added_date AS fecha_agregado_favorito
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN products p ON df.product_id = p.id
ORDER BY cu.first_name, f.name, p.name;

-- =====================================================
-- 15. VER PLANES, PERIODOS, PRECIOS Y BENEFICIOS (Múltiples INNER JOINs)
-- Historia: Como gestor, deseo obtener la relación de planes de membresía, periodos, precios y beneficios.
-- =====================================================

SELECT 
    m.name AS nombre_membresia,
    m.description AS descripcion_membresia,
    mp.start_date AS fecha_inicio_periodo,
    mp.end_date AS fecha_fin_periodo,
    mp.price AS precio_periodo,
    mp.status AS estado_periodo,
    b.name AS nombre_beneficio,
    b.description AS descripcion_beneficio,
    b.type AS tipo_beneficio
FROM memberships m
INNER JOIN membershipperiods mp ON m.id = mp.membership_id
LEFT JOIN membershipbenefits mb ON m.id = mb.membership_id
LEFT JOIN benefits b ON mb.benefit_id = b.id
ORDER BY m.name, mp.start_date, b.name;

-- =====================================================
-- 16. VER COMBINACIONES EMPRESA-PRODUCTO-CLIENTE CALIFICADOS (INNER JOINs)
-- Historia: Como desarrollador, quiero consultar todas las combinaciones empresa-producto-cliente que hayan sido calificadas.
-- =====================================================

SELECT 
    c.name AS nombre_empresa,
    p.name AS nombre_producto,
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    r.rating AS calificacion,
    r.comment AS comentario,
    r.created_at AS fecha_calificacion
FROM companies c
INNER JOIN rates r ON c.id = r.company_id
INNER JOIN products p ON r.product_id = p.id
INNER JOIN customers cu ON r.customer_id = cu.id
ORDER BY c.name, p.name, cu.first_name;

-- =====================================================
-- 17. COMPARAR FAVORITOS CON PRODUCTOS CALIFICADOS (INNER JOIN)
-- Historia: Como cliente, quiero ver productos que he calificado y también tengo en favoritos.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    p.name AS producto,
    r.rating AS mi_calificacion,
    df.added_date AS fecha_agregado_favorito,
    r.created_at AS fecha_calificacion
FROM customers cu
INNER JOIN details_favorites df ON cu.id = (SELECT customer_id FROM favorites WHERE id = df.favorite_id)
INNER JOIN rates r ON cu.id = r.customer_id AND df.product_id = r.product_id
INNER JOIN products p ON df.product_id = p.id
WHERE cu.id = 1 -- Ejemplo: para un cliente específico
ORDER BY p.name;

-- =====================================================
-- 18. VER PRODUCTOS ORDENADOS POR CATEGORÍA (INNER JOIN)
-- Historia: Como operador, quiero unir categories y products.
-- =====================================================

SELECT 
    cat.name AS nombre_categoria,
    p.name AS nombre_producto,
    p.description AS descripcion_producto,
    p.status AS estado_producto
FROM categories cat
INNER JOIN products p ON cat.id = p.category_id
ORDER BY cat.name, p.name;

-- =====================================================
-- 19. VER BENEFICIOS POR AUDIENCIA, INCLUSO VACÍOS (LEFT JOIN)
-- Historia: Como especialista, quiero listar beneficios por audiencia, incluso si no tienen asignados.
-- =====================================================

SELECT 
    a.name AS nombre_audiencia,
    b.name AS nombre_beneficio,
    b.description AS descripcion_beneficio,
    b.type AS tipo_beneficio
FROM audiences a
LEFT JOIN audiencebenefits ab ON a.id = ab.audience_id
LEFT JOIN benefits b ON ab.benefit_id = b.id
ORDER BY a.name, b.name;

-- =====================================================
-- 20. VER DATOS CRUZADOS ENTRE CALIFICACIONES, ENCUESTAS, PRODUCTOS Y CLIENTES (Múltiples INNER JOINs)
-- Historia: Como auditor, deseo una consulta que relacione rates, polls, products y customers.
-- =====================================================

SELECT 
    r.id AS id_calificacion,
    r.rating AS calificacion,
    r.comment AS comentario_calificacion,
    r.created_at AS fecha_calificacion,
    po.title AS titulo_encuesta,
    po.type AS tipo_encuesta,
    p.name AS nombre_producto,
    cat.name AS categoria_producto,
    CONCAT(cu.first_name, ' ', cu.last_name) AS nombre_cliente,
    cu.email AS email_cliente
FROM rates r
INNER JOIN products p ON r.product_id = p.id
INNER JOIN customers cu ON r.customer_id = cu.id
LEFT JOIN polls po ON r.poll_id = po.id -- LEFT JOIN porque poll_id puede ser NULL
LEFT JOIN categories cat ON p.category_id = cat.id
ORDER BY r.created_at DESC;

-- =====================================================
-- FIN DE LAS CONSULTAS JOIN
-- =====================================================
