-- =====================================================
-- PROYECTO: PLATAFORMA DE COMERCIALIZACIÓN DIGITAL MULTINIVEL
-- ARCHIVO: Events (Eventos Programados)
-- DESCRIPCIÓN: Definición de eventos programados para tareas periódicas
-- =====================================================

USE plataforma_comercial;

-- Habilitar el planificador de eventos si no está habilitado
SET GLOBAL event_scheduler = ON;

-- =====================================================
-- PROCEDIMIENTOS AUXILIARES PARA EVENTOS (Si no existen)
-- =====================================================

-- Procedimiento para Evento 1: Borrar productos sin actividad
DROP PROCEDURE IF EXISTS pr_borrar_productos_sin_actividad;
DELIMITER //
CREATE PROCEDURE pr_borrar_productos_sin_actividad()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_borrar_productos_sin_actividad');

    DELETE p
    FROM products p
    LEFT JOIN rates r ON p.id = r.product_id
    LEFT JOIN details_favorites df ON p.id = df.product_id
    LEFT JOIN companyproducts cp ON p.id = cp.product_id
    WHERE r.id IS NULL
      AND df.id IS NULL
      AND cp.id IS NULL
      AND p.created_at < NOW() - INTERVAL 6 MONTH; -- Productos creados hace más de 6 meses sin actividad

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_borrar_productos_sin_actividad. Productos eliminados: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 2: Recalcular el promedio de calificaciones semanalmente
DROP PROCEDURE IF EXISTS pr_recalcular_promedio_calificaciones;
DELIMITER //
CREATE PROCEDURE pr_recalcular_promedio_calificaciones()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_recalcular_promedio_calificaciones');

    UPDATE products p
    SET p.average_rating = (
        SELECT AVG(r.rating)
        FROM rates r
        WHERE r.product_id = p.id
    )
    WHERE EXISTS (SELECT 1 FROM rates r2 WHERE r2.product_id = p.id);

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Finalizado pr_recalcular_promedio_calificaciones');
END //
DELIMITER ;

-- Procedimiento para Evento 3: Actualizar precios según inflación mensual
DROP PROCEDURE IF EXISTS pr_actualizar_precios_inflacion;
DELIMITER //
CREATE PROCEDURE pr_actualizar_precios_inflacion()
BEGIN
    DECLARE inflation_rate_val DECIMAL(5,4);
    
    -- Obtener la tasa de inflación del mes actual o más reciente
    SELECT inflation_rate INTO inflation_rate_val
    FROM inflacion_indice
    WHERE month_year = DATE_FORMAT(CURDATE(), '%Y-%m-01')
    ORDER BY month_year DESC
    LIMIT 1;

    IF inflation_rate_val IS NULL THEN
        -- Si no hay una tasa específica para el mes, usar un valor por defecto o loguear
        SET inflation_rate_val = 0.005; -- Ejemplo: 0.5% por defecto
        INSERT INTO log_acciones (action_type, description)
        VALUES ('Evento Programado', 'No se encontró tasa de inflación para el mes actual. Usando 0.5% por defecto.');
    END IF;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Iniciando pr_actualizar_precios_inflacion con tasa: ', inflation_rate_val * 100, '%'));

    UPDATE companyproducts
    SET price = price * (1 + inflation_rate_val)
    WHERE status = 'available';

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_actualizar_precios_inflacion. Precios actualizados: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 4: Crear backups lógicos diariamente
DROP PROCEDURE IF EXISTS pr_crear_backup_productos;
DELIMITER //
CREATE PROCEDURE pr_crear_backup_productos()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_crear_backup_productos');

    INSERT INTO products_backup (id, name, description, category_id, unit_id, image_url, status, average_rating, created_at, updated_at)
    SELECT id, name, description, category_id, unit_id, image_url, status, average_rating, created_at, updated_at
    FROM products;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_crear_backup_productos. Productos respaldados: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 5: Notificar sobre productos favoritos sin calificar
