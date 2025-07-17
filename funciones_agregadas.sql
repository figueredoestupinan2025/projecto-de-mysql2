-- =====================================================
-- VERIFICACIÓN DE FUNCIONES AGREGADAS
-- ARCHIVO: Ejecutar y validar las 20 consultas con funciones agregadas
-- DESCRIPCIÓN: Confirmar la lógica y los resultados de las funciones agregadas
-- =====================================================

USE plataforma_comercial;

-- =====================================================
-- 0. PREPARACIÓN INICIAL Y DATOS DE PRUEBA PARA FUNCIONES AGREGADAS
-- =====================================================

SELECT '--- 0. PREPARACIÓN INICIAL Y DATOS DE PRUEBA PARA FUNCIONES AGREGADAS ---' AS seccion;

-- Limpiar datos de prueba específicos si existen para evitar conflictos
DELETE FROM rates WHERE customer_id = 9999 OR product_id = 9999;
DELETE FROM products WHERE name LIKE 'Producto Agregada Test%';
DELETE FROM customers WHERE email = 'cliente.agregada@example.com';
DELETE FROM companies WHERE name = 'Empresa Agregada Test';
DELETE FROM membershipperiods WHERE customer_id = 9999;
DELETE FROM favorites WHERE customer_id = 9999;
DELETE FROM details_favorites WHERE product_id = 9999;
DELETE FROM companyproducts WHERE product_id = 9999 OR company_id = 9999;
DELETE FROM polls WHERE title LIKE 'Encuesta Agregada Test%';
DELETE FROM quality_products WHERE product_id = 9999;
DELETE FROM log_acciones WHERE description LIKE '%Agregada Test%';
DELETE FROM notifications WHERE message LIKE '%Agregada Test%';
DELETE FROM benefits WHERE name = 'Beneficio Agregada Test';
DELETE FROM memberships WHERE name = 'Membresía Agregada Test';
DELETE FROM audiences WHERE name = 'Audiencia Agregada Test';
DELETE FROM company_types WHERE name = 'Tipo Empresa Agregada Test';
DELETE FROM units WHERE name = 'Unidad Agregada Test';

-- Asegurar que existan datos base para las pruebas
INSERT IGNORE INTO countries (id, name, code) VALUES (1, 'Colombia', 'COL');
INSERT IGNORE INTO stateregions (id, name, code, country_id) VALUES (1, 'Antioquia', 'ANT', 1);
INSERT IGNORE INTO citiesormunicipalities (id, name, code, stateregion_id) VALUES (1, 'Medellín', 'MED', 1), (2, 'Bogotá', 'BOG', 1), (3, 'Cali', 'CAL', 1);
INSERT IGNORE INTO categories (id, name, description) VALUES (1, 'Alimentos y Bebidas', 'Comestibles'), (2, 'Tecnología', 'Electrónica'), (3, 'Ropa y Accesorios', 'Vestimenta'), (4, 'Hogar', 'Artículos para el hogar');
INSERT IGNORE INTO units (id, name, abbreviation, type) VALUES (1, 'Kilogramo', 'kg', 'weight'), (8, 'Unidad', 'und', 'unit'), (9999, 'Unidad Agregada Test', 'UAT', 'unit');
INSERT IGNORE INTO audiences (id, name, description, age_range) VALUES (1, 'Niños', '0-12', '0-12 años'), (3, 'Jóvenes Adultos', '18-35', '18-35 años'), (9999, 'Audiencia Agregada Test', 'Para pruebas', 'N/A');
INSERT IGNORE INTO company_types (id, name, description) VALUES (1, 'Retail', 'Venta al por menor'), (9999, 'Tipo Empresa Agregada Test', 'Para pruebas');
INSERT IGNORE INTO memberships (id, name, description, level, status) VALUES (1, 'Básica', 'Esencial', 1, 'active'), (3, 'VIP', 'Exclusiva', 3, 'active'), (9999, 'Membresía Agregada Test', 'Para pruebas', 1, 'active');
INSERT IGNORE INTO benefits (id, name, description, type, value, status, expires_at) VALUES (1, 'Descuento', '10% off', 'discount', '10%', 'active', NULL), (2, 'Envío Gratis', 'Envío sin costo', 'service', 'free', 'active', NULL), (9999, 'Beneficio Agregada Test', 'Para pruebas', 'access', 'test', 'active', NULL);

