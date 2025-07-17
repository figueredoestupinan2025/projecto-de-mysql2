-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS PARA PLATAFORMA COMERCIAL
-- Total: 20 procedimientos almacenados
-- =====================================================

USE plataforma_comercial;

DELIMITER //

-- =====================================================
-- 1. REGISTRAR NUEVA CALIFICACIÓN Y ACTUALIZAR PROMEDIO
-- =====================================================
CREATE PROCEDURE registrar_calificacion_y_actualizar_promedio(
    IN p_product_id INT,
    IN p_customer_id INT,
    IN p_rating DECIMAL(2,1),
    IN p_company_id INT
)
BEGIN
    DECLARE v_avg_rating DECIMAL(2,1);
    
    -- Insertar nueva calificación
    INSERT INTO rates (customer_id, product_id, company_id, rating, created_at)
    VALUES (p_customer_id, p_product_id, p_company_id, p_rating, NOW());
    
    -- Calcular nuevo promedio
    SELECT AVG(rating) INTO v_avg_rating
    FROM rates
    WHERE product_id = p_product_id;
    
    -- Actualizar promedio en la tabla productos
    UPDATE products
    SET average_rating = v_avg_rating
    WHERE id = p_product_id;
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Calificación registrada para producto ', p_product_id, ' por cliente ', p_customer_id), NOW());
    
END //

-- =====================================================
-- 2. INSERTAR EMPRESA Y ASOCIAR PRODUCTOS POR DEFECTO
-- =====================================================
CREATE PROCEDURE insertar_empresa_y_asociar_productos(
    IN p_name VARCHAR(100),
    IN p_business_name VARCHAR(100),
    IN p_tax_id VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_address VARCHAR(255),
    IN p_city_id INT,
    IN p_company_type_id INT,
    IN p_audience_id INT,
    IN p_status ENUM('active', 'inactive', 'pending')
)
BEGIN
    DECLARE v_company_id INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    
    -- Cursor para productos por defecto
    DECLARE product_cursor CURSOR FOR 
        SELECT id FROM products WHERE id IN (1000, 1001) AND status = 'active';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Insertar nueva empresa
    INSERT INTO companies (name, business_name, tax_id, email, phone, address, city_id, company_type_id, audience_id, status, created_at)
    VALUES (p_name, p_business_name, p_tax_id, p_email, p_phone, p_address, p_city_id, p_company_type_id, p_audience_id, p_status, NOW());
    
    SET v_company_id = LAST_INSERT_ID();
    
    -- Asociar productos por defecto
    OPEN product_cursor;
    read_loop: LOOP
        FETCH product_cursor INTO v_product_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        INSERT INTO companyproducts (company_id, product_id, price, stock_quantity, unit_id, status)
        VALUES (v_company_id, v_product_id, 99.99, 10, 8, 'available');
    END LOOP;
    CLOSE product_cursor;
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Empresa creada: ', p_name, ' (ID: ', v_company_id, ')'), NOW());
    
END //

-- =====================================================
-- 3. AÑADIR PRODUCTO FAVORITO VALIDANDO DUPLICADOS
-- =====================================================
CREATE PROCEDURE añadir_producto_favorito_validando_duplicados(
    IN p_customer_id INT,
    IN p_product_id INT
)
BEGIN
    DECLARE v_favorite_id INT;
    DECLARE v_exists INT DEFAULT 0;
    
    -- Obtener ID de la lista de favoritos del cliente
    SELECT id INTO v_favorite_id
    FROM favorites
    WHERE customer_id = p_customer_id
    LIMIT 1;
    
    -- Si no existe lista de favoritos, crearla
    IF v_favorite_id IS NULL THEN
        INSERT INTO favorites (customer_id, name, created_at)
        VALUES (p_customer_id, 'Mis Favoritos', NOW());
        SET v_favorite_id = LAST_INSERT_ID();
    END IF;
    
    -- Verificar si el producto ya está en favoritos
    SELECT COUNT(*) INTO v_exists
    FROM details_favorites
    WHERE favorite_id = v_favorite_id AND product_id = p_product_id;
    
    -- Si no existe, añadirlo
    IF v_exists = 0 THEN
        INSERT INTO details_favorites (favorite_id, product_id, added_date)
        VALUES (v_favorite_id, p_product_id, NOW());
        
        -- Log de la acción
        INSERT INTO log_acciones (description, created_at)
        VALUES (CONCAT('Producto ', p_product_id, ' añadido a favoritos del cliente ', p_customer_id), NOW());
    END IF;
    
