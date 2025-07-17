-- =====================================================
-- PROYECTO: PLATAFORMA DE COMERCIALIZACIÓN DIGITAL MULTINIVEL
-- ARCHIVO: Funciones Definidas por el Usuario (UDFs) - 20 Historias de Usuario
-- DESCRIPCIÓN: Creación de funciones personalizadas para lógica de negocio específica
-- =====================================================

USE plataforma_comercial;

-- Habilitar la creación de funciones y procedimientos almacenados si no está habilitado
SET GLOBAL log_bin_trust_function_creators = 1;

-- =====================================================
-- 1. CALCULAR PROMEDIO PONDERADO DE CALIDAD DE UN PRODUCTO
-- Historia: Como analista, quiero una función que calcule el promedio ponderado de calidad de un producto basado en sus calificaciones y fecha de evaluación.
-- =====================================================
DROP FUNCTION IF EXISTS calcular_promedio_ponderado_calidad;
DELIMITER //
CREATE FUNCTION calcular_promedio_ponderado_calidad(p_product_id INT)
RETURNS DECIMAL(2,1)
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(2,1);
    SELECT 
        ROUND(SUM(r.rating * (1 - (DATEDIFF(CURRENT_DATE, r.created_at) / 365.0))) / SUM(1 - (DATEDIFF(CURRENT_DATE, r.created_at) / 365.0)), 1)
    INTO v_promedio
    FROM rates r
    WHERE r.product_id = p_product_id
    AND DATEDIFF(CURRENT_DATE, r.created_at) < 365; -- Solo calificaciones del último año para ponderación

    IF v_promedio IS NULL THEN
        RETURN 0.0;
    END IF;
    RETURN v_promedio;
END //
DELIMITER ;

