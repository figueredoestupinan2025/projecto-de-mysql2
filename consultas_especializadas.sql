-- =====================================================
-- PROYECTO: PLATAFORMA DE COMERCIALIZACIÓN DIGITAL MULTINIVEL
-- ARCHIVO: Consultas Especializadas (20 Historias de Usuario) 
-- DESCRIPCIÓN: Consultas SQL para obtener información específica
-- =====================================================

USE plataforma_comercial;

-- =====================================================
-- 1. PRODUCTOS CON PRECIO MÁS BAJO POR CIUDAD 
-- Historia: Como cliente, quiero encontrar los productos con el precio más bajo en mi ciudad.
-- =====================================================

SELECT 
    p.name AS producto,
    c.name AS empresa,
    ci.name AS ciudad,
    cp.price AS precio_mas_bajo,
    cat.name AS categoria
FROM products p
INNER JOIN companyproducts cp ON p.id = cp.product_id
INNER JOIN companies c ON cp.company_id = c.id
INNER JOIN citiesormunicipalities ci ON c.city_id = ci.id
INNER JOIN categories cat ON p.category_id = cat.id
WHERE (p.id, ci.id, cp.price) IN (
    SELECT 
        p2.id,
        ci2.id,
        MIN(cp2.price)
    FROM products p2
    INNER JOIN companyproducts cp2 ON p2.id = cp2.product_id
    INNER JOIN companies c2 ON cp2.company_id = c2.id
    INNER JOIN citiesormunicipalities ci2 ON c2.city_id = ci2.id
    GROUP BY p2.id, ci2.id
)
ORDER BY ci.name, p.name;

-- =====================================================
-- 2. TOP 5 CLIENTES MÁS ACTIVOS
-- Historia: Como gerente, quiero identificar a los 5 clientes que más calificaciones han realizado en los últimos 6 meses.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    ci.name AS ciudad,
    COUNT(r.id) AS total_calificaciones,
    ROUND(AVG(r.rating), 2) AS promedio_calificaciones,
    MAX(r.created_at) AS ultima_calificacion
FROM customers cu
INNER JOIN rates r ON cu.id = r.customer_id
LEFT JOIN citiesormunicipalities ci ON cu.city_id = ci.id
WHERE r.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
GROUP BY cu.id, cu.first_name, cu.last_name, cu.email, ci.name
ORDER BY total_calificaciones DESC, promedio_calificaciones DESC
LIMIT 5;

-- =====================================================
-- 3. PRODUCTOS MÁS CALIFICADOS POR CLIENTES VIP
-- Historia: Como analista, quiero ver los productos mejor calificados por clientes con membresía VIP.
-- =====================================================

SELECT 
    p.name AS producto,
    cat.name AS categoria,
    ROUND(AVG(r.rating), 2) AS promedio_calificacion,
    COUNT(r.id) AS total_calificaciones
FROM products p
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN customers cu ON r.customer_id = cu.id
INNER JOIN membershipperiods mp ON cu.id = mp.customer_id
INNER JOIN memberships m ON mp.membership_id = m.id
INNER JOIN categories cat ON p.category_id = cat.id
WHERE m.name = 'VIP'
GROUP BY p.id, p.name, cat.name
ORDER BY promedio_calificacion DESC, total_calificaciones DESC;

-- =====================================================
-- 4. EMPRESAS CON MAYOR NÚMERO DE PRODUCTOS EN FAVORITOS 
-- Historia: Como supervisor, quiero identificar las empresas cuyos productos son más populares entre los clientes (más veces en favoritos).
-- =====================================================

SELECT 
    c.name AS empresa,
    COUNT(df.product_id) AS total_veces_en_favoritos
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN details_favorites df ON cp.product_id = df.product_id
GROUP BY c.id, c.name
ORDER BY total_veces_en_favoritos DESC;

-- =====================================================
-- 5. EMPRESAS SIN CALIFICACIONES 
-- Historia: Como técnico, quiero listar las empresas que no tienen ninguna calificación en sus productos.
-- =====================================================