END //

-- =====================================================
-- 4. GENERAR RESUMEN MENSUAL DE CALIFICACIONES POR EMPRESA
-- =====================================================
CREATE PROCEDURE generar_resumen_mensual_calificaciones_empresa(
    IN p_mes DATE
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_company_id INT;
    DECLARE v_avg_rating DECIMAL(2,1);
    DECLARE v_total_ratings INT;
    
    -- Cursor para empresas
    DECLARE company_cursor CURSOR FOR 
        SELECT DISTINCT r.company_id
        FROM rates r
        WHERE DATE_FORMAT(r.created_at, '%Y-%m') = DATE_FORMAT(p_mes, '%Y-%m');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN company_cursor;
    read_loop: LOOP
        FETCH company_cursor INTO v_company_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calcular promedio y total de calificaciones
        SELECT AVG(rating), COUNT(*) INTO v_avg_rating, v_total_ratings
        FROM rates
        WHERE company_id = v_company_id 
        AND DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(p_mes, '%Y-%m');
        
        -- Insertar o actualizar resumen
        INSERT INTO resumen_calificaciones_empresa (company_id, mes, promedio_rating, total_calificaciones)
        VALUES (v_company_id, p_mes, v_avg_rating, v_total_ratings)
        ON DUPLICATE KEY UPDATE
            promedio_rating = v_avg_rating,
            total_calificaciones = v_total_ratings;
            
    END LOOP;
    CLOSE company_cursor;
    
END //

-- =====================================================
-- 5. CALCULAR BENEFICIOS ACTIVOS POR MEMBRESÍA
-- =====================================================
CREATE PROCEDURE calcular_beneficios_activos_por_membresia(
    IN p_membership_id INT
)
BEGIN
    SELECT 
        m.name AS membership_name,
        b.name AS benefit_name,
        b.description AS benefit_description,
        b.type AS benefit_type,
        b.value AS benefit_value,
        b.status AS benefit_status
    FROM memberships m
    JOIN membershipbenefits mb ON m.id = mb.membership_id
    JOIN benefits b ON mb.benefit_id = b.id
    WHERE m.id = p_membership_id 
    AND b.status = 'active'
    AND m.status = 'active';
    
END //

-- =====================================================
-- 6. ELIMINAR PRODUCTOS HUÉRFANOS
-- =====================================================
CREATE PROCEDURE eliminar_productos_huerfanos()
BEGIN
    DECLARE v_deleted_count INT DEFAULT 0;
    
    -- Eliminar productos sin categoría o unidad
    DELETE FROM products 
    WHERE category_id IS NULL 
    OR unit_id IS NULL 
    OR status = 'inactive';
    
    SET v_deleted_count = ROW_COUNT();
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Productos huérfanos eliminados: ', v_deleted_count), NOW());
    
END //

-- =====================================================
-- 7. ACTUALIZAR PRECIOS DE PRODUCTOS POR CATEGORÍA
-- =====================================================
CREATE PROCEDURE actualizar_precios_por_categoria(
    IN p_category_id INT,
    IN p_factor DECIMAL(4,2)
)
BEGIN
    DECLARE v_updated_count INT DEFAULT 0;
    
    -- Actualizar precios
    UPDATE companyproducts cp
    JOIN products p ON cp.product_id = p.id
    SET cp.price = cp.price * p_factor
    WHERE p.category_id = p_category_id;
    
    SET v_updated_count = ROW_COUNT();
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Precios actualizados para categoría ', p_category_id, '. Productos afectados: ', v_updated_count), NOW());
    
END //

-- =====================================================
-- 8. VALIDAR INCONSISTENCIA ENTRE RATES Y QUALITY_PRODUCTS
-- =====================================================
CREATE PROCEDURE validar_inconsistencia_rates_quality_products()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_rate_id INT;
    DECLARE v_product_id INT;
    DECLARE v_customer_id INT;
    DECLARE v_quality_exists INT;
    
    -- Cursor para calificaciones sin entrada en quality_products
    DECLARE rate_cursor CURSOR FOR 
        SELECT r.id, r.product_id, r.customer_id
        FROM rates r
        LEFT JOIN quality_products qp ON r.product_id = qp.product_id AND r.customer_id = qp.customer_id
        WHERE qp.product_id IS NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN rate_cursor;
    read_loop: LOOP
        FETCH rate_cursor INTO v_rate_id, v_product_id, v_customer_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Registrar inconsistencia
        INSERT INTO errores_log (error_type, description, error_date)
        VALUES ('inconsistencia', 
                CONCAT('Rate ID ', v_rate_id, ' sin entrada en quality_products para producto ', v_product_id, ' y cliente ', v_customer_id), 
                NOW());
                
    END LOOP;
    CLOSE rate_cursor;
    
END //

-- =====================================================
-- 9. ASIGNAR BENEFICIOS A NUEVAS AUDIENCIAS
-- =====================================================
CREATE PROCEDURE asignar_beneficio_a_audiencia(
    IN p_audience_id INT,
    IN p_benefit_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    -- Verificar si la asignación ya existe
    SELECT COUNT(*) INTO v_exists
    FROM audiencebenefits
    WHERE audience_id = p_audience_id AND benefit_id = p_benefit_id;
    
    -- Si no existe, crearla
    IF v_exists = 0 THEN
        INSERT INTO audiencebenefits (audience_id, benefit_id)
        VALUES (p_audience_id, p_benefit_id);
        
        -- Log de la acción
        INSERT INTO log_acciones (description, created_at)
        VALUES (CONCAT('Beneficio ', p_benefit_id, ' asignado a audiencia ', p_audience_id), NOW());
    END IF;
    
END //

-- =====================================================
-- 10. ACTIVAR PLANES DE MEMBRESÍA VENCIDOS CON PAGO CONFIRMADO
-- =====================================================
CREATE PROCEDURE activar_membresias_vencidas_con_pago()
BEGIN
    DECLARE v_updated_count INT DEFAULT 0;
    
    -- Extender membresías vencidas con pago confirmado por 1 año
    UPDATE membershipperiods
    SET status = 'active',
        start_date = CURDATE(),
        end_date = DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
    WHERE status = 'expired' 
    AND payment_confirmed = TRUE
    AND end_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY); -- Solo las vencidas en los últimos 30 días
    
    SET v_updated_count = ROW_COUNT();
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Membresías reactivadas: ', v_updated_count), NOW());
    
END //

-- =====================================================
-- 11. LISTAR PRODUCTOS FAVORITOS DEL CLIENTE CON SU CALIFICACIÓN
-- =====================================================
CREATE PROCEDURE listar_favoritos_con_calificacion(
    IN p_customer_id INT
)
BEGIN
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        p.description AS product_description,
        df.added_date,
        COALESCE(r.rating, 0) AS my_rating,
        p.average_rating
    FROM favorites f
    JOIN details_favorites df ON f.id = df.favorite_id
    JOIN products p ON df.product_id = p.id
    LEFT JOIN rates r ON p.id = r.product_id AND r.customer_id = p_customer_id
    WHERE f.customer_id = p_customer_id
    ORDER BY df.added_date DESC;
    
END //

-- =====================================================
-- 12. REGISTRAR ENCUESTA Y SUS PREGUNTAS ASOCIADAS
-- =====================================================
CREATE PROCEDURE registrar_encuesta_y_preguntas(
    IN p_title VARCHAR(200),
    IN p_description TEXT,
    IN p_type ENUM('product', 'service', 'general'),
    IN p_status ENUM('active', 'inactive', 'draft'),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_questions TEXT
)
BEGIN
    DECLARE v_poll_id INT;
    DECLARE v_question TEXT;
    DECLARE v_question_type VARCHAR(50);
    DECLARE v_pos INT;
    DECLARE v_separator_pos INT;
    DECLARE v_questions_remaining TEXT;
    
    -- Crear la encuesta
    INSERT INTO polls (title, description, type, status, start_date, end_date, created_at)
    VALUES (p_title, p_description, p_type, p_status, p_start_date, p_end_date, NOW());
    
    SET v_poll_id = LAST_INSERT_ID();
    SET v_questions_remaining = p_questions;
    
    -- Procesar preguntas (formato: "pregunta1;tipo1|pregunta2;tipo2|...")
    WHILE LENGTH(v_questions_remaining) > 0 DO
        -- Encontrar el separador de pregunta
        SET v_pos = LOCATE('|', v_questions_remaining);
        
        IF v_pos = 0 THEN
            SET v_question = v_questions_remaining;
            SET v_questions_remaining = '';
        ELSE
            SET v_question = SUBSTRING(v_questions_remaining, 1, v_pos - 1);
            SET v_questions_remaining = SUBSTRING(v_questions_remaining, v_pos + 1);
        END IF;
        
        -- Separar pregunta y tipo
        SET v_separator_pos = LOCATE(';', v_question);
        IF v_separator_pos > 0 THEN
            SET v_question_type = SUBSTRING(v_question, v_separator_pos + 1);
            SET v_question = SUBSTRING(v_question, 1, v_separator_pos - 1);
            
            -- Insertar pregunta
            INSERT INTO poll_questions (poll_id, question_text, question_type, created_at)
            VALUES (v_poll_id, v_question, v_question_type, NOW());
        END IF;
        
    END WHILE;
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Encuesta creada: ', p_title, ' (ID: ', v_poll_id, ')'), NOW());
    
END //

-- =====================================================
-- 13. ELIMINAR FAVORITOS ANTIGUOS SIN CALIFICACIONES
-- =====================================================
CREATE PROCEDURE eliminar_favoritos_antiguos_sin_calificaciones()
BEGIN
    DECLARE v_deleted_count INT DEFAULT 0;
    
    -- Eliminar favoritos anteriores a 2 años sin calificaciones
    DELETE df FROM details_favorites df
    JOIN favorites f ON df.favorite_id = f.id
    LEFT JOIN rates r ON df.product_id = r.product_id AND f.customer_id = r.customer_id
    WHERE df.added_date < DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
    AND r.id IS NULL;
    
    SET v_deleted_count = ROW_COUNT();
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Favoritos antiguos eliminados: ', v_deleted_count), NOW());
    
END //

-- =====================================================
-- 14. ASOCIAR BENEFICIOS AUTOMÁTICAMENTE POR AUDIENCIA
-- =====================================================
CREATE PROCEDURE asociar_beneficios_por_audiencia(
    IN p_audience_id INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_benefit_id INT;
    DECLARE v_exists INT;
    
    -- Cursor para beneficios activos
    DECLARE benefit_cursor CURSOR FOR 
        SELECT id FROM benefits WHERE status = 'active';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN benefit_cursor;
    read_loop: LOOP
        FETCH benefit_cursor INTO v_benefit_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar si ya existe la asignación
        SELECT COUNT(*) INTO v_exists
        FROM audiencebenefits
        WHERE audience_id = p_audience_id AND benefit_id = v_benefit_id;
        
        -- Si no existe, crearla
        IF v_exists = 0 THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id)
            VALUES (p_audience_id, v_benefit_id);
        END IF;
        
    END LOOP;
    CLOSE benefit_cursor;
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Beneficios auto-asignados a audiencia ', p_audience_id), NOW());
    
END //

-- =====================================================
-- 15. TRIGGER PARA HISTORIAL DE CAMBIOS DE PRECIO
-- =====================================================
CREATE TRIGGER precio_historial_trigger
AFTER UPDATE ON companyproducts
FOR EACH ROW
BEGIN
    IF OLD.price != NEW.price THEN
        INSERT INTO historial_precios (product_id, company_id, old_price, new_price, change_date)
        VALUES (NEW.product_id, NEW.company_id, OLD.price, NEW.price, NOW());
    END IF;
END //

-- =====================================================
-- 16. REGISTRAR ENCUESTA ACTIVA AUTOMÁTICAMENTE
-- =====================================================
CREATE PROCEDURE registrar_encuesta_activa_automatica(
    IN p_title VARCHAR(200),
    IN p_description TEXT,
    IN p_type ENUM('product', 'service', 'general')
)
BEGIN
    DECLARE v_poll_id INT;
    
    -- Crear encuesta activa por defecto
    INSERT INTO polls (title, description, type, status, start_date, end_date, created_at)
    VALUES (p_title, p_description, p_type, 'active', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), NOW());
    
    SET v_poll_id = LAST_INSERT_ID();
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES (CONCAT('Encuesta activa automática creada: ', p_title, ' (ID: ', v_poll_id, ')'), NOW());
    