-- =====================================================
-- 2. DETERMINAR SI UN PRODUCTO HA SIDO CALIFICADO RECIENTEMENTE
-- Historia: Como auditor, deseo una función que determine si un producto ha sido calificado recientemente (últimos 30 días).
-- =====================================================
DROP FUNCTION IF EXISTS es_calificado_recientemente;
DELIMITER //
CREATE FUNCTION es_calificado_recientemente(p_product_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_reciente BOOLEAN DEFAULT FALSE;
    SELECT EXISTS (
        SELECT 1
        FROM rates
        WHERE product_id = p_product_id AND created_at >= NOW() - INTERVAL 30 DAY
    ) INTO v_reciente;
    RETURN v_reciente;
END //
DELIMITER ;

-- =====================================================
-- 3. OBTENER EL NOMBRE COMPLETO DE LA EMPRESA QUE VENDE UN PRODUCTO
-- Historia: Como desarrollador, quiero una función que reciba un product_id y devuelva el nombre completo de la empresa que lo vende.
-- =====================================================
DROP FUNCTION IF EXISTS obtener_empresa_de_producto;
DELIMITER //
CREATE FUNCTION obtener_empresa_de_producto(p_product_id INT)
RETURNS VARCHAR(200)
READS SQL DATA
BEGIN
    DECLARE v_company_name VARCHAR(200);
    SELECT c.name INTO v_company_name
    FROM companies c
    INNER JOIN companyproducts cp ON c.id = cp.company_id
    WHERE cp.product_id = p_product_id
    LIMIT 1; -- Asume que un producto puede ser vendido por varias, devuelve la primera encontrada

    IF v_company_name IS NULL THEN
        RETURN 'No disponible';
    END IF;
    RETURN v_company_name;
END //
DELIMITER ;

-- =====================================================
-- 4. INDICAR SI UN CLIENTE TIENE UNA MEMBRESÍA ACTIVA
-- Historia: Como operador, quiero una función que, dado un customer_id, me indique si el cliente tiene una membresía activa.
-- =====================================================
DROP FUNCTION IF EXISTS tiene_membresia_activa;
DELIMITER //
CREATE FUNCTION tiene_membresia_activa(p_customer_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_activa BOOLEAN DEFAULT FALSE;
    SELECT EXISTS (
        SELECT 1
        FROM membershipperiods
        WHERE customer_id = p_customer_id
          AND status = 'active'
          AND CURRENT_DATE BETWEEN start_date AND end_date
    ) INTO v_activa;
    RETURN v_activa;
END //
DELIMITER ;

-- =====================================================
-- 5. VALIDAR SI UNA CIUDAD TIENE MÁS DE X EMPRESAS REGISTRADAS
-- Historia: Como administrador, quiero una función que valide si una ciudad tiene más de X empresas registradas, recibiendo la ciudad y el número como parámetros.
-- =====================================================
DROP FUNCTION IF EXISTS ciudad_supera_empresas_limite;
DELIMITER //
CREATE FUNCTION ciudad_supera_empresas_limite(p_city_id INT, p_limite INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM companies
    WHERE city_id = p_city_id AND status = 'active';

    RETURN v_count > p_limite;
END //
DELIMITER ;

-- =====================================================
-- 6. DEVOLVER DESCRIPCIÓN TEXTUAL DE LA CALIFICACIÓN
-- Historia: Como gerente, deseo una función que, dado un rate_id, me devuelva una descripción textual de la calificación.
-- =====================================================
DROP FUNCTION IF EXISTS descripcion_calificacion;
DELIMITER //
CREATE FUNCTION descripcion_calificacion(p_rate_id INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_rating DECIMAL(2,1);
    SELECT rating INTO v_rating FROM rates WHERE id = p_rate_id;

    IF v_rating IS NULL THEN
        RETURN 'Sin calificación';
    ELSEIF v_rating >= 4.5 THEN
        RETURN 'Excelente';
    ELSEIF v_rating >= 3.5 THEN
        RETURN 'Muy Bueno';
    ELSEIF v_rating >= 2.5 THEN
        RETURN 'Bueno';
    ELSEIF v_rating >= 1.5 THEN
        RETURN 'Regular';
    ELSE
        RETURN 'Malo';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 7. DEVOLVER EL ESTADO DE UN PRODUCTO EN FUNCIÓN DE SU EVALUACIÓN
-- Historia: Como técnico, quiero una función que devuelva el estado de un producto en función de su evaluación (ej. “Aceptable”, “Crítico”).
-- =====================================================
DROP FUNCTION IF EXISTS estado_producto_por_evaluacion;
DELIMITER //
CREATE FUNCTION estado_producto_por_evaluacion(p_product_id INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_avg_rating DECIMAL(2,1);
    SELECT average_rating INTO v_avg_rating FROM products WHERE id = p_product_id;

    IF v_avg_rating IS NULL OR v_avg_rating = 0.0 THEN
        RETURN 'Sin evaluar';
    ELSEIF v_avg_rating >= 4.0 THEN
        RETURN 'Óptimo';
    ELSEIF v_avg_rating >= 2.5 THEN
        RETURN 'Aceptable';
    ELSE
        RETURN 'Crítico';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 8. INDICAR SI UN PRODUCTO ESTÁ ENTRE MIS FAVORITOS
-- Historia: Como cliente, deseo una función que indique si un producto está entre mis favoritos, recibiendo el product_id y mi customer_id.
-- =====================================================
DROP FUNCTION IF EXISTS es_producto_favorito;
DELIMITER //
CREATE FUNCTION es_producto_favorito(p_customer_id INT, p_product_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_is_favorite BOOLEAN DEFAULT FALSE;
    SELECT EXISTS (
        SELECT 1
        FROM details_favorites df
        INNER JOIN favorites f ON df.favorite_id = f.id
        WHERE f.customer_id = p_customer_id AND df.product_id = p_product_id
    ) INTO v_is_favorite;
    RETURN v_is_favorite;
END //
DELIMITER ;

-- =====================================================
-- 9. DETERMINAR SI UN BENEFICIO ESTÁ ASIGNADO A UNA AUDIENCIA ESPECÍFICA
-- Historia: Como gestor de beneficios, quiero una función que determine si un beneficio está asignado a una audiencia específica, retornando verdadero o falso.
-- =====================================================
DROP FUNCTION IF EXISTS beneficio_asignado_a_audiencia;
DELIMITER //
CREATE FUNCTION beneficio_asignado_a_audiencia(p_benefit_id INT, p_audience_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_is_assigned BOOLEAN DEFAULT FALSE;
    SELECT EXISTS (
        SELECT 1
        FROM audiencebenefits
        WHERE benefit_id = p_benefit_id AND audience_id = p_audience_id
    ) INTO v_is_assigned;
    RETURN v_is_assigned;
END //
DELIMITER ;

-- =====================================================
-- 10. DETERMINAR SI UNA FECHA SE ENCUENTRA DENTRO DE UN RANGO DE MEMBRESÍA ACTIVA
-- Historia: Como auditor, deseo una función que reciba una fecha y determine si se encuentra dentro de un rango de membresía activa.
-- =====================================================
DROP FUNCTION IF EXISTS fecha_en_membresia_activa;
DELIMITER //
CREATE FUNCTION fecha_en_membresia_activa(p_check_date DATE, p_customer_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_in_range BOOLEAN DEFAULT FALSE;
    SELECT EXISTS (
        SELECT 1
        FROM membershipperiods
        WHERE customer_id = p_customer_id
          AND status = 'active'
          AND p_check_date BETWEEN start_date AND end_date
    ) INTO v_in_range;
    RETURN v_in_range;
END //
DELIMITER ;

-- =====================================================
-- 11. CALCULAR EL PORCENTAJE DE CALIFICACIONES POSITIVAS DE UN PRODUCTO
-- Historia: Como desarrollador, quiero una función que calcule el porcentaje de calificaciones positivas de un producto respecto al total.
-- =====================================================
DROP FUNCTION IF EXISTS porcentaje_calificaciones_positivas;
DELIMITER //
CREATE FUNCTION porcentaje_calificaciones_positivas(p_product_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total_ratings INT;
    DECLARE v_positive_ratings INT;
    
    SELECT COUNT(*) INTO v_total_ratings FROM rates WHERE product_id = p_product_id;
    SELECT COUNT(*) INTO v_positive_ratings FROM rates WHERE product_id = p_product_id AND rating >= 4.0; -- Definimos positivo como >= 4.0

    IF v_total_ratings = 0 THEN
        RETURN 0.00;
    END IF;
    RETURN (v_positive_ratings * 100.0 / v_total_ratings);
END //
DELIMITER ;

-- =====================================================
-- 12. CALCULAR LA EDAD DE UNA CALIFICACIÓN EN DÍAS
-- Historia: Como supervisor, quiero saber cuántos días han pasado desde que se registró una calificación de un producto.
-- =====================================================
DROP FUNCTION IF EXISTS edad_de_calificacion;
DELIMITER //
CREATE FUNCTION edad_de_calificacion(p_rate_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_edad INT;
    SELECT DATEDIFF(CURRENT_DATE, created_at) INTO v_edad FROM rates WHERE id = p_rate_id;
    RETURN v_edad;
END //
DELIMITER ;

-- =====================================================
-- 13. CANTIDAD DE PRODUCTOS ÚNICOS ASOCIADOS A UNA EMPRESA
-- Historia: Como operador, quiero una función que, dado un company_id, devuelva la cantidad de productos únicos asociados a esa empresa.
-- =====================================================
DROP FUNCTION IF EXISTS cantidad_productos_unicos_empresa;
DELIMITER //
CREATE FUNCTION cantidad_productos_unicos_empresa(p_company_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(DISTINCT product_id) INTO v_count
    FROM companyproducts
    WHERE company_id = p_company_id;
    RETURN v_count;
END //
DELIMITER ;

-- =====================================================
-- 14. NIVEL DE ACTIVIDAD DE UN CLIENTE SEGÚN SU NÚMERO DE CALIFICACIONES
-- Historia: Como gerente, deseo una función que retorne el nivel de actividad de un cliente (frecuente, esporádico, inactivo), según su número de calificaciones.
-- =====================================================
DROP FUNCTION IF EXISTS nivel_actividad_cliente;
DELIMITER //
CREATE FUNCTION nivel_actividad_cliente(p_customer_id INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_num_calificaciones INT;
    SELECT COUNT(*) INTO v_num_calificaciones FROM rates WHERE customer_id = p_customer_id;

    IF v_num_calificaciones >= 10 THEN
        RETURN 'Frecuente';
    ELSEIF v_num_calificaciones >= 3 THEN
        RETURN 'Esporádico';
    ELSE
        RETURN 'Inactivo';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 15. PRECIO PROMEDIO PONDERADO DE UN PRODUCTO TOMANDO EN CUENTA SU USO EN FAVORITOS
-- Historia: Como administrador, quiero una función que calcule el precio promedio ponderado de un producto, tomando en cuenta su uso en favoritos.
-- =====================================================
DROP FUNCTION IF EXISTS precio_promedio_ponderado_producto;
DELIMITER //
CREATE FUNCTION precio_promedio_ponderado_producto(p_product_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_precio_ponderado DECIMAL(10,2);
    SELECT 
        SUM(cp.price * (1 + (df_count / (SELECT MAX(fav_count) FROM (SELECT COUNT(*) AS fav_count FROM details_favorites GROUP BY product_id) AS max_fav))))
        / SUM(1 + (df_count / (SELECT MAX(fav_count) FROM (SELECT COUNT(*) AS fav_count FROM details_favorites GROUP BY product_id) AS max_fav)))
    INTO v_precio_ponderado
    FROM companyproducts cp
    LEFT JOIN (
        SELECT product_id, COUNT(*) AS df_count
        FROM details_favorites
        GROUP BY product_id
    ) AS fav ON cp.product_id = fav.product_id
    WHERE cp.product_id = p_product_id;

    IF v_precio_ponderado IS NULL THEN
        RETURN 0.00;
    END IF;
    RETURN v_precio_ponderado;
END //
DELIMITER ;

-- =====================================================
-- 16. INDICAR SI UN BENEFICIO ESTÁ ASIGNADO A MÁS DE UNA AUDIENCIA O MEMBRESÍA
-- Historia: Como técnico, quiero una función que me indique si un benefit_id está asignado a más de una audiencia o membresía (valor booleano).
-- =====================================================
DROP FUNCTION IF EXISTS beneficio_compartido;
DELIMITER //
CREATE FUNCTION beneficio_compartido(p_benefit_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT (
        (SELECT COUNT(*) FROM audiencebenefits WHERE benefit_id = p_benefit_id) +
        (SELECT COUNT(*) FROM membershipbenefits WHERE benefit_id = p_benefit_id)
    ) INTO v_count;
    RETURN v_count > 1;
END //
DELIMITER ;

-- =====================================================
-- 17. RETORNAR ÍNDICE DE VARIEDAD BASADO EN NÚMERO DE EMPRESAS Y PRODUCTOS
-- Historia: Como cliente, quiero una función que, dada mi ciudad, retorne un índice de variedad basado en número de empresas y productos.
-- =====================================================
DROP FUNCTION IF EXISTS indice_variedad_ciudad;
DELIMITER //
CREATE FUNCTION indice_variedad_ciudad(p_city_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_num_empresas INT;
    DECLARE v_num_productos INT;
    DECLARE v_indice DECIMAL(5,2);

    SELECT COUNT(DISTINCT id) INTO v_num_empresas FROM companies WHERE city_id = p_city_id AND status = 'active';
    SELECT COUNT(DISTINCT cp.product_id) INTO v_num_productos
    FROM companyproducts cp
    INNER JOIN companies c ON cp.company_id = c.city_id
    WHERE c.city_id = p_city_id AND cp.status = 'available';

    IF v_num_empresas = 0 THEN
        RETURN 0.00;
    END IF;

    SET v_indice = (v_num_productos + v_num_empresas) / 2.0;
    RETURN v_indice;
END //
DELIMITER ;

-- =====================================================
-- 18. EVALUAR SI UN PRODUCTO DEBE SER DESACTIVADO POR TENER BAJA CALIFICACIÓN HISTÓRICA
-- Historia: Como gestor de calidad, deseo una función que evalúe si un producto debe ser desactivado por tener baja calificación histórica.
-- =====================================================
DROP FUNCTION IF EXISTS debe_desactivar_producto_por_calificacion;
DELIMITER //
CREATE FUNCTION debe_desactivar_producto_por_calificacion(p_product_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_avg_rating DECIMAL(2,1);
    SELECT average_rating INTO v_avg_rating FROM products WHERE id = p_product_id;

    IF v_avg_rating IS NULL THEN
        RETURN FALSE; -- No desactivar si no hay calificaciones
    ELSEIF v_avg_rating < 2.5 THEN
        RETURN TRUE; -- Desactivar si el promedio es menor a 2.5
    ELSE
        RETURN FALSE;
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 19. CALCULAR EL ÍNDICE DE POPULARIDAD DE UN PRODUCTO (combinando favoritos y ratings)
-- =====================================================
DROP FUNCTION IF EXISTS indice_popularidad_producto;
DELIMITER //
CREATE FUNCTION indice_popularidad_producto(p_product_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_veces_en_favoritos INT;
    DECLARE v_avg_rating DECIMAL(2,1);
    DECLARE v_indice DECIMAL(5,2);

    SELECT COUNT(*) INTO v_veces_en_favoritos FROM details_favorites WHERE product_id = p_product_id;
    SELECT COALESCE(average_rating, 0) INTO v_avg_rating FROM products WHERE id = p_product_id;

    SET v_indice = (v_veces_en_favoritos * 0.4) + (v_avg_rating * 0.6); -- Ponderación: 40% favoritos, 60% rating
    RETURN v_indice;
END //
DELIMITER ;

-- =====================================================
-- 20. GENERAR UN CÓDIGO ÚNICO BASADO EN EL NOMBRE DEL PRODUCTO Y SU FECHA DE CREACIÓN
-- =====================================================
DROP FUNCTION IF EXISTS generar_codigo_unico_producto;
DELIMITER //
CREATE FUNCTION generar_codigo_unico_producto(p_product_id INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_name VARCHAR(200);
    DECLARE v_created_at TIMESTAMP;
    DECLARE v_codigo VARCHAR(50);

    SELECT name, created_at INTO v_name, v_created_at FROM products WHERE id = p_product_id;

    SET v_codigo = CONCAT(
        UPPER(LEFT(v_name, 3)), -- Tres primeras letras del nombre en mayúsculas
        DATE_FORMAT(v_created_at, '%Y%m%d'), -- Formato de fecha
        LPAD(p_product_id, 5, '0') -- ID del producto con ceros a la izquierda
    );

    RETURN v_codigo;
END //
DELIMITER ;

-- =====================================================
-- FIN DE LAS FUNCIONES DEFINIDAS POR EL USUARIO
-- =====================================================
