-- =====================================================
-- 20 SUBCONSULTAS SQL - PLATAFORMA COMERCIAL
-- =====================================================

-- =====================================================
-- 1. PRODUCTOS CON PRECIO SUPERIOR AL PROMEDIO DE SU CATEGORÍA
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    cp.price AS precio_producto,
    c.name AS empresa,
    ci.name AS ciudad,
    (
        SELECT ROUND(AVG(cp2.price), 2) 
        FROM companyproducts cp2 
        INNER JOIN products p2 ON cp2.product_id = p2.id 
        WHERE p2.category_id = p.category_id
    ) AS promedio_categoria
FROM products p
INNER JOIN companyproducts cp ON p.id = cp.product_id
INNER JOIN companies c ON cp.company_id = c.id
INNER JOIN categories cat ON p.category_id = cat.id
LEFT JOIN citiesormunicipalities ci ON c.city_id = ci.id
WHERE cp.price > (
    SELECT AVG(cp2.price) 
    FROM companyproducts cp2 
    INNER JOIN products p2 ON cp2.product_id = p2.id 
    WHERE p2.category_id = p.category_id
)
AND cp.status = 'available'
ORDER BY cat.name, precio_producto DESC
LIMIT 5;

-- =====================================================
-- 2. EMPRESAS CON MÁS PRODUCTOS QUE LA MEDIA
-- =====================================================
SELECT 
    c.name AS empresa,
    c.business_name AS razon_social,
    ci.name AS ciudad,
    ct.name AS tipo_empresa,
    COUNT(DISTINCT cp.product_id) AS productos_ofrecidos,
    (
        SELECT ROUND(AVG(producto_count), 2)
        FROM (
            SELECT COUNT(DISTINCT cp2.product_id) as producto_count
            FROM companies c2
            INNER JOIN companyproducts cp2 ON c2.id = cp2.company_id
            WHERE c2.status = 'active'
            GROUP BY c2.id
        ) AS avg_calc
    ) AS promedio_productos_por_empresa
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
LEFT JOIN citiesormunicipalities ci ON c.city_id = ci.id
LEFT JOIN company_types ct ON c.company_type_id = ct.id
WHERE c.status = 'active' AND cp.status = 'available'
GROUP BY c.id, c.name, c.business_name, ci.name, ct.name
HAVING COUNT(DISTINCT cp.product_id) > (
    SELECT AVG(producto_count)
    FROM (
        SELECT COUNT(DISTINCT cp2.product_id) as producto_count
        FROM companies c2
        INNER JOIN companyproducts cp2 ON c2.id = cp2.company_id
        WHERE c2.status = 'active'
        GROUP BY c2.id
    ) AS avg_calc
)
ORDER BY productos_ofrecidos DESC
LIMIT 5;

-- =====================================================
-- 3. PRODUCTOS FAVORITOS QUE HAN SIDO CALIFICADOS POR OTROS CLIENTES
-- =====================================================
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    p.name AS producto_favorito,
    cat.name AS categoria,
    f.name AS lista_favoritos,
    (
        SELECT COUNT(DISTINCT r.customer_id)
        FROM rates r 
        WHERE r.product_id = p.id AND r.customer_id != cu.id
    ) AS otros_clientes_que_calificaron,
    (
        SELECT ROUND(AVG(r.rating), 2)
        FROM rates r 
        WHERE r.product_id = p.id AND r.customer_id != cu.id
    ) AS promedio_calificacion_otros
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN products p ON df.product_id = p.id
LEFT JOIN categories cat ON p.category_id = cat.id
WHERE EXISTS (
    SELECT 1 
    FROM rates r 
    WHERE r.product_id = p.id AND r.customer_id != cu.id
)
ORDER BY cu.first_name, otros_clientes_que_calificaron DESC
LIMIT 5;

