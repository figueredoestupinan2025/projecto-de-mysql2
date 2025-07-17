-- =====================================================
-- 20 TRIGGERS PARA PLATAFORMA COMERCIAL
-- Base de datos: plataforma_comercial
-- Descripción: Triggers para validación, auditoría y mantenimiento
-- =====================================================

USE plataforma_comercial;

-- =====================================================
-- 1. TRIGGER: Actualizar updated_at en productos
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_products_update_timestamp
    BEFORE UPDATE ON products
    FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //
DELIMITER ;

-- =====================================================
-- 2. TRIGGER: Registrar log cuando un cliente califica un producto
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_rates_log_insert
    AFTER INSERT ON rates
    FOR EACH ROW
BEGIN
    INSERT INTO log_acciones (
        table_name, 
        action, 
        record_id, 
        description, 
        created_at
    ) VALUES (
        'rates',
        'INSERT',
        NEW.id,
        CONCAT('Cliente ', NEW.customer_id, ' calificó el producto ', NEW.product_id, ' con ', NEW.rating, ' estrellas', 
               CASE WHEN NEW.comment IS NOT NULL THEN CONCAT(': ', NEW.comment) ELSE '' END),
        NOW()
    );
END //
DELIMITER ;

-- =====================================================
-- 3. TRIGGER: Impedir insertar productos sin unidad de medida
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_products_validate_unit
    BEFORE INSERT ON products
    FOR EACH ROW
BEGIN
    IF NEW.unit_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede insertar un producto sin unidad de medida';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 4. TRIGGER: Validar calificaciones no mayores a 5
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_rates_validate_rating
    BEFORE INSERT ON rates
    FOR EACH ROW
BEGIN
    IF NEW.rating > 5.0 OR NEW.rating < 0.0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: La calificación debe estar entre 0 y 5';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 5. TRIGGER: Actualizar estado de membresía cuando vence
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_membership_check_expiry
    BEFORE UPDATE ON membershipperiods
    FOR EACH ROW
BEGIN
    IF NEW.end_date < CURDATE() AND NEW.status = 'active' THEN
        SET NEW.status = 'expired';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 6. TRIGGER: Evitar duplicados de productos por empresa
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_companyproducts_avoid_duplicates
    BEFORE INSERT ON companyproducts
    FOR EACH ROW
BEGIN
    DECLARE duplicate_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO duplicate_count
    FROM companyproducts
    WHERE company_id = NEW.company_id AND product_id = NEW.product_id;
    
    IF duplicate_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Este producto ya está registrado para esta empresa';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 7. TRIGGER: Enviar notificación al añadir un favorito
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_favorites_notification
    AFTER INSERT ON details_favorites
    FOR EACH ROW
BEGIN
    DECLARE customer_id_var INT;
    DECLARE product_name_var VARCHAR(255);
    
    -- Obtener el customer_id de la lista de favoritos
    SELECT customer_id INTO customer_id_var
    FROM favorites
    WHERE id = NEW.favorite_id;
    
    -- Obtener el nombre del producto
    SELECT name INTO product_name_var
    FROM products
    WHERE id = NEW.product_id;
    
    -- Insertar notificación
    INSERT INTO notifications (
        customer_id,
        message,
        type,
        status,
        created_at
    ) VALUES (
        customer_id_var,
        CONCAT('El producto "', product_name_var, '" ha sido añadido a tu lista de favoritos'),
        'favorite',
        'unread',
        NOW()
    );
END //
DELIMITER ;

-- =====================================================
-- 8. TRIGGER: Insertar fila en quality_products tras calificación
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_rates_quality_products_insert
    AFTER INSERT ON rates
    FOR EACH ROW
BEGIN
    -- Solo insertar si la calificación tiene poll_id (es una evaluación de calidad)
    IF NEW.poll_id IS NOT NULL THEN
        INSERT INTO quality_products (
            product_id,
            customer_id,
            poll_id,
            quality_score,
            satisfaction_level,
            recommendation_score,
            created_at
        ) VALUES (
            NEW.product_id,
            NEW.customer_id,
            NEW.poll_id,
            NEW.rating / 5.0, -- Convertir calificación a score (0-1)
            CASE 
                WHEN NEW.rating >= 4.0 THEN 'high'
                WHEN NEW.rating >= 3.0 THEN 'medium'
                ELSE 'low'
            END,
            ROUND(NEW.rating * 2), -- Convertir a escala de 10
            NOW()
        );
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 9. TRIGGER: Eliminar favoritos si se elimina el producto
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_products_delete_favorites
    AFTER DELETE ON products
    FOR EACH ROW
BEGIN
    DELETE FROM details_favorites WHERE product_id = OLD.id;
END //
DELIMITER ;

-- =====================================================
-- 10. TRIGGER: Bloquear modificación de audiencias activas
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_audiences_block_active_modification
    BEFORE UPDATE ON audiences
    FOR EACH ROW
BEGIN
    DECLARE active_customers INT DEFAULT 0;
    
    SELECT COUNT(*) INTO active_customers
    FROM customers
    WHERE audience_id = OLD.id AND status = 'active';
    
    IF active_customers > 0 AND OLD.name != NEW.name THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede modificar una audiencia que tiene clientes activos';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 11. TRIGGER: Recalcular promedio de calidad del producto
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_rates_update_average_rating
    AFTER INSERT ON rates
    FOR EACH ROW
BEGIN
    UPDATE products 
    SET average_rating = (
        SELECT AVG(rating) 
        FROM rates 
        WHERE product_id = NEW.product_id
    )
    WHERE id = NEW.product_id;
END //
DELIMITER ;

-- =====================================================
-- 12A. TRIGGER: Registrar asignación de beneficio a membresía
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_membershipbenefits_log
    AFTER INSERT ON membershipbenefits
    FOR EACH ROW