SELECT 
    c.name AS empresa,
    c.business_name AS razon_social,
    ci.name AS ciudad,
    ct.name AS tipo_empresa,
    c.registration_date AS fecha_registro
FROM companies c
LEFT JOIN citiesormunicipalities ci ON c.city_id = ci.id
LEFT JOIN company_types ct ON c.company_type_id = ct.id
WHERE NOT EXISTS (
    SELECT 1 
    FROM rates r 
    WHERE r.company_id = c.id
)
ORDER BY c.name;

-- =====================================================
-- 6. PRODUCTOS MÁS VENDIDOS EN EL ÚLTIMO MES 
-- Historia: Como gerente, quiero identificar los productos que más se han vendido en el último mes.
-- =====================================================

SELECT 
    p.name AS producto,
    cat.name AS categoria,
    SUM(od.quantity) AS total_cantidad_vendida
FROM products p
INNER JOIN orderdetails od ON p.id = od.product_id
INNER JOIN orders o ON od.order_id = o.id
INNER JOIN categories cat ON p.category_id = cat.id
WHERE o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
GROUP BY p.id, p.name, cat.name
ORDER BY total_cantidad_vendida DESC;

-- =====================================================
-- 7. CLIENTES QUE HAN GASTADO MÁS DE X EN UNA SOLA COMPRA 
-- Historia: Como operador, quiero identificar a los clientes que han realizado compras de gran valor.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    o.total_amount AS monto_total_orden,
    o.order_date AS fecha_orden
FROM customers cu
INNER JOIN orders o ON cu.id = o.customer_id
WHERE o.total_amount > 500 -- Ejemplo: Gastado más de $500
ORDER BY o.total_amount DESC;

-- =====================================================
-- 8. BENEFICIOS MÁS UTILIZADOS POR CLIENTES 
-- Historia: Como analista, quiero saber cuáles son los beneficios más utilizados por los clientes.
-- =====================================================

SELECT 
    b.name AS beneficio,
    b.description AS descripcion,
    COUNT(mb.membership_id) AS total_veces_usado
FROM benefits b
INNER JOIN membershipbenefits mb ON b.id = mb.benefit_id
GROUP BY b.id, b.name, b.description
ORDER BY total_veces_usado DESC;

-- =====================================================
-- 9. PRODUCTOS CON MAYOR VARIACIÓN DE PRECIO ENTRE EMPRESAS 
-- Historia: Como técnico, quiero identificar los productos que tienen la mayor diferencia de precio entre las empresas que los venden.
-- =====================================================

SELECT 
    p.name AS producto,
    cat.name AS categoria,
    (MAX(cp.price) - MIN(cp.price)) AS diferencia_precio
FROM products p
INNER JOIN companyproducts cp ON p.id = cp.product_id
INNER JOIN categories cat ON p.category_id = cat.id
GROUP BY p.id, p.name, cat.name
ORDER BY diferencia_precio DESC;

-- =====================================================
-- 10. CIUDADES CON MAYOR CRECIMIENTO DE CLIENTES EN EL ÚLTIMO AÑO 
-- Historia: Como administrador, quiero identificar las ciudades con mayor crecimiento de clientes en el último año.
-- =====================================================

SELECT 
    ci.name AS ciudad,
    sr.name AS departamento,
    co.name AS pais,
    COUNT(cu.id) AS nuevos_clientes
FROM citiesormunicipalities ci
INNER JOIN stateregions sr ON ci.stateregion_id = sr.id
INNER JOIN countries co ON sr.country_id = co.id
INNER JOIN customers cu ON ci.id = cu.city_id
WHERE cu.registration_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
GROUP BY ci.id, ci.name, sr.name, co.name
ORDER BY nuevos_clientes DESC;

-- =====================================================
-- 11. PRODUCTOS CON MÁS COMENTARIOS NEGATIVOS 
-- Historia: Como gestor de calidad, quiero identificar los productos que tienen la mayor cantidad de comentarios negativos.
-- =====================================================