END //

-- =====================================================
-- 17. ACTUALIZAR UNIDAD DE MEDIDA DE PRODUCTOS SIN AFECTAR VENTAS
-- =====================================================
CREATE PROCEDURE actualizar_unidad_producto_sin_ventas(
    IN p_product_id INT,
    IN p_new_unit_id INT
)
BEGIN
    DECLARE v_has_sales INT DEFAULT 0;
    
    -- Verificar si el producto tiene ventas (asumiendo que rates representa ventas/uso)
    SELECT COUNT(*) INTO v_has_sales
    FROM rates
    WHERE product_id = p_product_id;
    
    -- Si no tiene ventas, actualizar unidad
    IF v_has_sales = 0 THEN
        UPDATE products
        SET unit_id = p_new_unit_id
        WHERE id = p_product_id;
        
        -- También actualizar en companyproducts
        UPDATE companyproducts
        SET unit_id = p_new_unit_id
        WHERE product_id = p_product_id;
        
        -- Log de la acción
        INSERT INTO log_acciones (description, created_at)
        VALUES (CONCAT('Unidad actualizada para producto ', p_product_id, ' a unidad ', p_new_unit_id), NOW());
    ELSE
        -- Log de error
        INSERT INTO errores_log (error_type, description, error_date)
        VALUES ('unit_update_blocked', 
                CONCAT('No se puede actualizar unidad del producto ', p_product_id, ' porque tiene ventas'), 
                NOW());
    END IF;
    