-- =====================================================
-- 4. PRODUCTOS CON MAYOR NÚMERO DE VECES EN FAVORITOS
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    COUNT(df.id) AS veces_en_favoritos,
    (
        SELECT COUNT(df2.id) 
        FROM details_favorites df2 
        INNER JOIN favorites f2 ON df2.favorite_id = f2.id
    ) AS total_favoritos_sistema,
    ROUND(COUNT(df.id) * 100.0 / (
        SELECT COUNT(df2.id) 
        FROM details_favorites df2
    ), 2) AS porcentaje_popularidad,
    (
        SELECT COUNT(DISTINCT r.customer_id)
        FROM rates r 
        WHERE r.product_id = p.id
    ) AS clientes_que_calificaron,
    (
        SELECT ROUND(AVG(r.rating), 2)
        FROM rates r 
        WHERE r.product_id = p.id
    ) AS promedio_calificacion,
    (
        SELECT MIN(cp.price)
        FROM companyproducts cp 
        WHERE cp.product_id = p.id AND cp.status = 'available'
    ) AS precio_minimo_disponible
FROM products p
INNER JOIN details_favorites df ON p.id = df.product_id
LEFT JOIN categories cat ON p.category_id = cat.id
GROUP BY p.id, p.name, cat.name
HAVING COUNT(df.id) >= (
    SELECT AVG(fav_count)
    FROM (
        SELECT COUNT(df2.id) as fav_count
        FROM products p2
        INNER JOIN details_favorites df2 ON p2.id = df2.product_id
        GROUP BY p2.id
    ) AS avg_calc
)
ORDER BY veces_en_favoritos DESC, promedio_calificacion DESC
LIMIT 5;

-- =====================================================
-- 5. CLIENTES SIN CALIFICACIONES NI QUALITY_PRODUCTS
-- =====================================================
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    ci.name AS ciudad,
    a.name AS audiencia,
    DATEDIFF(CURRENT_DATE, cu.registration_date) AS dias_registrado,
    (
        SELECT COUNT(df.id)
        FROM favorites f
        INNER JOIN details_favorites df ON f.id = df.favorite_id
        WHERE f.customer_id = cu.id
    ) AS productos_en_favoritos,
    (
        SELECT COUNT(mp.id)
        FROM membershipperiods mp
        WHERE mp.customer_id = cu.id AND mp.status = 'active'
    ) AS membresias_activas
FROM customers cu
LEFT JOIN citiesormunicipalities ci ON cu.city_id = ci.id
LEFT JOIN audiences a ON cu.audience_id = a.id
WHERE cu.status = 'active'
    AND NOT EXISTS (SELECT 1 FROM rates r WHERE r.customer_id = cu.id)
    AND NOT EXISTS (SELECT 1 FROM quality_products qp WHERE qp.customer_id = cu.id)
ORDER BY dias_registrado DESC, productos_en_favoritos DESC
LIMIT 5;

-- =====================================================
-- 6. PRODUCTOS CON CALIFICACIÓN INFERIOR AL MÍNIMO DE SU CATEGORÍA
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    ROUND(AVG(r.rating), 2) AS promedio_producto,
    COUNT(r.id) AS total_calificaciones,
    (
        SELECT MIN(avg_rating)
        FROM (
            SELECT AVG(r2.rating) as avg_rating
            FROM products p2
            INNER JOIN rates r2 ON p2.id = r2.product_id
            WHERE p2.category_id = p.category_id
            GROUP BY p2.id
            HAVING COUNT(r2.id) >= 2
        ) AS min_calc
    ) AS minimo_categoria
FROM products p
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN categories cat ON p.category_id = cat.id
GROUP BY p.id, p.name, cat.id, cat.name
HAVING COUNT(r.id) >= 2
    AND AVG(r.rating) < (
        SELECT MIN(avg_rating)
        FROM (
            SELECT AVG(r2.rating) as avg_rating
            FROM products p2
            INNER JOIN rates r2 ON p2.id = r2.product_id
            WHERE p2.category_id = p.category_id
            GROUP BY p2.id
            HAVING COUNT(r2.id) >= 2
        ) AS min_calc
    )
ORDER BY promedio_producto ASC, total_calificaciones DESC
LIMIT 5;

-- =====================================================
-- 7. CIUDADES SIN CLIENTES
-- =====================================================
SELECT 
    ci.name AS ciudad,
    sr.name AS departamento,
    co.name AS pais,
    (
        SELECT COUNT(c.id)
        FROM companies c
        WHERE c.city_id = ci.id AND c.status = 'active'
    ) AS empresas_activas,
    (
        SELECT COUNT(DISTINCT cp.product_id)
        FROM companies c
        INNER JOIN companyproducts cp ON c.id = cp.company_id
        WHERE c.city_id = ci.id AND c.status = 'active' AND cp.status = 'available'
    ) AS productos_disponibles