SELECT 
    p.name AS producto,
    cat.name AS categoria,
    COUNT(c.id) AS total_comentarios_negativos
FROM products p
INNER JOIN comments c ON p.id = c.product_id
INNER JOIN categories cat ON p.category_id = cat.id
WHERE c.rating < 3
GROUP BY p.id, p.name, cat.name
ORDER BY total_comentarios_negativos DESC;

-- =====================================================
-- 12. CLIENTES QUE HAN REFERIDO A MÁS DE X PERSONAS 
-- Historia: Como gestor de afiliados, quiero identificar a los afiliados más exitosos.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS afiliado,
    cu.email,
    COUNT(r.id) AS total_referidos
FROM affiliates a
INNER JOIN customers cu ON a.customer_id = cu.id
LEFT JOIN referrals r ON a.id = r.affiliate_id
GROUP BY cu.id, cu.first_name, cu.last_name, cu.email
HAVING COUNT(r.id) > 5 -- Ejemplo: Más de 5 referidos
ORDER BY total_referidos DESC;

-- =====================================================
-- 13. EMPRESAS CON MAYOR PROPORCIÓN DE CLIENTES VIP 
-- Historia: Como analista, quiero identificar las empresas que atraen más clientes VIP.
-- =====================================

SELECT 
    c.name AS empresa,
    (COUNT(CASE WHEN m.name = 'VIP' THEN cu.id END) / COUNT(cu.id)) * 100 AS porcentaje_vip
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN products p ON cp.product_id = p.id
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN customers cu ON r.customer_id = cu.id
LEFT JOIN membershipperiods mp ON cu.id = mp.customer_id AND mp.status = 'active'
LEFT JOIN memberships m ON mp.membership_id = m.id
GROUP BY c.id, c.name
HAVING COUNT(cu.id) > 0
ORDER BY porcentaje_vip DESC;

-- =====================================================
-- 14. PRODUCTOS CON MAYOR PRECIO ENTRE TODAS LAS EMPRESAS 
-- Historia: Como gerente comercial, quiero consultar los productos con el mayor precio entre todas las empresas
-- =====================================================

SELECT 
    p.name AS producto,
    cat.name AS categoria,
    precio_stats.precio_maximo,
    precio_stats.empresa_precio_maximo,
    precio_stats.precio_minimo,
    precio_stats.empresa_precio_minimo,
    precio_stats.precio_promedio,
    precio_stats.empresas_que_lo_venden
FROM products p
INNER JOIN categories cat ON p.category_id = cat.id
INNER JOIN (
    SELECT 
        cp.product_id,
        MAX(cp.price) AS precio_maximo,
        MIN(cp.price) AS precio_minimo,
        ROUND(AVG(cp.price), 2) AS precio_promedio,
        COUNT(*) AS empresas_que_lo_venden,
        -- Empresa con precio máximo (primera encontrada si hay empates)
        (SELECT c2.name 
         FROM companyproducts cp2 
         INNER JOIN companies c2 ON cp2.company_id = c2.id 
         WHERE cp2.product_id = cp.product_id 
         ORDER BY cp2.price DESC, c2.name ASC 
         LIMIT 1) AS empresa_precio_maximo,
        -- Empresa con precio mínimo (primera encontrada si hay empates)
        (SELECT c3.name 
         FROM companyproducts cp3 
         INNER JOIN companies c3 ON cp3.company_id = c3.id 
         WHERE cp3.product_id = cp.product_id 
         ORDER BY cp3.price ASC, c3.name ASC 
         LIMIT 1) AS empresa_precio_minimo
    FROM companyproducts cp
    GROUP BY cp.product_id
) precio_stats ON p.id = precio_stats.product_id
ORDER BY precio_stats.precio_maximo DESC;