END //

-- =====================================================
-- 18. RECALCULAR PROMEDIOS DE CALIDAD SEMANALMENTE
-- =====================================================
CREATE PROCEDURE recalcular_promedios_calidad_semanal()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_avg_quality DECIMAL(3,2);
    DECLARE v_avg_rating DECIMAL(2,1);
    
    -- Cursor para productos con datos de calidad
    DECLARE product_cursor CURSOR FOR 
        SELECT DISTINCT product_id FROM quality_products;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN product_cursor;
    read_loop: LOOP
        FETCH product_cursor INTO v_product_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calcular promedio de calidad
        SELECT AVG(quality_score) INTO v_avg_quality
        FROM quality_products
        WHERE product_id = v_product_id;
        
        -- Convertir a escala de 1-5 para average_rating
        SET v_avg_rating = v_avg_quality * 5;
        
        -- Actualizar promedio en productos
        UPDATE products
        SET average_rating = v_avg_rating
        WHERE id = v_product_id;
        
    END LOOP;
    CLOSE product_cursor;
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES ('Promedios de calidad recalculados semanalmente', NOW());
    
END //

-- =====================================================
-- 19. VALIDAR CLAVES FORÁNEAS ENTRE CALIFICACIONES Y ENCUESTAS
-- =====================================================
CREATE PROCEDURE validar_claves_foraneas_rates_polls()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_rate_id INT;
    DECLARE v_poll_id INT;
    DECLARE v_poll_exists INT;
    
    -- Cursor para calificaciones con poll_id
    DECLARE rate_cursor CURSOR FOR 
        SELECT id, poll_id FROM rates WHERE poll_id IS NOT NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN rate_cursor;
    read_loop: LOOP
        FETCH rate_cursor INTO v_rate_id, v_poll_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar si existe la encuesta
        SELECT COUNT(*) INTO v_poll_exists
        FROM polls
        WHERE id = v_poll_id;
        
        -- Si no existe, registrar error
        IF v_poll_exists = 0 THEN
            INSERT INTO errores_log (error_type, description, error_date)
            VALUES ('foreign_key_error', 
                    CONCAT('Rate ID ', v_rate_id, ' referencia poll_id inexistente: ', v_poll_id), 
                    NOW());
        END IF;
        
    END LOOP;
    CLOSE rate_cursor;
    