DROP PROCEDURE IF EXISTS pr_notificar_favoritos_sin_calificar;
DELIMITER //
CREATE PROCEDURE pr_notificar_favoritos_sin_calificar()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_notificar_favoritos_sin_calificar');

    INSERT INTO notifications (customer_id, message)
    SELECT DISTINCT f.customer_id,
                    CONCAT('¡Tienes productos en tu lista de favoritos (', f.name, ') que aún no has calificado! Ayúdanos a mejorar.')
    FROM favorites f
    INNER JOIN details_favorites df ON f.id = df.favorite_id
    LEFT JOIN rates r ON df.product_id = r.product_id AND f.customer_id = r.customer_id
    WHERE r.id IS NULL
    AND df.added_date < NOW() - INTERVAL 7 DAY -- Solo notificar si se añadió hace más de 7 días
    AND NOT EXISTS ( -- Evitar notificaciones repetidas para el mismo producto/cliente en el mismo día
        SELECT 1 FROM notifications n
        WHERE n.customer_id = f.customer_id
        AND n.message LIKE CONCAT('%', p.name, '%aún no has calificado%')
        AND n.created_at >= CURDATE()
    );

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_notificar_favoritos_sin_calificar. Notificaciones enviadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 6: Revisar inconsistencias entre empresa y productos
DROP PROCEDURE IF EXISTS pr_revisar_inconsistencias_empresa_producto;
DELIMITER //
CREATE PROCEDURE pr_revisar_inconsistencias_empresa_producto()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_revisar_inconsistencias_empresa_producto');

    -- Inconsistencia 1: Empresas sin productos asociados
    INSERT INTO errores_log (error_type, description)
    SELECT 'Empresa sin productos', CONCAT('La empresa "', c.name, '" (ID: ', c.id, ') no tiene productos asociados.')
    FROM companies c
    LEFT JOIN companyproducts cp ON c.id = cp.company_id
    WHERE cp.company_id IS NULL
    AND c.status = 'active'
    AND NOT EXISTS (SELECT 1 FROM errores_log el WHERE el.error_type = 'Empresa sin productos' AND el.description LIKE CONCAT('%ID: ', c.id, '%') AND el.error_date >= CURDATE());

    -- Inconsistencia 2: Productos sin empresa asociada (en companyproducts)
    INSERT INTO errores_log (error_type, description)
    SELECT 'Producto sin empresa', CONCAT('El producto "', p.name, '" (ID: ', p.id, ') no está asociado a ninguna empresa en companyproducts.')
    FROM products p
    LEFT JOIN companyproducts cp ON p.id = cp.product_id
    WHERE cp.product_id IS NULL
    AND p.status = 'active'
    AND NOT EXISTS (SELECT 1 FROM errores_log el WHERE el.error_type = 'Producto sin empresa' AND el.description LIKE CONCAT('%ID: ', p.id, '%') AND el.error_date >= CURDATE());

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Finalizado pr_revisar_inconsistencias_empresa_producto');
END //
DELIMITER ;

-- Procedimiento para Evento 7: Archivar membresías vencidas diariamente
DROP PROCEDURE IF EXISTS pr_archivar_membresias_vencidas;
DELIMITER //
CREATE PROCEDURE pr_archivar_membresias_vencidas()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_archivar_membresias_vencidas');

    UPDATE membershipperiods
    SET status = 'expired'
    WHERE end_date < CURDATE() AND status = 'active';

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_archivar_membresias_vencidas. Membresías actualizadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 8: Notificar beneficios nuevos a usuarios semanalmente
DROP PROCEDURE IF EXISTS pr_notificar_beneficios_nuevos;
DELIMITER //
CREATE PROCEDURE pr_notificar_beneficios_nuevos()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_notificar_beneficios_nuevos');

    INSERT INTO notifications (customer_id, message)
    SELECT DISTINCT mp.customer_id,
                    CONCAT('¡Descubre un nuevo beneficio disponible: "', b.name, '" (', b.description, ')!')
    FROM benefits b
    INNER JOIN membershipbenefits mb ON b.id = mb.benefit_id
    INNER JOIN membershipperiods mp ON mb.membership_id = mp.membership_id
    WHERE b.created_at >= NOW() - INTERVAL 7 DAY -- Beneficios creados en la última semana
    AND mp.status = 'active' AND mp.end_date >= CURDATE() -- Clientes con membresía activa
    AND NOT EXISTS ( -- Evitar notificaciones repetidas para el mismo cliente/beneficio en el mismo día
        SELECT 1 FROM notifications n
        WHERE n.customer_id = mp.customer_id
        AND n.message LIKE CONCAT('%', b.name, '%nuevo beneficio disponible%')
        AND n.created_at >= CURDATE()
    );

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_notificar_beneficios_nuevos. Notificaciones enviadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 9: Calcular cantidad de favoritos por cliente mensualmente
DROP PROCEDURE IF EXISTS pr_calcular_favoritos_por_cliente_mensual;
DELIMITER //
CREATE PROCEDURE pr_calcular_favoritos_por_cliente_mensual()
BEGIN
    DECLARE current_month_start DATE;
    SET current_month_start = DATE_FORMAT(CURDATE(), '%Y-%m-01');

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Iniciando pr_calcular_favoritos_por_cliente_mensual para ', current_month_start));

    INSERT INTO favoritos_resumen (customer_id, total_favoritos, mes_resumen)
    SELECT f.customer_id, COUNT(df.id), current_month_start
    FROM favorites f
    INNER JOIN details_favorites df ON f.id = df.favorite_id
    GROUP BY f.customer_id
    ON DUPLICATE KEY UPDATE
        total_favoritos = VALUES(total_favoritos),
        created_at = CURRENT_TIMESTAMP;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_calcular_favoritos_por_cliente_mensual. Resúmenes actualizados: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 10: Validar claves foráneas semanalmente