-- =====================================================
-- 15. CLIENTES QUE HAN COMPRADO PRODUCTOS DE MÁS DE 3 CATEGORÍAS DIFERENTES 
-- Historia: Como analista de mercado, quiero identificar a los clientes que tienen un perfil de compra diversificado.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    COUNT(DISTINCT cat.id) AS categorias_diferentes
FROM customers cu
INNER JOIN orders o ON cu.id = o.customer_id
INNER JOIN orderdetails od ON o.id = od.order_id
INNER JOIN products p ON od.product_id = p.id
INNER JOIN categories cat ON p.category_id = cat.id
GROUP BY cu.id, cu.first_name, cu.last_name, cu.email
HAVING COUNT(DISTINCT cat.id) > 3
ORDER BY categorias_diferentes DESC;

-- =====================================================
-- 16. EMPRESAS CON MÁS PRODUCTOS CALIFICADOS CON 5 ESTRELLAS 
-- Historia: Como gestor de calidad, quiero identificar las empresas que consistentemente ofrecen productos de alta calidad.
-- =====================================================

SELECT 
    c.name AS empresa,
    COUNT(r.id) AS total_calificaciones_5_estrellas
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN rates r ON cp.product_id = r.product_id AND c.id = r.company_id
WHERE r.rating = 5
GROUP BY c.id, c.name
ORDER BY total_calificaciones_5_estrellas DESC;

-- =====================================================
-- 17. PRODUCTOS QUE NUNCA HAN SIDO AÑADIDOS A FAVORITOS 
-- Historia: Como gestor de producto, quiero identificar los productos que no están generando interés en los clientes.
-- =====================================================

SELECT 
    p.name AS producto,
    cat.name AS categoria
FROM products p
LEFT JOIN details_favorites df ON p.id = df.product_id
INNER JOIN categories cat ON p.category_id = cat.id
WHERE df.product_id IS NULL
ORDER BY p.name;

-- =====================================================
-- 18. CLIENTES QUE TIENEN MEMBRESÍA ACTIVA Y NO HAN REALIZADO NINGUNA COMPRA 
-- Historia: Como equipo de retención, quiero identificar a los clientes que tienen membresía activa pero no están comprando.
-- =====================================================

SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email
FROM customers cu
INNER JOIN membershipperiods mp ON cu.id = mp.customer_id AND mp.status = 'active' AND mp.end_date >= CURRENT_DATE
LEFT JOIN orders o ON cu.id = o.customer_id
WHERE o.id IS NULL
ORDER BY cu.first_name;

-- =====================================================
-- 19. EMPRESAS CON MAYOR PROMEDIO DE DESCUENTO EN SUS PRODUCTOS 
-- Historia: Como analista de precios, quiero identificar las empresas que ofrecen los mayores descuentos en sus productos.
-- =====================================================
SELECT 
    c.name AS empresa,
    ROUND(AVG(cp.price - COALESCE(i.cost, 0)), 2) AS promedio_margen,
    COUNT(cp.id) AS total_productos
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
LEFT JOIN inventory i ON cp.product_id = i.product_id AND cp.company_id = i.company_id
GROUP BY c.id, c.name
HAVING COUNT(cp.id) > 0
ORDER BY promedio_margen DESC;

-- =====================================================
-- 20. PRODUCTOS MÁS CALIFICADOS EN CADA CATEGORÍA 
-- Historia: Como gestor de catálogo, quiero identificar los productos estrella en cada categoría.
-- =====================================================

SELECT 
    cat.name AS categoria,
    p.name AS producto,
    ROUND(AVG(r.rating), 2) AS promedio_calificacion,
    COUNT(r.id) AS total_calificaciones
FROM products p
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN categories cat ON p.category_id = cat.id
GROUP BY cat.id, cat.name, p.id, p.name
HAVING AVG(r.rating) = (
    SELECT MAX(avg_rating)
    FROM (
        SELECT 
            p2.category_id,
            AVG(r2.rating) AS avg_rating
        FROM products p2
        INNER JOIN rates r2 ON p2.id = r2.product_id
        WHERE p2.category_id = cat.id
        GROUP BY p2.id
    ) AS category_ratings
)
ORDER BY categoria, total_calificaciones DESC;