END //

-- =====================================================
-- 20. GENERAR EL TOP 10 DE PRODUCTOS MÁS CALIFICADOS POR CIUDAD
-- =====================================================
CREATE PROCEDURE generar_top_productos_calificados_por_ciudad()
BEGIN
    -- Limpiar tabla de resultados
    DELETE FROM top_products_by_city;
    
    -- Generar ranking
    INSERT INTO top_products_by_city (city_id, city_name, product_id, product_name, avg_rating, total_ratings, rank_in_city)
    SELECT 
        city_id,
        city_name,
        product_id,
        product_name,
        avg_rating,
        total_ratings,
        ROW_NUMBER() OVER (PARTITION BY city_id ORDER BY avg_rating DESC, total_ratings DESC) as rank_in_city
    FROM (
        SELECT 
            c.id as city_id,
            c.name as city_name,
            p.id as product_id,
            p.name as product_name,
            AVG(r.rating) as avg_rating,
            COUNT(r.rating) as total_ratings
        FROM citiesormunicipalities c
        JOIN customers cust ON c.id = cust.city_id
        JOIN rates r ON cust.id = r.customer_id
        JOIN products p ON r.product_id = p.id
        GROUP BY c.id, c.name, p.id, p.name
        HAVING COUNT(r.rating) >= 1
    ) ranked_products
    WHERE rank_in_city <= 10;
    
    -- Log de la acción
    INSERT INTO log_acciones (description, created_at)
    VALUES ('Top 10 productos por ciudad generado', NOW());
    