FROM citiesormunicipalities ci
INNER JOIN stateregions sr ON ci.stateregion_id = sr.id
INNER JOIN countries co ON sr.country_id = co.id
WHERE NOT EXISTS (
    SELECT 1 
    FROM customers cu 
    WHERE cu.city_id = ci.id AND cu.status = 'active'
)
ORDER BY empresas_activas DESC, productos_disponibles DESC
LIMIT 5;

-- =====================================================
-- 8. PRODUCTOS NO EVALUADOS EN NINGUNA ENCUESTA
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    p.description AS descripcion,
    (
        SELECT COUNT(cp.id)
        FROM companyproducts cp
        WHERE cp.product_id = p.id AND cp.status = 'available'
    ) AS empresas_que_lo_venden,
    (
        SELECT COUNT(r.id)
        FROM rates r
        WHERE r.product_id = p.id
    ) AS calificaciones_sin_encuesta,
    (
        SELECT COUNT(df.id)
        FROM details_favorites df
        WHERE df.product_id = p.id
    ) AS veces_en_favoritos,
    (
        SELECT MIN(cp.price)
        FROM companyproducts cp
        WHERE cp.product_id = p.id AND cp.status = 'available'
    ) AS precio_minimo
FROM products p
LEFT JOIN categories cat ON p.category_id = cat.id
WHERE p.status = 'active'
    AND NOT EXISTS (
        SELECT 1 
        FROM rates r 
        WHERE r.product_id = p.id AND r.poll_id IS NOT NULL
    )
    AND NOT EXISTS (
        SELECT 1 
        FROM quality_products qp 
        WHERE qp.product_id = p.id AND qp.poll_id IS NOT NULL
    )
ORDER BY calificaciones_sin_encuesta DESC, veces_en_favoritos DESC
LIMIT 5;

-- =====================================================
-- 9. BENEFICIOS NO ASIGNADOS A NINGUNA AUDIENCIA
-- =====================================================
SELECT 
    b.name AS beneficio,
    b.description AS descripcion,
    b.type AS tipo_beneficio,
    b.value AS valor,
    b.status AS estado,
    b.expires_at AS fecha_expiracion,
    (
        SELECT COUNT(mb.id)
        FROM membershipbenefits mb
        WHERE mb.benefit_id = b.id
    ) AS asignado_a_membresias,
    (
        SELECT GROUP_CONCAT(m.name SEPARATOR ', ')
        FROM membershipbenefits mb
        INNER JOIN memberships m ON mb.membership_id = m.id
        WHERE mb.benefit_id = b.id
    ) AS membresias_que_lo_incluyen
FROM benefits b
WHERE b.status = 'active'
    AND NOT EXISTS (
        SELECT 1 
        FROM audiencebenefits ab 
        WHERE ab.benefit_id = b.id
    )
ORDER BY b.created_at DESC
LIMIT 5;

-- =====================================================
-- 10. PRODUCTOS FAVORITOS NO DISPONIBLES
-- =====================================================
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    p.name AS producto_favorito,
    cat.name AS categoria,
    df.added_date AS fecha_agregado_favoritos,
    p.status AS estado_producto,
    (
        SELECT COUNT(cp.id)
        FROM companyproducts cp
        WHERE cp.product_id = p.id AND cp.status = 'available'
    ) AS empresas_disponibles
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN products p ON df.product_id = p.id
LEFT JOIN categories cat ON p.category_id = cat.id
WHERE NOT EXISTS (
    SELECT 1 
    FROM companyproducts cp 
    WHERE cp.product_id = p.id AND cp.status = 'available'
)
ORDER BY cu.first_name, df.added_date DESC
LIMIT 5;