BEGIN
    DECLARE membership_name VARCHAR(255);
    DECLARE benefit_name VARCHAR(255);
    
    SELECT name INTO membership_name FROM memberships WHERE id = NEW.membership_id;
    SELECT name INTO benefit_name FROM benefits WHERE id = NEW.benefit_id;
    
    INSERT INTO log_acciones (
        table_name,
        action,
        record_id,
        description,
        created_at
    ) VALUES (
        'membershipbenefits',
        'INSERT',
        CONCAT(NEW.membership_id, '-', NEW.benefit_id),
        CONCAT('Beneficio "', benefit_name, '" asignado a la membresía "', membership_name, '"'),
        NOW()
    );
END //
DELIMITER ;

-- =====================================================
-- 12B. TRIGGER: Registrar asignación de beneficio a audiencia
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_audiencebenefits_log
    AFTER INSERT ON audiencebenefits
    FOR EACH ROW
BEGIN
    DECLARE audience_name VARCHAR(255);
    DECLARE benefit_name VARCHAR(255);
    
    SELECT name INTO audience_name FROM audiences WHERE id = NEW.audience_id;
    SELECT name INTO benefit_name FROM benefits WHERE id = NEW.benefit_id;
    
    INSERT INTO log_acciones (
        table_name,
        action,
        record_id,
        description,
        created_at
    ) VALUES (
        'audiencebenefits',
        'INSERT',
        CONCAT(NEW.audience_id, '-', NEW.benefit_id),
        CONCAT('Beneficio "', benefit_name, '" asignado a la audiencia "', audience_name, '"'),
        NOW()
    );
END //
DELIMITER ;

-- =====================================================
-- 13. TRIGGER: Impedir doble calificación por parte del cliente
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_rates_prevent_duplicate
    BEFORE INSERT ON rates
    FOR EACH ROW
BEGIN
    DECLARE existing_rating INT DEFAULT 0;
    
    SELECT COUNT(*) INTO existing_rating
    FROM rates
    WHERE customer_id = NEW.customer_id AND product_id = NEW.product_id;
    
    IF existing_rating > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El cliente ya ha calificado este producto';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 14. TRIGGER: Validar correos duplicados en clientes
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_customers_prevent_duplicate_email
    BEFORE INSERT ON customers
    FOR EACH ROW
BEGIN
    DECLARE existing_email INT DEFAULT 0;
    
    SELECT COUNT(*) INTO existing_email
    FROM customers
    WHERE email = NEW.email;
    
    IF existing_email > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Ya existe un cliente con este email';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 15. TRIGGER: Eliminar detalles de favoritos huérfanos
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_favorites_delete_details
    AFTER DELETE ON favorites
    FOR EACH ROW
BEGIN
    DELETE FROM details_favorites WHERE favorite_id = OLD.id;
END //
DELIMITER ;

-- =====================================================
-- 16. TRIGGER: Actualizar updated_at en companies
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_companies_update_timestamp
    BEFORE UPDATE ON companies
    FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //
DELIMITER ;

-- =====================================================
-- 17. TRIGGER: Impedir borrar ciudad si hay empresas activas
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_cities_prevent_delete_with_companies
    BEFORE DELETE ON citiesormunicipalities
    FOR EACH ROW
BEGIN
    DECLARE active_companies INT DEFAULT 0;
    
    SELECT COUNT(*) INTO active_companies
    FROM companies
    WHERE city_id = OLD.id AND status = 'active';
    
    IF active_companies > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede eliminar una ciudad que tiene empresas activas';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 18. TRIGGER: Registrar cambios de estado en encuestas
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_polls_log_status_change
    AFTER UPDATE ON polls
    FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO log_acciones (
            table_name,
            action,
            record_id,
            description,
            created_at
        ) VALUES (
            'polls',
            'UPDATE',
            NEW.id,
            CONCAT('La encuesta "', NEW.title, '" cambió de estado de "', OLD.status, '" a "', NEW.status, '"'),
            NOW()
        );
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 19. TRIGGER: Sincronizar rates y quality_products (al actualizar rating)
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_rates_sync_quality_products
    AFTER UPDATE ON rates
    FOR EACH ROW
BEGIN
    -- Actualizar quality_products si existe el registro
    IF NEW.poll_id IS NOT NULL THEN
        UPDATE quality_products
        SET 
            quality_score = NEW.rating / 5.0,
            satisfaction_level = CASE 
                WHEN NEW.rating >= 4.0 THEN 'high'
                WHEN NEW.rating >= 3.0 THEN 'medium'
                ELSE 'low'
            END,
            recommendation_score = ROUND(NEW.rating * 2),
            updated_at = NOW()
        WHERE product_id = NEW.product_id 
          AND customer_id = NEW.customer_id 
          AND poll_id = NEW.poll_id;
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 20. TRIGGER: Eliminar productos sin relación a empresas
-- =====================================================
DELIMITER //
CREATE TRIGGER trg_companyproducts_delete_orphan_products
    AFTER DELETE ON companyproducts
    FOR EACH ROW
BEGIN
    DECLARE remaining_relations INT DEFAULT 0;
    
    -- Verificar si el producto tiene otras relaciones con empresas
    SELECT COUNT(*) INTO remaining_relations
    FROM companyproducts
    WHERE product_id = OLD.product_id;
    
    -- Si no tiene más relaciones, eliminar el producto
    IF remaining_relations = 0 THEN
        DELETE FROM products WHERE id = OLD.product_id;
    END IF;
END //
DELIMITER ;

-- =====================================================
-- VERIFICACIÓN DE TRIGGERS CREADOS
-- =====================================================
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    TRIGGER_SCHEMA
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'plataforma_comercial'
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;