DROP PROCEDURE IF EXISTS pr_validar_claves_foraneas;
DELIMITER //
CREATE PROCEDURE pr_validar_claves_foraneas()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_validar_claves_foraneas');

    -- Ejemplo de validación: rates.product_id vs products.id
    INSERT INTO errores_log (error_type, description)
    SELECT 'FK Inconsistencia', CONCAT('rates.product_id (', r.product_id, ') no existe en products.id. Rate ID: ', r.id)
    FROM rates r
    LEFT JOIN products p ON r.product_id = p.id
    WHERE p.id IS NULL
    AND NOT EXISTS (SELECT 1 FROM errores_log el WHERE el.error_type = 'FK Inconsistencia' AND el.description LIKE CONCAT('%Rate ID: ', r.id, '%') AND el.error_date >= CURDATE());

    -- Ejemplo de validación: companyproducts.company_id vs companies.id
    INSERT INTO errores_log (error_type, description)
    SELECT 'FK Inconsistencia', CONCAT('companyproducts.company_id (', cp.company_id, ') no existe en companies.id. CompanyProduct ID: ', cp.id)
    FROM companyproducts cp
    LEFT JOIN companies c ON cp.company_id = c.id
    WHERE c.id IS NULL
    AND NOT EXISTS (SELECT 1 FROM errores_log el WHERE el.error_type = 'FK Inconsistencia' AND el.description LIKE CONCAT('%CompanyProduct ID: ', cp.id, '%') AND el.error_date >= CURDATE());

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Finalizado pr_validar_claves_foraneas');
END //
DELIMITER ;