END //

DELIMITER ;

-- =====================================================
-- EVENTOS PROGRAMADOS (OPCIONAL)
-- =====================================================

-- Evento para recalcular promedios semanalmente
DROP EVENT IF EXISTS recalcular_promedios_semanal;
CREATE EVENT recalcular_promedios_semanal
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
    CALL recalcular_promedios_calidad_semanal();

-- Evento para generar top productos mensualmente
DROP EVENT IF EXISTS generar_top_productos_mensual;
CREATE EVENT generar_top_productos_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
    CALL generar_top_productos_calificados_por_ciudad();

-- Evento para limpiar favoritos antiguos cada 6 meses
DROP EVENT IF EXISTS limpiar_favoritos_antiguos;
CREATE EVENT limpiar_favoritos_antiguos
ON SCHEDULE EVERY 6 MONTH
STARTS CURRENT_TIMESTAMP
DO
    CALL eliminar_favoritos_antiguos_sin_calificaciones();

-- =====================================================
-- TABLAS AUXILIARES REQUERIDAS
-- =====================================================

-- Tabla para log de acciones
CREATE TABLE IF NOT EXISTS log_acciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para notificaciones
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para quality_products
CREATE TABLE IF NOT EXISTS quality_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    poll_id INT,
    quality_score DECIMAL(3,2) DEFAULT 0.00,
    satisfaction_level ENUM('very_low', 'low', 'medium', 'high', 'very_high') DEFAULT 'medium',
    recommendation_score INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE SET NULL
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_rates_product_customer ON rates(product_id, customer_id);
CREATE INDEX IF NOT EXISTS idx_rates_created_at ON rates(created_at);
CREATE INDEX IF NOT EXISTS idx_companyproducts_category ON companyproducts(product_id);
CREATE INDEX IF NOT EXISTS idx_favorites_customer ON favorites(customer_id);
CREATE INDEX IF NOT EXISTS idx_membershipperiods_status ON membershipperiods(status, payment_confirmed);

-- =====================================================
-- FIN DE PROCEDIMIENTOS ALMACENADOS
-- =====================================================