INSERT IGNORE INTO customers (id, first_name, last_name, email, phone, birth_date, gender, city_id, audience_id, status) VALUES
(1, 'Juan', 'Perez', 'juan.perez@example.com', '1111111111', '1990-01-01', 'M', 1, 3, 'active'),
(2, 'Maria', 'Gomez', 'maria.gomez@example.com', '2222222222', '1992-02-02', 'F', 1, 3, 'active'),
(3, 'Carlos', 'Ruiz', 'carlos.ruiz@example.com', '3333333333', '1985-03-03', 'M', 2, 4, 'active'),
(4, 'Laura', 'Diaz', 'laura.diaz@example.com', '4444444444', '1995-04-04', 'F', 3, 3, 'active'),
(5, 'Pedro', 'Sánchez', 'pedro.sanchez@example.com', '5555555555', '1988-05-05', 'M', 1, 4, 'active'),
(9999, 'Cliente', 'Agregada Test', 'cliente.agregada@example.com', '9999999999', '2000-01-01', 'M', 1, 3, 'active'),
(10000, 'Cliente', 'Sin Email', NULL, '1234567890', '1990-01-01', 'M', 1, 3, 'active');


INSERT IGNORE INTO companies (id, name, business_name, tax_id, email, phone, address, city_id, company_type_id, audience_id, status) VALUES
(1, 'TechCorp', 'TechCorp S.A.', '123456789-0', 'info@techcorp.com', '4444444444', 'Calle Falsa 123', 1, 1, 3, 'active'),
(2, 'FoodMart', 'FoodMart Ltda.', '098765432-1', 'info@foodmart.com', '5555555555', 'Avenida Siempre Viva 456', 1, 1, 6, 'active'),
(3, 'ElectroMax', 'ElectroMax S.A.', '112233445-0', 'info@electromax.com', '6666666666', 'Calle 10 #20-30', 2, 1, 3, 'active'),
(4, 'ModaExpress', 'ModaExpress S.A.S.', '223344556-0', 'info@modaexpress.com', '7777777777', 'Carrera 50 #10-20', 1, 1, 3, 'active'),
(9999, 'Empresa Agregada Test', 'Empresa Agregada S.A.S.', '999999999-0', 'test@empresa.com', '1234567890', 'Calle Test 123', 1, 1, 3, 'active');

INSERT IGNORE INTO products (id, name, description, category_id, unit_id, status, average_rating) VALUES
(1, 'Laptop X1', 'Potente laptop para trabajo', 2, 8, 'active', 4.5),
(2, 'Café Orgánico', 'Café de alta calidad', 1, 1, 'active', 4.0),
(3, 'Teclado Mecánico', 'Teclado para gamers', 2, 8, 'active', 3.5),
(4, 'Camiseta Algodón', 'Camiseta de algodón suave', 3, 8, 'active', 4.2),
(5, 'Zapatos Deportivos', 'Zapatos para correr', 6, 8, 'active', 4.8),
(6, 'Crema Hidratante', 'Crema para el cuidado de la piel', 5, 5, 'active', 4.1),
(7, 'Libro de Cocina', 'Recetas fáciles y deliciosas', 1, 8, 'active', 4.6),
(8, 'Aceite de Oliva', 'Aceite de oliva extra virgen', 1, 4, 'active', 4.3),
(9, 'Set de Pinceles', 'Pinceles para artistas', 10, 8, 'active', 4.9),
(10, 'Filtro de Aire', 'Filtro de aire para autos', 8, 8, 'active', 3.8),
(11, 'Silla Ergonómica', 'Silla para oficina', 4, 8, 'active', 4.0),
(12, 'Mesa de Centro', 'Mesa para sala', 4, 8, 'active', 3.9),
(9999, 'Producto Agregada Test', 'Producto para pruebas de funciones agregadas', 2, 8, 'active', 0.0);