-- =====================================================
-- 11. PRODUCTOS VENDIDOS EN CIUDADES CON MENOS DE 3 EMPRESAS
-- =====================================================
SELECT 
    ci.name AS ciudad,
    sr.name AS departamento,
    (
        SELECT COUNT(c2.id)
        FROM companies c2
        WHERE c2.city_id = ci.id AND c2.status = 'active'
    ) AS total_empresas_ciudad,
    p.name AS producto,
    cat.name AS categoria,
    c.name AS empresa,
    cp.price AS precio
FROM citiesormunicipalities ci
INNER JOIN stateregions sr ON ci.stateregion_id = sr.id
INNER JOIN companies c ON ci.id = c.city_id
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN products p ON cp.product_id = p.id
LEFT JOIN categories cat ON p.category_id = cat.id
WHERE c.status = 'active' 
    AND cp.status = 'available'
    AND (
        SELECT COUNT(c2.id)
        FROM companies c2
        WHERE c2.city_id = ci.id AND c2.status = 'active'
    ) < 3
ORDER BY total_empresas_ciudad ASC, ci.name, p.name
LIMIT 5;

-- =====================================================
-- 12. PRODUCTOS CON CALIDAD SUPERIOR AL PROMEDIO GENERAL
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    COUNT(qp.id) AS evaluaciones_calidad,
    ROUND(AVG(qp.quality_score), 2) AS promedio_calidad_producto,
    (
        SELECT ROUND(AVG(quality_score), 2)
        FROM quality_products
    ) AS promedio_calidad_general
FROM products p
INNER JOIN quality_products qp ON p.id = qp.product_id
LEFT JOIN categories cat ON p.category_id = cat.id
GROUP BY p.id, p.name, cat.name
HAVING AVG(qp.quality_score) > (
    SELECT AVG(quality_score)
    FROM quality_products
)
ORDER BY promedio_calidad_producto DESC
LIMIT 5;

-- =====================================================
-- 13. EMPRESAS QUE SOLO VENDEN PRODUCTOS DE UNA ÚNICA CATEGORÍA
-- =====================================================
SELECT 
    c.name AS empresa,
    c.business_name AS razon_social,
    ci.name AS ciudad,
    ct.name AS tipo_empresa,
    COUNT(DISTINCT p.category_id) AS categorias_unicas,
    GROUP_CONCAT(DISTINCT cat.name SEPARATOR ', ') AS nombres_categorias
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN products p ON cp.product_id = p.id
LEFT JOIN categories cat ON p.category_id = cat.id
LEFT JOIN citiesormunicipalities ci ON c.city_id = ci.id
LEFT JOIN company_types ct ON c.company_type_id = ct.id
WHERE c.status = 'active' AND cp.status = 'available'
GROUP BY c.id, c.name, c.business_name, ci.name, ct.name
HAVING COUNT(DISTINCT p.category_id) = 1
ORDER BY c.name
LIMIT 5;

-- =====================================================
-- 14. PRODUCTOS CON EL MAYOR PRECIO ENTRE TODAS LAS EMPRESAS
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    cp.price AS precio_maximo,
    c.name AS empresa_vendedora,
    ci.name AS ciudad_empresa
FROM products p
INNER JOIN companyproducts cp ON p.id = cp.product_id
INNER JOIN companies c ON cp.company_id = c.id
LEFT JOIN categories cat ON p.category_id = cat.id
LEFT JOIN citiesormunicipalities ci ON c.city_id = ci.id
WHERE cp.price = (
    SELECT MAX(cp2.price)
    FROM companyproducts cp2
    WHERE cp2.product_id = p.id
)
ORDER BY precio_maximo DESC, p.name
LIMIT 5;

-- =====================================================
-- 15. PRODUCTOS FAVORITOS CALIFICADOS POR OTRO CLIENTE CON +4 ESTRELLAS
-- =====================================================
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    p.name AS producto_favorito,
    cat.name AS categoria,
    (
        SELECT COUNT(r.id)
        FROM rates r
        WHERE r.product_id = p.id AND r.customer_id != cu.id AND r.rating >= 4
    ) AS calificaciones_altas_otros,
    (
        SELECT ROUND(AVG(r.rating), 2)
        FROM rates r
        WHERE r.product_id = p.id AND r.customer_id != cu.id AND r.rating >= 4
    ) AS promedio_altas_otros
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN products p ON df.product_id = p.id
LEFT JOIN categories cat ON p.category_id = cat.id
WHERE EXISTS (
    SELECT 1
    FROM rates r
    WHERE r.product_id = p.id AND r.customer_id != cu.id AND r.rating >= 4
)
ORDER BY cliente, calificaciones_altas_otros DESC
LIMIT 5;