-- Procedimiento para Evento 11: Eliminar calificaciones inválidas antiguas
DROP PROCEDURE IF EXISTS pr_eliminar_calificaciones_invalidas_antiguas;
DELIMITER //
CREATE PROCEDURE pr_eliminar_calificaciones_invalidas_antiguas()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_eliminar_calificaciones_invalidas_antiguas');

    DELETE FROM rates
    WHERE (rating IS NULL OR rating < 0 OR rating > 5) -- Calificaciones inválidas
      AND created_at < NOW() - INTERVAL 3 MONTH; -- Antiguas (más de 3 meses)

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_eliminar_calificaciones_invalidas_antiguas. Calificaciones eliminadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 12: Cambiar estado de encuestas inactivas automáticamente
DROP PROCEDURE IF EXISTS pr_actualizar_estado_encuestas_inactivas;
DELIMITER //
CREATE PROCEDURE pr_actualizar_estado_encuestas_inactivas()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_actualizar_estado_encuestas_inactivas');

    UPDATE polls
    SET status = 'inactive'
    WHERE status = 'active'
      AND id NOT IN (SELECT DISTINCT poll_id FROM rates WHERE poll_id IS NOT NULL AND created_at >= NOW() - INTERVAL 6 MONTH) -- No tiene respuestas recientes
      AND end_date < CURDATE(); -- Y su fecha de fin ya pasó

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_actualizar_estado_encuestas_inactivas. Encuestas actualizadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 13: Registrar auditorías de forma periódica
DROP PROCEDURE IF EXISTS pr_registrar_auditorias_diarias;
DELIMITER //
CREATE PROCEDURE pr_registrar_auditorias_diarias()
BEGIN
    DECLARE total_cust INT;
    DECLARE total_comp INT;
    DECLARE total_prod INT;
    DECLARE total_rat INT;
    DECLARE total_mem_active INT;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_registrar_auditorias_diarias');

    SELECT COUNT(*) INTO total_cust FROM customers WHERE status = 'active';
    SELECT COUNT(*) INTO total_comp FROM companies WHERE status = 'active';
    SELECT COUNT(*) INTO total_prod FROM products WHERE status = 'active';
    SELECT COUNT(*) INTO total_rat FROM rates;
    SELECT COUNT(*) INTO total_mem_active FROM membershipperiods WHERE status = 'active' AND end_date >= CURDATE();

    INSERT INTO auditorias_diarias (audit_date, total_customers, total_companies, total_products, total_rates, total_memberships_active)
    VALUES (CURDATE(), total_cust, total_comp, total_prod, total_rat, total_mem_active)
    ON DUPLICATE KEY UPDATE
        total_customers = VALUES(total_customers),
        total_companies = VALUES(total_companies),
        total_products = VALUES(total_products),
        total_rates = VALUES(total_rates),
        total_memberships_active = VALUES(total_memberships_active),
        created_at = CURRENT_TIMESTAMP;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Finalizado pr_registrar_auditorias_diarias');
END //
DELIMITER ;

-- Procedimiento para Evento 14: Notificar métricas de calidad a empresas
DROP PROCEDURE IF EXISTS pr_notificar_metricas_calidad_empresas;
DELIMITER //
CREATE PROCEDURE pr_notificar_metricas_calidad_empresas()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_notificar_metricas_calidad_empresas');

    INSERT INTO company_notifications (company_id, message)
    SELECT c.id,
           CONCAT('Informe semanal de calidad: El promedio de calificación de sus productos es ', ROUND(AVG(r.rating), 2), '.')
    FROM companies c
    INNER JOIN rates r ON c.id = r.company_id
    WHERE r.created_at >= NOW() - INTERVAL 7 DAY -- Calificaciones de la última semana
    GROUP BY c.id
    HAVING COUNT(r.id) > 0 -- Solo empresas con calificaciones recientes
    ON DUPLICATE KEY UPDATE
        message = VALUES(message),
        is_read = FALSE,
        created_at = CURRENT_TIMESTAMP;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_notificar_metricas_calidad_empresas. Notificaciones enviadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 15: Recordar renovación de membresías