INSERT IGNORE INTO companyproducts (id, company_id, product_id, price, stock_quantity, unit_id, status) VALUES
(1, 1, 1, 1200.00, 10, 8, 'available'),
(2, 1, 3, 80.00, 20, 8, 'available'),
(3, 2, 2, 25.00, 50, 1, 'available'),
(4, 3, 1, 1250.00, 5, 8, 'available'),
(5, 3, 3, 85.00, 10, 8, 'available'),
(6, 1, 4, 30.00, 15, 8, 'available'),
(7, 2, 7, 15.00, 30, 8, 'available'),
(8, 3, 8, 20.00, 20, 8, 'available'),
(9, 1, 9, 50.00, 10, 8, 'available'),
(10, 2, 10, 12.00, 40, 8, 'available'),
(11, 4, 4, 32.00, 20, 8, 'available'), -- ModaExpress vende Camiseta Algodón
(12, 4, 11, 250.00, 5, 8, 'available'), -- ModaExpress vende Silla Ergonómica
(13, 4, 12, 150.00, 8, 8, 'available'), -- ModaExpress vende Mesa de Centro
(9999, 9999, 9999, 100.00, 5, 8, 'available');

INSERT IGNORE INTO rates (id, customer_id, product_id, company_id, rating, created_at, poll_id) VALUES
(1, 1, 1, 1, 5.0, '2025-07-10 10:00:00', 1),
(2, 2, 1, 1, 4.0, '2025-07-12 11:00:00', 1),
(3, 1, 2, 2, 4.0, '2025-06-01 12:00:00', NULL),
(4, 3, 3, 1, 3.0, '2025-07-15 13:00:00', 1),
(5, 4, 4, 1, 4.5, '2025-07-05 15:00:00', NULL),
(6, 5, 5, 3, 2.0, '2025-07-06 16:00:00', NULL),
(7, 1, 6, 4, 4.2, '2025-07-07 17:00:00', NULL),
(8, 2, 7, 5, 3.5, '2025-07-08 18:00:00', NULL),
(9, 3, 8, 1, 4.8, '2025-07-09 19:00:00', NULL),
(10, 4, 9, 1, 4.1, '2025-07-10 20:00:00', NULL),
(11, 5, 10, 2, 3.9, '2025-07-11 21:00:00', NULL),
(12, 1, 11, 4, 4.0, '2025-07-13 10:00:00', NULL),
(13, 2, 12, 4, 3.5, '2025-07-14 11:00:00', NULL),
(9999, 9999, 9999, 9999, 3.0, '2025-07-16 09:00:00', NULL);

INSERT IGNORE INTO favorites (id, customer_id, name) VALUES
(1, 1, 'Mis Favoritos'),
(2, 2, 'Favoritos de Maria'),
(3, 3, 'Favoritos de Carlos'),
(4, 4, 'Favoritos de Laura'),
(5, 5, 'Favoritos de Pedro'),
(9999, 9999, 'Favoritos Agregada Test');

INSERT IGNORE INTO details_favorites (favorite_id, product_id, added_date) VALUES
(1, 1, '2025-01-01'), (1, 2, '2025-01-01'), (1, 4, '2025-01-01'),
(2, 1, '2025-02-01'), (2, 3, '2025-02-01'),
(3, 4, '2025-03-01'),
(4, 5, '2025-04-01'), (4, 6, '2025-04-01'),
(5, 7, '2025-05-01'), (5, 8, '2025-05-01'),
(9999, 9999, '2025-07-16');