-- =====================================================
-- 16. PRODUCTOS SIN IMAGEN PERO CALIFICADOS
-- =====================================================
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    COUNT(r.id) AS total_calificaciones,
    ROUND(AVG(r.rating), 2) AS promedio_calificacion
FROM products p
INNER JOIN rates r ON p.id = r.product_id
LEFT JOIN categories cat ON p.category_id = cat.id
WHERE p.image_url IS NULL OR p.image_url = ''
GROUP BY p.id, p.name, cat.name
ORDER BY total_calificaciones DESC, promedio_calificacion DESC
LIMIT 5;

-- =====================================================
-- 17. PLANES DE MEMBRESÍA SIN PERIODO VIGENTE
-- =====================================================
SELECT 
    m.name AS nombre_membresia,
    m.description AS descripcion,
    m.level AS nivel,
    m.status AS estado_membresia,
    (
        SELECT COUNT(mp.id)
        FROM membershipperiods mp
        WHERE mp.membership_id = m.id AND mp.status = 'active' AND mp.end_date >= CURRENT_DATE
    ) AS periodos_activos_actualmente
FROM memberships m
WHERE m.status = 'active'
    AND NOT EXISTS (
        SELECT 1
        FROM membershipperiods mp
        WHERE mp.membership_id = m.id AND mp.status = 'active' AND mp.end_date >= CURRENT_DATE
    )
ORDER BY m.name
LIMIT 5;

-- =====================================================
-- 18. BENEFICIOS COMPARTIDOS POR MÁS DE UNA AUDIENCIA
-- =====================================================
SELECT 
    b.name AS beneficio,
    b.description AS descripcion,
    b.type AS tipo_beneficio,
    COUNT(ab.audience_id) AS total_audiencias_compartidas,
    GROUP_CONCAT(a.name SEPARATOR ', ') AS nombres_audiencias
FROM benefits b
INNER JOIN audiencebenefits ab ON b.id = ab.benefit_id
INNER JOIN audiences a ON ab.audience_id = a.id
WHERE b.status = 'active'
GROUP BY b.id, b.name, b.description, b.type
HAVING COUNT(ab.audience_id) > 1
ORDER BY total_audiencias_compartidas DESC, b.name
LIMIT 5;

-- =====================================================
-- 19. EMPRESAS CON PRODUCTOS SIN UNIDAD DE MEDIDA DEFINIDA
-- =====================================================
SELECT 
    c.name AS empresa,
    c.business_name AS razon_social,
    ci.name AS ciudad,
    COUNT(DISTINCT p.id) AS productos_sin_unidad_definida,
    GROUP_CONCAT(DISTINCT p.name SEPARATOR ', ') AS nombres_productos_sin_unidad
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
INNER JOIN products p ON cp.product_id = p.id
LEFT JOIN citiesormunicipalities ci ON c.city_id = ci.id
WHERE p.unit_id IS NULL
GROUP BY c.id, c.name, c.business_name, ci.name
ORDER BY productos_sin_unidad_definida DESC, c.name
LIMIT 5;

-- =====================================================
-- 20. CLIENTES CON MEMBRESÍA ACTIVA Y SIN PRODUCTOS FAVORITOS
-- =====================================================
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    m.name AS tipo_membresia,
    mp.end_date AS fecha_fin_membresia,
    DATEDIFF(mp.end_date, CURRENT_DATE) AS dias_restantes_membresia
FROM customers cu
INNER JOIN membershipperiods mp ON cu.id = mp.customer_id
INNER JOIN memberships m ON mp.membership_id = m.id
WHERE mp.status = 'active' AND mp.end_date >= CURRENT_DATE
    AND NOT EXISTS (
        SELECT 1
        FROM favorites f
        INNER JOIN details_favorites df ON f.id = df.favorite_id
        WHERE f.customer_id = cu.id
    )
ORDER BY dias_restantes_membresia ASC, cu.first_name
LIMIT 5;