DROP PROCEDURE IF EXISTS pr_recordar_renovacion_membresias;
DELIMITER //
CREATE PROCEDURE pr_recordar_renovacion_membresias()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_recordar_renovacion_membresias');

    INSERT INTO notifications (customer_id, message)
    SELECT mp.customer_id,
           CONCAT('¡Tu membresía "', m.name, '" vence pronto (el ', DATE_FORMAT(mp.end_date, '%d-%m-%Y'), ')! Renueva ahora para no perder tus beneficios.')
    FROM membershipperiods mp
    INNER JOIN memberships m ON mp.membership_id = m.id
    WHERE mp.status = 'active'
      AND mp.end_date BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY -- Vence en los próximos 7 días
      AND NOT EXISTS ( -- Evitar notificaciones repetidas para el mismo cliente/membresía en el mismo día
          SELECT 1 FROM notifications n
          WHERE n.customer_id = mp.customer_id
          AND n.message LIKE CONCAT('%Tu membresía "', m.name, '" vence pronto%')
          AND n.created_at >= CURDATE()
      );

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_recordar_renovacion_membresias. Notificaciones enviadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 16: Reordenar estadísticas generales cada semana
DROP PROCEDURE IF EXISTS pr_reordenar_estadisticas_generales;
DELIMITER //
CREATE PROCEDURE pr_reordenar_estadisticas_generales()
BEGIN
    DECLARE total_active_prod INT;
    DECLARE total_active_comp INT;
    DECLARE total_active_cust INT;
    DECLARE avg_overall_rate DECIMAL(2,1);
    DECLARE total_orders_comp INT;
    DECLARE total_rev DECIMAL(10,2);

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_reordenar_estadisticas_generales');

    SELECT COUNT(*) INTO total_active_prod FROM products WHERE status = 'active';
    SELECT COUNT(*) INTO total_active_comp FROM companies WHERE status = 'active';
    SELECT COUNT(*) INTO total_active_cust FROM customers WHERE status = 'active';
    SELECT AVG(rating) INTO avg_overall_rate FROM rates;
    SELECT COUNT(*) INTO total_orders_comp FROM orders WHERE status = 'completed';
    SELECT SUM(total_amount) INTO total_rev FROM orders WHERE status = 'completed';

    INSERT INTO general_statistics (stat_date, total_active_products, total_active_companies, total_active_customers, avg_overall_rating, total_orders_completed, total_revenue)
    VALUES (CURDATE(), total_active_prod, total_active_comp, total_active_cust, avg_overall_rate, total_orders_comp, total_rev)
    ON DUPLICATE KEY UPDATE
        total_active_products = VALUES(total_active_products),
        total_active_companies = VALUES(total_active_companies),
        total_active_customers = VALUES(total_active_customers),
        avg_overall_rating = VALUES(avg_overall_rating),
        total_orders_completed = VALUES(total_orders_completed),
        total_revenue = VALUES(total_revenue),
        created_at = CURRENT_TIMESTAMP;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Finalizado pr_reordenar_estadisticas_generales');
END //
DELIMITER ;

-- Procedimiento para Evento 17: Crear resúmenes temporales de uso por categoría
DROP PROCEDURE IF EXISTS pr_crear_resumenes_uso_categoria;
DELIMITER //
CREATE PROCEDURE pr_crear_resumenes_uso_categoria()
BEGIN
    DECLARE current_month_start DATE;
    SET current_month_start = DATE_FORMAT(CURDATE(), '%Y-%m-01');

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Iniciando pr_crear_resumenes_uso_categoria para ', current_month_start));

    INSERT INTO category_usage_summary (category_id, summary_date, total_products_rated, avg_category_rating, total_favorites_in_category)
    SELECT 
        c.id,
        current_month_start,
        COUNT(DISTINCT r.product_id),
        AVG(r.rating),
        COUNT(DISTINCT df.product_id)
    FROM categories c
    LEFT JOIN products p ON c.id = p.category_id
    LEFT JOIN rates r ON p.id = r.product_id AND r.created_at >= current_month_start
    LEFT JOIN details_favorites df ON p.id = df.product_id AND df.added_date >= current_month_start
    GROUP BY c.id
    ON DUPLICATE KEY UPDATE
        total_products_rated = VALUES(total_products_rated),
        avg_category_rating = VALUES(avg_category_rating),
        total_favorites_in_category = VALUES(total_favorites_in_category),
        created_at = CURRENT_TIMESTAMP;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_crear_resumenes_uso_categoria. Resúmenes actualizados: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 18: Actualizar beneficios caducados
DROP PROCEDURE IF EXISTS pr_actualizar_beneficios_caducados;
DELIMITER //
CREATE PROCEDURE pr_actualizar_beneficios_caducados()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_actualizar_beneficios_caducados');

    UPDATE benefits
    SET status = 'inactive'
    WHERE expires_at IS NOT NULL AND expires_at < CURDATE() AND status = 'active';

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_actualizar_beneficios_caducados. Beneficios actualizados: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 19: Alertar productos sin evaluación anual
DROP PROCEDURE IF EXISTS pr_alertar_productos_sin_evaluacion_anual;
DELIMITER //
CREATE PROCEDURE pr_alertar_productos_sin_evaluacion_anual()
BEGIN
    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', 'Iniciando pr_alertar_productos_sin_evaluacion_anual');

    INSERT INTO alertas_productos (product_id, alert_type, message)
    SELECT p.id, 'Sin Evaluación Anual', CONCAT('El producto "', p.name, '" no ha recibido calificaciones en el último año.')
    FROM products p
    LEFT JOIN rates r ON p.id = r.product_id AND r.created_at >= NOW() - INTERVAL 1 YEAR
    WHERE r.id IS NULL
    AND p.status = 'active'
    AND NOT EXISTS ( -- Evitar alertas duplicadas para el mismo producto en el mismo día
        SELECT 1 FROM alertas_productos ap
        WHERE ap.product_id = p.id
        AND ap.alert_type = 'Sin Evaluación Anual'
        AND ap.alert_date >= CURDATE()
    );

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_alertar_productos_sin_evaluacion_anual. Alertas generadas: ', ROW_COUNT()));
END //
DELIMITER ;