INSERT IGNORE INTO polls (id, title, description, type, status) VALUES
(1, 'Encuesta General', 'Encuesta de satisfacción general', 'product', 'active'),
(2, 'Encuesta Tecnología', 'Encuesta sobre productos tecnológicos', 'product', 'active'),
(9999, 'Encuesta Agregada Test', 'Para pruebas', 'product', 'active');

INSERT IGNORE INTO membershipperiods (id, customer_id, membership_id, start_date, end_date, price, status, payment_confirmed) VALUES
(1, 1, 3, '2025-01-01', '2025-12-31', 199.99, 'active', TRUE),
(2, 2, 1, '2025-01-01', '2025-12-31', 49.99, 'active', TRUE),
(3, 3, 3, '2025-01-01', '2025-12-31', 199.99, 'active', TRUE),
(4, 4, 1, '2025-01-01', '2025-12-31', 49.99, 'active', TRUE),
(5, 5, 3, '2025-01-01', '2025-12-31', 199.99, 'active', TRUE),
(9999, 9999, 3, '2025-01-01', '2025-12-31', 199.99, 'active', TRUE);

INSERT IGNORE INTO audiencebenefits (audience_id, benefit_id) VALUES (3, 1), (1, 2);
INSERT IGNORE INTO membershipbenefits (membership_id, benefit_id) VALUES (1, 1), (3, 2);

-- =====================================================
-- 1. OBTENER EL PROMEDIO DE CALIFICACIÓN POR PRODUCTO
-- =====================================================
SELECT '--- 1. PROMEDIO DE CALIFICACIÓN POR PRODUCTO ---' AS seccion;
SELECT 
    p.name AS producto,
    c.name AS categoria,
    ROUND(AVG(r.rating), 2) AS promedio_calificacion,
    COUNT(r.id) AS total_calificaciones
FROM products p
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN categories c ON p.category_id = c.id
GROUP BY p.id, p.name, c.name
ORDER BY promedio_calificacion DESC, total_calificaciones DESC
LIMIT 5;

-- =====================================================
-- 2. CONTAR CUÁNTOS PRODUCTOS HA CALIFICADO CADA CLIENTE
-- =====================================================
SELECT '--- 2. PRODUCTOS CALIFICADOS POR CLIENTE ---' AS seccion;
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    COUNT(r.id) AS productos_calificados,
    MAX(r.created_at) AS ultima_calificacion
FROM customers cu
LEFT JOIN rates r ON cu.id = r.customer_id
GROUP BY cu.id, cu.first_name, cu.last_name, cu.email
ORDER BY productos_calificados DESC
LIMIT 5;

-- =====================================================
-- 3. SUMAR EL TOTAL DE BENEFICIOS ASIGNADOS POR AUDIENCIA
-- =====================================================
SELECT '--- 3. TOTAL DE BENEFICIOS POR AUDIENCIA ---' AS seccion;
SELECT 
    a.name AS audiencia,
    COUNT(ab.benefit_id) AS total_beneficios_asignados
FROM audiences a
LEFT JOIN audiencebenefits ab ON a.id = ab.audience_id
GROUP BY a.id, a.name
ORDER BY total_beneficios_asignados DESC
LIMIT 5;

-- =====================================================
-- 4. CALCULAR LA MEDIA DE PRODUCTOS POR EMPRESA
-- =====================================================
SELECT '--- 4. MEDIA DE PRODUCTOS POR EMPRESA ---' AS seccion;
SELECT 
    ROUND(AVG(productos_por_empresa), 2) AS media_productos_por_empresa
FROM (
    SELECT 
        company_id,
        COUNT(product_id) AS productos_por_empresa
    FROM companyproducts
    GROUP BY company_id
) AS subquery;

-- =====================================================
-- 5. CONTAR EL TOTAL DE EMPRESAS POR CIUDAD
-- =====================================================
SELECT '--- 5. TOTAL DE EMPRESAS POR CIUDAD ---' AS seccion;
SELECT 
    ci.name AS ciudad,
    sr.name AS departamento,
    co.name AS pais,
    COUNT(c.id) AS total_empresas
FROM citiesormunicipalities ci
LEFT JOIN companies c ON ci.id = c.city_id
LEFT JOIN stateregions sr ON ci.stateregion_id = sr.id
LEFT JOIN countries co ON sr.country_id = co.id
GROUP BY ci.id, ci.name, sr.name, co.name
ORDER BY total_empresas DESC
LIMIT 5;

-- =====================================================
-- 6. CALCULAR EL PROMEDIO DE PRECIOS POR UNIDAD DE MEDIDA
-- =====================================================
SELECT '--- 6. PROMEDIO DE PRECIOS POR UNIDAD DE MEDIDA ---' AS seccion;
SELECT 
    u.name AS unidad_medida,
    u.abbreviation AS abreviacion,
    ROUND(AVG(cp.price), 2) AS promedio_precio
FROM units u
INNER JOIN companyproducts cp ON u.id = cp.unit_id
GROUP BY u.id, u.name, u.abbreviation
ORDER BY promedio_precio DESC
LIMIT 5;

-- =====================================================
-- 7. CONTAR CUÁNTOS CLIENTES HAY POR CIUDAD
-- =====================================================
SELECT '--- 7. TOTAL DE CLIENTES POR CIUDAD ---' AS seccion;
SELECT 
    ci.name AS ciudad,
    sr.name AS departamento,
    co.name AS pais,
    COUNT(cu.id) AS total_clientes
FROM citiesormunicipalities ci
LEFT JOIN customers cu ON ci.id = cu.city_id
LEFT JOIN stateregions sr ON ci.stateregion_id = sr.id
LEFT JOIN countries co ON sr.country_id = co.id
GROUP BY ci.id, ci.name, sr.name, co.name
ORDER BY total_clientes DESC
LIMIT 5;

-- =====================================================
-- 8. CALCULAR PLANES DE MEMBRESÍA POR PERIODO
-- =====================================================
SELECT '--- 8. PLANES DE MEMBRESÍA POR PERIODO ---' AS seccion;
SELECT 
    m.name AS tipo_membresia,
    YEAR(mp.start_date) AS anio,
    MONTH(mp.start_date) AS mes,
    COUNT(mp.id) AS total_periodos_activos
FROM membershipperiods mp
INNER JOIN memberships m ON mp.membership_id = m.id
WHERE mp.status = 'active'
GROUP BY m.name, anio, mes
ORDER BY anio DESC, mes DESC, total_periodos_activos DESC
LIMIT 5;

-- =====================================================
-- 9. VER EL PROMEDIO DE CALIFICACIONES DADAS POR UN CLIENTE A SUS FAVORITOS
-- =====================================================
SELECT '--- 9. PROMEDIO DE CALIFICACIONES DE FAVORITOS POR CLIENTE ---' AS seccion;
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    cu.email,
    ROUND(AVG(r.rating), 2) AS promedio_calificacion_favoritos,
    COUNT(r.id) AS total_calificaciones_favoritos
FROM customers cu
INNER JOIN favorites f ON cu.id = f.customer_id
INNER JOIN details_favorites df ON f.id = df.favorite_id
INNER JOIN rates r ON df.product_id = r.product_id AND cu.id = r.customer_id
GROUP BY cu.id, cu.first_name, cu.last_name, cu.email
ORDER BY promedio_calificacion_favoritos DESC
LIMIT 5;

-- =====================================================
-- 10. CONSULTAR LA FECHA MÁS RECIENTE EN QUE SE CALIFICÓ UN PRODUCTO
-- =====================================================
SELECT '--- 10. FECHA MÁS RECIENTE DE CALIFICACIÓN POR PRODUCTO ---' AS seccion;
SELECT 
    p.name AS producto,
    c.name AS categoria,
    MAX(r.created_at) AS ultima_calificacion_fecha