-- Procedimiento para Evento 20: Actualizar precios con índice externo
DROP PROCEDURE IF EXISTS pr_actualizar_precios_con_indice_externo;
DELIMITER //
CREATE PROCEDURE pr_actualizar_precios_con_indice_externo()
BEGIN
    DECLARE external_index_rate DECIMAL(5,4);
    
    -- Obtener el índice externo más reciente (ej. de una tabla de índices externos)
    SELECT inflation_rate INTO external_index_rate
    FROM inflacion_indice
    ORDER BY month_year DESC
    LIMIT 1;

    IF external_index_rate IS NULL THEN
        SET external_index_rate = 0.01; -- Valor por defecto si no se encuentra
        INSERT INTO log_acciones (action_type, description)
        VALUES ('Evento Programado', 'No se encontró índice externo. Usando 1% por defecto.');
    END IF;

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Iniciando pr_actualizar_precios_con_indice_externo con tasa: ', external_index_rate * 100, '%'));

    UPDATE companyproducts
    SET price = price * (1 + external_index_rate)
    WHERE status = 'available';

    INSERT INTO log_acciones (action_type, description)
    VALUES ('Evento Programado', CONCAT('Finalizado pr_actualizar_precios_con_indice_externo. Precios actualizados: ', ROW_COUNT()));
END //
DELIMITER ;

-- =====================================================
-- DEFINICIÓN DE LOS EVENTOS
-- =====================================================

-- Desactivar eventos existentes para evitar duplicados durante la recreación
DROP EVENT IF EXISTS evt_borrar_productos_sin_actividad;
DROP EVENT IF EXISTS evt_recalcular_promedio_calificaciones;
DROP EVENT IF EXISTS evt_actualizar_precios_inflacion;
DROP EVENT IF EXISTS evt_crear_backup_productos;
DROP EVENT IF EXISTS evt_notificar_favoritos_sin_calificar;
DROP EVENT IF EXISTS evt_revisar_inconsistencias_empresa_producto;
DROP EVENT IF EXISTS evt_archivar_membresias_vencidas;
DROP EVENT IF EXISTS evt_notificar_beneficios_nuevos;
DROP EVENT IF EXISTS evt_calcular_favoritos_por_cliente_mensual;
DROP EVENT IF EXISTS evt_validar_claves_foraneas;
DROP EVENT IF EXISTS evt_eliminar_calificaciones_invalidas_antiguas;
DROP EVENT IF EXISTS evt_actualizar_estado_encuestas_inactivas;
DROP EVENT IF EXISTS evt_registrar_auditorias_diarias;
DROP EVENT IF EXISTS evt_notificar_metricas_calidad_empresas;
DROP EVENT IF EXISTS evt_recordar_renovacion_membresias;
DROP EVENT IF EXISTS evt_reordenar_estadisticas_generales;
DROP EVENT IF EXISTS evt_crear_resumenes_uso_categoria;
DROP EVENT IF EXISTS evt_actualizar_beneficios_caducados;
DROP EVENT IF EXISTS evt_alertar_productos_sin_evaluacion_anual;
DROP EVENT IF EXISTS evt_actualizar_precios_con_indice_externo;

-- 1. Borrar productos sin actividad cada 6 meses
DELIMITER //
CREATE EVENT evt_borrar_productos_sin_actividad
ON SCHEDULE EVERY 6 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE -- Inicia 1 minuto después de la creación
DO
BEGIN
    CALL pr_borrar_productos_sin_actividad();
END //
DELIMITER ;

-- 2. Recalcular el promedio de calificaciones semanalmente
DELIMITER //
CREATE EVENT evt_recalcular_promedio_calificaciones
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_recalcular_promedio_calificaciones();
END //
DELIMITER ;