FROM products p
INNER JOIN rates r ON p.id = r.product_id
INNER JOIN categories c ON p.category_id = c.id
GROUP BY p.id, p.name, c.name
ORDER BY ultima_calificacion_fecha DESC
LIMIT 5;

-- =====================================================
-- 11. OBTENER LA DESVIACIÓN ESTÁNDAR DE PRECIOS POR CATEGORÍA
-- =====================================================
SELECT '--- 11. DESVIACIÓN ESTÁNDAR DE PRECIOS POR CATEGORÍA ---' AS seccion;
SELECT 
    cat.name AS categoria,
    ROUND(AVG(cp.price), 2) AS promedio_precio,
    ROUND(STDDEV(cp.price), 2) AS desviacion_estandar_precio,
    COUNT(DISTINCT cp.product_id) AS total_productos_en_categoria
FROM categories cat
INNER JOIN products p ON cat.id = p.category_id
INNER JOIN companyproducts cp ON p.id = cp.product_id
GROUP BY cat.id, cat.name
HAVING COUNT(cp.price) > 1 -- Necesita al menos 2 precios para calcular STDDEV
ORDER BY desviacion_estandar_precio DESC
LIMIT 5;

-- =====================================================
-- 12. CONTAR CUÁNTAS VECES UN PRODUCTO FUE FAVORITO
-- =====================================================
SELECT '--- 12. VECES QUE UN PRODUCTO FUE FAVORITO ---' AS seccion;
SELECT 
    p.name AS producto,
    cat.name AS categoria,
    COUNT(df.id) AS veces_en_favoritos
FROM products p
INNER JOIN details_favorites df ON p.id = df.product_id
INNER JOIN categories cat ON p.category_id = cat.id
GROUP BY p.id, p.name, cat.name
ORDER BY veces_en_favoritos DESC
LIMIT 5;

-- =====================================================
-- 13. CALCULAR EL PORCENTAJE DE PRODUCTOS EVALUADOS
-- =====================================================
SELECT '--- 13. PORCENTAJE DE PRODUCTOS EVALUADOS ---' AS seccion;
SELECT 
    (SELECT COUNT(DISTINCT product_id) FROM rates) AS productos_calificados,
    (SELECT COUNT(id) FROM products) AS total_productos,
    ROUND((SELECT COUNT(DISTINCT product_id) FROM rates) * 100.0 / (SELECT COUNT(id) FROM products), 2) AS porcentaje_evaluados;

-- =====================================================
-- 14. VER EL PROMEDIO DE RATING POR ENCUESTA
-- =====================================================
SELECT '--- 14. PROMEDIO DE RATING POR ENCUESTA ---' AS seccion;
SELECT 
    po.title AS titulo_encuesta,
    po.type AS tipo_encuesta,
    ROUND(AVG(r.rating), 2) AS promedio_rating_encuesta,
    COUNT(r.id) AS total_calificaciones_encuesta
FROM polls po
INNER JOIN rates r ON po.id = r.poll_id
GROUP BY po.id, po.title, po.type
ORDER BY promedio_rating_encuesta DESC, total_calificaciones_encuesta DESC
LIMIT 5;

-- =====================================================
-- 15. CALCULAR EL PROMEDIO Y TOTAL DE BENEFICIOS POR PLAN
-- =====================================================
SELECT '--- 15. TOTAL DE BENEFICIOS POR PLAN DE MEMBRESÍA ---' AS seccion;
SELECT 
    m.name AS plan_membresia,
    COUNT(mb.benefit_id) AS total_beneficios_asignados
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.membership_id
GROUP BY m.id, m.name
ORDER BY total_beneficios_asignados DESC
LIMIT 5;