-- 3. Actualizar precios según inflación mensual
DELIMITER //
CREATE EVENT evt_actualizar_precios_inflacion
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_actualizar_precios_inflacion();
END //
DELIMITER ;

-- 4. Crear backups lógicos diariamente
DELIMITER //
CREATE EVENT evt_crear_backup_productos
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_crear_backup_productos();
END //
DELIMITER ;

-- 5. Notificar sobre productos favoritos sin calificar (cada 2 días)
DELIMITER //
CREATE EVENT evt_notificar_favoritos_sin_calificar
ON SCHEDULE EVERY 2 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_notificar_favoritos_sin_calificar();
END //
DELIMITER ;

-- 6. Revisar inconsistencias entre empresa y productos cada domingo
DELIMITER //
CREATE EVENT evt_revisar_inconsistencias_empresa_producto
ON SCHEDULE EVERY 1 WEEK ON SUNDAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_revisar_inconsistencias_empresa_producto();
END //
DELIMITER ;

-- 7. Archivar membresías vencidas diariamente
DELIMITER //
CREATE EVENT evt_archivar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_archivar_membresias_vencidas();
END //
DELIMITER ;

-- 8. Notificar beneficios nuevos a usuarios semanalmente
DELIMITER //
CREATE EVENT evt_notificar_beneficios_nuevos
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_notificar_beneficios_nuevos();
END //
DELIMITER ;

-- 9. Calcular cantidad de favoritos por cliente mensualmente
DELIMITER //
CREATE EVENT evt_calcular_favoritos_por_cliente_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_calcular_favoritos_por_cliente_mensual();
END //
DELIMITER ;

-- 10. Validar claves foráneas semanalmente
DELIMITER //
CREATE EVENT evt_validar_claves_foraneas
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_validar_claves_foraneas();
END //
DELIMITER ;

-- 11. Eliminar calificaciones inválidas antiguas (mensual)
DELIMITER //
CREATE EVENT evt_eliminar_calificaciones_invalidas_antiguas
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_eliminar_calificaciones_invalidas_antiguas();
END //
DELIMITER ;

-- 12. Cambiar estado de encuestas inactivas automáticamente (mensual)
DELIMITER //
CREATE EVENT evt_actualizar_estado_encuestas_inactivas
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_actualizar_estado_encuestas_inactivas();
END //
DELIMITER ;

-- 13. Registrar auditorías de forma periódica (diario)
DELIMITER //
CREATE EVENT evt_registrar_auditorias_diarias
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_registrar_auditorias_diarias();
END //
DELIMITER ;

-- 14. Notificar métricas de calidad a empresas (semanal)
DELIMITER //
CREATE EVENT evt_notificar_metricas_calidad_empresas
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_notificar_metricas_calidad_empresas();
END //
DELIMITER ;

-- 15. Recordar renovación de membresías (diario)
DELIMITER //
CREATE EVENT evt_recordar_renovacion_membresias
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_recordar_renovacion_membresias();
END //
DELIMITER ;

-- 16. Reordenar estadísticas generales cada semana
DELIMITER //
CREATE EVENT evt_reordenar_estadisticas_generales
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_reordenar_estadisticas_generales();
END //
DELIMITER ;

-- 17. Crear resúmenes temporales de uso por categoría (mensual)
DELIMITER //
CREATE EVENT evt_crear_resumenes_uso_categoria
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_crear_resumenes_uso_categoria();
END //
DELIMITER ;

-- 18. Actualizar beneficios caducados (diario)
DELIMITER //
CREATE EVENT evt_actualizar_beneficios_caducados
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_actualizar_beneficios_caducados();
END //
DELIMITER ;

-- 19. Alertar productos sin evaluación anual (mensual)
DELIMITER //
CREATE EVENT evt_alertar_productos_sin_evaluacion_anual
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_alertar_productos_sin_evaluacion_anual();
END //
DELIMITER ;

-- 20. Actualizar precios con índice externo (mensual)
DELIMITER //
CREATE EVENT evt_actualizar_precios_con_indice_externo
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
BEGIN
    CALL pr_actualizar_precios_con_indice_externo();
END //
DELIMITER ;

DELIMITER ;

-- =====================================================
-- FIN DE LOS EVENTS
-- =====================================================