-- =====================================================
-- 16. OBTENER MEDIA Y VARIANZA DE PRECIOS POR EMPRESA
-- =====================================================
SELECT '--- 16. MEDIA Y VARIANZA DE PRECIOS POR EMPRESA ---' AS seccion;
SELECT 
    c.name AS empresa,
    ROUND(AVG(cp.price), 2) AS promedio_precio_productos,
    ROUND(VAR_POP(cp.price), 2) AS varianza_precio_productos, -- VAR_POP para varianza poblacional
    ROUND(STDDEV_POP(cp.price), 2) AS desviacion_estandar_precio -- STDDEV_POP para desviación estándar poblacional
FROM companies c
INNER JOIN companyproducts cp ON c.id = cp.company_id
GROUP BY c.id, c.name
HAVING COUNT(cp.price) > 1 -- Necesita al menos 2 precios para calcular varianza/desviación
ORDER BY varianza_precio_productos DESC
LIMIT 5;

-- =====================================================
-- 17. VER TOTAL DE PRODUCTOS DISPONIBLES EN LA CIUDAD DEL CLIENTE
-- =====================================================
SELECT '--- 17. TOTAL DE PRODUCTOS DISPONIBLES EN LA CIUDAD DEL CLIENTE ---' AS seccion;
SELECT 
    CONCAT(cu.first_name, ' ', cu.last_name) AS cliente,
    ci.name AS ciudad_cliente,
    COUNT(DISTINCT cp.product_id) AS total_productos_disponibles_en_ciudad
FROM customers cu
INNER JOIN citiesormunicipalities ci ON cu.city_id = ci.id
INNER JOIN companies comp ON ci.id = comp.city_id
INNER JOIN companyproducts cp ON comp.id = cp.company_id
WHERE cp.status = 'available'
GROUP BY cu.id, cu.first_name, cu.last_name, ci.name
ORDER BY total_productos_disponibles_en_ciudad DESC
LIMIT 5;

-- =====================================================
-- 18. CONTAR PRODUCTOS ÚNICOS POR TIPO DE EMPRESA
-- =====================================================
SELECT '--- 18. PRODUCTOS ÚNICOS POR TIPO DE EMPRESA ---' AS seccion;
SELECT 
    ct.name AS tipo_empresa,
    COUNT(DISTINCT cp.product_id) AS total_productos_unicos
FROM company_types ct
LEFT JOIN companies c ON ct.id = c.company_type_id
LEFT JOIN companyproducts cp ON c.id = cp.company_id
WHERE cp.status = 'available' OR cp.status IS NULL -- Incluir tipos de empresa sin productos aún
GROUP BY ct.id, ct.name
ORDER BY total_productos_unicos DESC
LIMIT 5;

-- =====================================================
-- 19. VER TOTAL DE CLIENTES SIN CORREO ELECTRÓNICO REGISTRADO
-- =====================================================
SELECT '--- 19. TOTAL DE CLIENTES SIN CORREO ELECTRÓNICO ---' AS seccion;
SELECT 
    COUNT(id) AS total_clientes_sin_email
FROM customers
WHERE email IS NULL OR email = '';

-- =====================================================
-- 20. EMPRESA CON MÁS PRODUCTOS CALIFICADOS
-- =====================================================
SELECT '--- 20. EMPRESA CON MÁS PRODUCTOS CALIFICADOS ---' AS seccion;
SELECT 
    c.name AS empresa,
    COUNT(DISTINCT r.product_id) AS productos_calificados_unicos,
    COUNT(r.id) AS total_calificaciones_recibidas
FROM companies c
INNER JOIN rates r ON c.id = r.company_id
GROUP BY c.id, c.name
ORDER BY productos_calificados_unicos DESC, total_calificaciones_recibidas DESC
LIMIT 1;

-- =====================================================
-- FIN DE LA VERIFICACIÓN DE FUNCIONES AGREGADAS
-- =====================================================
