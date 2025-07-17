-- =====================================================
-- PROYECTO: PLATAFORMA DE COMERCIALIZACIÓN DIGITAL MULTINIVEL
-- ARCHIVO: Inserción de datos de prueba (CORREGIDO)
-- DESCRIPCIÓN: Datos realistas para todas las tablas
-- =====================================================

USE plataforma_comercial;

-- =====================================================
-- 1. DATOS BASE - TABLAS SIN DEPENDENCIAS
-- =====================================================

-- Insertar países
INSERT INTO countries (name, code) VALUES
('Colombia', 'COL'),
('México', 'MEX'),
('Argentina', 'ARG'),
('Chile', 'CHL'),
('Perú', 'PER'),
('Ecuador', 'ECU'),
('Venezuela', 'VEN'),
('Brasil', 'BRA'),
('Uruguay', 'URY'),
('Paraguay', 'PRY')
ON DUPLICATE KEY UPDATE name=VALUES(name), code=VALUES(code);

-- Insertar categorías de productos
INSERT INTO categories (name, description) VALUES
('Alimentos y Bebidas', 'Productos alimenticios, bebidas y comestibles'),
('Tecnología', 'Dispositivos electrónicos, computadoras y accesorios'),
('Ropa y Accesorios', 'Vestimenta, calzado y complementos de moda'),
('Hogar y Jardín', 'Artículos para el hogar, decoración y jardinería'),
('Salud y Belleza', 'Productos de cuidado personal, cosméticos y salud'),
('Deportes y Recreación', 'Equipos deportivos y artículos recreativos'),
('Libros y Educación', 'Material educativo, libros y recursos de aprendizaje'),
('Automóviles', 'Vehículos, repuestos y accesorios automotrices'),
('Servicios', 'Servicios profesionales y especializados'),
('Arte y Manualidades', 'Materiales artísticos y productos para manualidades')
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description);

-- Insertar audiencias objetivo
INSERT INTO audiences (name, description, age_range) VALUES
('Niños', 'Productos dirigidos a niños y infantes', '0-12 años'),
('Adolescentes', 'Productos para jóvenes adolescentes', '13-17 años'),
('Jóvenes Adultos', 'Productos para adultos jóvenes', '18-35 años'),
('Adultos', 'Productos para adultos en general', '36-55 años'),
('Adultos Mayores', 'Productos para la tercera edad', '56+ años'),
('Familias', 'Productos dirigidos a núcleos familiares', 'Todas las edades'),
('Profesionales', 'Productos para uso profesional y empresarial', '25-65 años'),
('Estudiantes', 'Productos específicos para estudiantes', '15-30 años'),
('Deportistas', 'Productos para personas activas y deportistas', '16-50 años'),
('Mascotas', 'Productos para el cuidado de mascotas', 'N/A')
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description), age_range=VALUES(age_range);

-- Insertar tipos de empresa
INSERT INTO company_types (name, description) VALUES
('Retail', 'Empresas de venta al por menor'),
('Mayorista', 'Empresas de venta al por mayor'),
('Manufacturera', 'Empresas que fabrican productos'),
('Servicios', 'Empresas que ofrecen servicios'),
('Tecnología', 'Empresas del sector tecnológico'),
('Alimentaria', 'Empresas del sector alimentario'),
('Textil', 'Empresas del sector textil y confección'),
('Farmacéutica', 'Empresas del sector farmacéutico y salud'),
('Automotriz', 'Empresas del sector automotriz'),
('Educativa', 'Instituciones educativas y de formación')
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description);

-- Insertar unidades de medida
INSERT INTO units (name, abbreviation, type) VALUES
('Kilogramo', 'kg', 'weight'),
('Gramo', 'g', 'weight'),
('Libra', 'lb', 'weight'),
('Litro', 'L', 'volume'),
('Mililitro', 'ml', 'volume'),
('Metro', 'm', 'length'),
('Centímetro', 'cm', 'length'),
('Unidad', 'und', 'unit'),
('Docena', 'doc', 'unit'),
('Caja', 'caja', 'unit'),
('Metro cuadrado', 'm²', 'area'),
('Galón', 'gal', 'volume'),
('Onza', 'oz', 'weight'),
('Paquete', 'paq', 'unit'),
('Rollo', 'rollo', 'unit')
ON DUPLICATE KEY UPDATE name=VALUES(name), abbreviation=VALUES(abbreviation), type=VALUES(type);

-- =====================================================
-- 2. ESTRUCTURA GEOGRÁFICA
-- =====================================================

-- Insertar departamentos/estados (Colombia como ejemplo principal)
INSERT INTO stateregions (name, code, country_id) VALUES
-- Colombia
('Antioquia', 'ANT', (SELECT id FROM countries WHERE code = 'COL')),
('Bogotá D.C.', 'BOG', (SELECT id FROM countries WHERE code = 'COL')),
('Valle del Cauca', 'VAL', (SELECT id FROM countries WHERE code = 'COL')),
('Atlántico', 'ATL', (SELECT id FROM countries WHERE code = 'COL')),
('Santander', 'SAN', (SELECT id FROM countries WHERE code = 'COL')),
('Cundinamarca', 'CUN', (SELECT id FROM countries WHERE code = 'COL')),
('Bolívar', 'BOL', (SELECT id FROM countries WHERE code = 'COL')),
('Córdoba', 'COR', (SELECT id FROM countries WHERE code = 'COL')),
('Tolima', 'TOL', (SELECT id FROM countries WHERE code = 'COL')),
('Huila', 'HUI', (SELECT id FROM countries WHERE code = 'COL')),
-- México
('Ciudad de México', 'CDMX', (SELECT id FROM countries WHERE code = 'MEX')),
('Jalisco', 'JAL', (SELECT id FROM countries WHERE code = 'MEX')),
('Nuevo León', 'NL', (SELECT id FROM countries WHERE code = 'MEX')),
('Puebla', 'PUE', (SELECT id FROM countries WHERE code = 'MEX')),
('Guanajuato', 'GTO', (SELECT id FROM countries WHERE code = 'MEX')),
-- Argentina
('Buenos Aires', 'BA', (SELECT id FROM countries WHERE code = 'ARG')),
('Córdoba', 'CB', (SELECT id FROM countries WHERE code = 'ARG')),
('Santa Fe', 'SF', (SELECT id FROM countries WHERE code = 'ARG')),
-- Chile
('Región Metropolitana', 'RM', (SELECT id FROM countries WHERE code = 'CHL')),
('Valparaíso', 'VP', (SELECT id FROM countries WHERE code = 'CHL')),
-- Perú
('Lima', 'LIM', (SELECT id FROM countries WHERE code = 'PER')),
('Arequipa', 'ARE', (SELECT id FROM countries WHERE code = 'PER'))
ON DUPLICATE KEY UPDATE name=VALUES(name), code=VALUES(code), country_id=VALUES(country_id);

-- Insertar ciudades/municipios
INSERT INTO citiesormunicipalities (name, code, stateregion_id) VALUES
-- Antioquia, Colombia
('Medellín', 'MED', (SELECT id FROM stateregions WHERE code = 'ANT' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Bello', 'BEL', (SELECT id FROM stateregions WHERE code = 'ANT' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Itagüí', 'ITA', (SELECT id FROM stateregions WHERE code = 'ANT' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Envigado', 'ENV', (SELECT id FROM stateregions WHERE code = 'ANT' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Sabaneta', 'SAB', (SELECT id FROM stateregions WHERE code = 'ANT' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
-- Bogotá D.C., Colombia
('Bogotá', 'BOG', (SELECT id FROM stateregions WHERE code = 'BOG' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
-- Valle del Cauca, Colombia
('Cali', 'CAL', (SELECT id FROM stateregions WHERE code = 'VAL' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Palmira', 'PAL', (SELECT id FROM stateregions WHERE code = 'VAL' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Buenaventura', 'BUE', (SELECT id FROM stateregions WHERE code = 'VAL' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
-- Atlántico, Colombia
('Barranquilla', 'BAQ', (SELECT id FROM stateregions WHERE code = 'ATL' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Soledad', 'SOL', (SELECT id FROM stateregions WHERE code = 'ATL' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
-- Santander, Colombia
('Bucaramanga', 'BUC', (SELECT id FROM stateregions WHERE code = 'SAN' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
('Floridablanca', 'FLO', (SELECT id FROM stateregions WHERE code = 'SAN' AND country_id = (SELECT id FROM countries WHERE code = 'COL'))),
-- México
('Ciudad de México', 'CDMX', (SELECT id FROM stateregions WHERE code = 'CDMX' AND country_id = (SELECT id FROM countries WHERE code = 'MEX'))),
('Guadalajara', 'GDL', (SELECT id FROM stateregions WHERE code = 'JAL' AND country_id = (SELECT id FROM countries WHERE code = 'MEX'))),
('Monterrey', 'MTY', (SELECT id FROM stateregions WHERE code = 'NL' AND country_id = (SELECT id FROM countries WHERE code = 'MEX'))),
('Puebla', 'PUE', (SELECT id FROM stateregions WHERE code = 'PUE' AND country_id = (SELECT id FROM countries WHERE code = 'MEX'))),
-- Argentina
('Buenos Aires', 'CABA', (SELECT id FROM stateregions WHERE code = 'BA' AND country_id = (SELECT id FROM countries WHERE code = 'ARG'))),
('Córdoba', 'CBA', (SELECT id FROM stateregions WHERE code = 'CB' AND country_id = (SELECT id FROM countries WHERE code = 'ARG'))),
('Rosario', 'ROS', (SELECT id FROM stateregions WHERE code = 'SF' AND country_id = (SELECT id FROM countries WHERE code = 'ARG'))),
-- Chile
('Santiago', 'SCL', (SELECT id FROM stateregions WHERE code = 'RM' AND country_id = (SELECT id FROM countries WHERE code = 'CHL'))),
('Valparaíso', 'VAL', (SELECT id FROM stateregions WHERE code = 'VP' AND country_id = (SELECT id FROM countries WHERE code = 'CHL'))),
-- Perú
('Lima', 'LIM', (SELECT id FROM stateregions WHERE code = 'LIM' AND country_id = (SELECT id FROM countries WHERE code = 'PER'))),
('Arequipa', 'AQP', (SELECT id FROM stateregions WHERE code = 'ARE' AND country_id = (SELECT id FROM countries WHERE code = 'PER')))
ON DUPLICATE KEY UPDATE name=VALUES(name), code=VALUES(code), stateregion_id=VALUES(stateregion_id);

-- =====================================================
-- 3. ENTIDADES PRINCIPALES
-- =====================================================

-- Insertar clientes
INSERT INTO customers (first_name, last_name, email, phone, birth_date, gender, city_id, audience_id, status) VALUES
('Juan Carlos', 'Rodríguez', 'juan.rodriguez@email.com', '+57 300 123 4567', '1985-03-15', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('María Elena', 'González', 'maria.gonzalez@email.com', '+57 301 234 5678', '1990-07-22', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Carlos Alberto', 'Martínez', 'carlos.martinez@email.com', '+57 302 345 6789', '1978-11-08', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Bogotá' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Ana Sofía', 'López', 'ana.lopez@email.com', '+57 303 456 7890', '1995-01-30', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Cali' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Luis Fernando', 'Hernández', 'luis.hernandez@email.com', '+57 304 567 8901', '1982-09-12', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Palmira' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Carmen Rosa', 'Jiménez', 'carmen.jimenez@email.com', '+57 305 678 9012', '1988-05-18', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Barranquilla' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Diego Alejandro', 'Vargas', 'diego.vargas@email.com', '+57 306 789 0123', '1992-12-03', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Bucaramanga' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Valentina', 'Morales', 'valentina.morales@email.com', '+57 307 890 1234', '1987-04-25', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Floridablanca' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Andrés Felipe', 'Castro', 'andres.castro@email.com', '+52 55 1234 5678', '1991-08-14', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Ciudad de México' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Isabella', 'Ramírez', 'isabella.ramirez@email.com', '+52 33 2345 6789', '1986-02-28', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Guadalajara' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Santiago', 'Torres', 'santiago.torres@email.com', '+54 11 3456 7890', '1989-10-07', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Buenos Aires' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Camila', 'Flores', 'camila.flores@email.com', '+56 2 4567 8901', '1993-06-19', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Santiago' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Mateo', 'Silva', 'mateo.silva@email.com', '+51 1 5678 9012', '1984-12-11', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Lima' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Sofía', 'Mendoza', 'sofia.mendoza@email.com', '+57 300 111 2222', '1996-03-08', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Gabriel', 'Ruiz', 'gabriel.ruiz@email.com', '+57 301 222 3333', '1980-07-16', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Cali' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Lucía', 'Peña', 'lucia.pena@email.com', '+57 302 333 4444', '1994-11-22', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Palmira' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Sebastián', 'Ortega', 'sebastian.ortega@email.com', '+57 303 444 5555', '1983-01-05', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Barranquilla' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Daniela', 'Guerrero', 'daniela.guerrero@email.com', '+57 304 555 6666', '1991-09-30', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Bucaramanga' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Alejandro', 'Rojas', 'alejandro.rojas@email.com', '+57 305 666 7777', '1987-05-14', 'M', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Natalia', 'Vega', 'natalia.vega@email.com', '+57 306 777 8888', '1992-08-27', 'F', (SELECT id FROM citiesormunicipalities WHERE name = 'Bogotá' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active')
ON DUPLICATE KEY UPDATE first_name=VALUES(first_name), last_name=VALUES(last_name), phone=VALUES(phone), birth_date=VALUES(birth_date), gender=VALUES(gender), city_id=VALUES(city_id), audience_id=VALUES(audience_id), status=VALUES(status);

-- Insertar empresas
INSERT INTO companies (name, business_name, tax_id, email, phone, address, city_id, company_type_id, audience_id, status) VALUES
('TechnoStore', 'TechnoStore S.A.S.', '900123456-1', 'info@technostore.com', '+57 4 123 4567', 'Calle 50 #45-30', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('SuperMercados Frescos', 'Frescos Alimentarios Ltda.', '900234567-2', 'contacto@frescos.com', '+57 4 234 5678', 'Carrera 70 #32-15', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Familias' LIMIT 1), 'active'),
('Moda Urbana', 'Confecciones Urbanas S.A.', '900345678-3', 'ventas@modaurbana.com', '+57 1 345 6789', 'Avenida 19 #85-40', (SELECT id FROM citiesormunicipalities WHERE name = 'Bogotá' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Manufacturera' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Salud Total', 'Farmacéutica Salud Total S.A.S.', '900456789-4', 'info@saludtotal.com', '+57 2 456 7890', 'Calle 15 #28-50', (SELECT id FROM citiesormunicipalities WHERE name = 'Cali' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Farmacéutica' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Deportes Extremos', 'Deportes y Aventura Ltda.', '900567890-5', 'contacto@deportesextremos.com', '+57 5 567 8901', 'Carrera 27 #45-20', (SELECT id FROM citiesormunicipalities WHERE name = 'Bucaramanga' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Deportistas' LIMIT 1), 'active'),
('Hogar Ideal', 'Decoraciones del Hogar S.A.', '900678901-6', 'ventas@hogarideal.com', '+57 4 678 9012', 'Calle 80 #50-35', (SELECT id FROM citiesormunicipalities WHERE name = 'Medellín' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Familias' LIMIT 1), 'active'),
('Libros y Más', 'Editorial Conocimiento S.A.S.', '900789012-7', 'info@librosymas.com', '+57 1 789 0123', 'Carrera 13 #60-25', (SELECT id FROM citiesormunicipalities WHERE name = 'Bogotá' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Estudiantes' LIMIT 1), 'active'),
('AutoPartes Colombia', 'Repuestos Automotrices S.A.', '900890123-8', 'ventas@autopartes.com', '+57 2 890 1234', 'Avenida 30 #40-15', (SELECT id FROM citiesormunicipalities WHERE name = 'Cali' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Mayorista' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Belleza Natural', 'Cosméticos Naturales Ltda.', '900901234-9', 'contacto@bellezanatural.com', '+57 4 901 2345', 'Calle 70 #35-40', (SELECT id FROM citiesormunicipalities WHERE name = 'Palmira' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Servicios Profesionales', 'Consultoría Integral S.A.S.', '901012345-0', 'info@serviciospro.com', '+57 5 012 3456', 'Carrera 45 #25-30', (SELECT id FROM citiesormunicipalities WHERE name = 'Barranquilla' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Servicios' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Profesionales' LIMIT 1), 'active'),
('Electrónicos México', 'Tecnología Avanzada S.A. de C.V.', 'MEX123456789', 'ventas@electronicosmx.com', '+52 55 123 4567', 'Av. Insurgentes 1500', (SELECT id FROM citiesormunicipalities WHERE name = 'Ciudad de México' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Alimentos Guadalajara', 'Distribuidora de Alimentos S.A.', 'MEX234567890', 'info@alimentosgdl.com', '+52 33 234 5678', 'Calle Juárez 250', (SELECT id FROM citiesormunicipalities WHERE name = 'Guadalajara' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Mayorista' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Familias' LIMIT 1), 'active'),
('Fashion Buenos Aires', 'Moda Argentina S.R.L.', 'ARG345678901', 'contacto@fashionba.com', '+54 11 345 6789', 'Av. Corrientes 1200', (SELECT id FROM citiesormunicipalities WHERE name = 'Buenos Aires' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Manufacturera' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Jóvenes Adultos' LIMIT 1), 'active'),
('Farmacia Santiago', 'Salud Chile Ltda.', 'CHL456789012', 'info@farmaciasantiago.cl', '+56 2 456 7890', 'Providencia 1800', (SELECT id FROM citiesormunicipalities WHERE name = 'Santiago' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Farmacéutica' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Adultos' LIMIT 1), 'active'),
('Deportes Lima', 'Equipos Deportivos Perú S.A.C.', 'PER567890123', 'ventas@deporteslima.pe', '+51 1 567 8901', 'Av. Arequipa 3500', (SELECT id FROM citiesormunicipalities WHERE name = 'Lima' LIMIT 1), (SELECT id FROM company_types WHERE name = 'Retail' LIMIT 1), (SELECT id FROM audiences WHERE name = 'Deportistas' LIMIT 1), 'active')
ON DUPLICATE KEY UPDATE name=VALUES(name), business_name=VALUES(business_name), tax_id=VALUES(tax_id), email=VALUES(email), phone=VALUES(phone), address=VALUES(address), city_id=VALUES(city_id), company_type_id=VALUES(company_type_id), audience_id=VALUES(audience_id), status=VALUES(status);

-- Insertar productos
INSERT INTO products (name, description, category_id, unit_id, image_url, status) VALUES
-- Tecnología (IDs: 1-5)
('Smartphone Galaxy Pro', 'Teléfono inteligente de última generación con cámara de 108MP', (SELECT id FROM categories WHERE name = 'Tecnología' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/smartphone-galaxy.jpg', 'active'),
('Laptop Gaming Ultra', 'Computadora portátil para gaming con procesador i7 y RTX 4060', (SELECT id FROM categories WHERE name = 'Tecnología' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/laptop-gaming.jpg', 'active'),
('Auriculares Bluetooth', 'Auriculares inalámbricos con cancelación de ruido', (SELECT id FROM categories WHERE name = 'Tecnología' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/auriculares-bt.jpg', 'active'),
('Tablet 10 pulgadas', 'Tablet con pantalla HD y 128GB de almacenamiento', (SELECT id FROM categories WHERE name = 'Tecnología' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/tablet-10.jpg', 'active'),
('Smartwatch Fitness', 'Reloj inteligente con monitor de salud y GPS', (SELECT id FROM categories WHERE name = 'Tecnología' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/smartwatch.jpg', 'active'),

-- Alimentos y Bebidas (IDs: 6-10)
('Café Premium Colombiano', 'Café 100% arábica de las montañas colombianas', (SELECT id FROM categories WHERE name = 'Alimentos y Bebidas' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'kg' LIMIT 1), '/images/cafe-premium.jpg', 'active'),
('Aceite de Oliva Extra Virgen', 'Aceite de oliva de primera extracción en frío', (SELECT id FROM categories WHERE name = 'Alimentos y Bebidas' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'L' LIMIT 1), '/images/aceite-oliva.jpg', 'active'),
('Quinoa Orgánica', 'Quinoa orgánica certificada, rica en proteínas', (SELECT id FROM categories WHERE name = 'Alimentos y Bebidas' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'kg' LIMIT 1), '/images/quinoa-organica.jpg', 'active'),
('Miel de Abeja Natural', 'Miel pura de abeja sin procesar', (SELECT id FROM categories WHERE name = 'Alimentos y Bebidas' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'kg' LIMIT 1), '/images/miel-natural.jpg', 'active'),
('Té Verde Premium', 'Té verde de hojas selectas con antioxidantes', (SELECT id FROM categories WHERE name = 'Alimentos y Bebidas' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'g' LIMIT 1), '/images/te-verde.jpg', 'active'),

-- Ropa y Accesorios (IDs: 11-15)
('Camiseta Deportiva', 'Camiseta transpirable para actividades deportivas', (SELECT id FROM categories WHERE name = 'Ropa y Accesorios' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/camiseta-deportiva.jpg', 'active'),
('Jeans Clásicos', 'Pantalones jeans de corte clásico y cómodo', (SELECT id FROM categories WHERE name = 'Ropa y Accesorios' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/jeans-clasicos.jpg', 'active'),
('Zapatos Casuales', 'Zapatos cómodos para uso diario', (SELECT id FROM categories WHERE name = 'Ropa y Accesorios' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/zapatos-casuales.jpg', 'active'),
('Chaqueta Impermeable', 'Chaqueta resistente al agua para exteriores', (SELECT id FROM categories WHERE name = 'Ropa y Accesorios' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/chaqueta-impermeable.jpg', 'active'),
('Gorra Deportiva', 'Gorra ajustable con protección UV', (SELECT id FROM categories WHERE name = 'Ropa y Accesorios' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/gorra-deportiva.jpg', 'active'),

-- Hogar y Jardín (IDs: 16-20)
('Juego de Sábanas', 'Juego completo de sábanas de algodón 100%', (SELECT id FROM categories WHERE name = 'Hogar y Jardín' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/sabanas-algodon.jpg', 'active'),
('Maceta Decorativa', 'Maceta de cerámica para plantas de interior', (SELECT id FROM categories WHERE name = 'Hogar y Jardín' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/maceta-ceramica.jpg', 'active'),
('Lámpara LED', 'Lámpara de mesa con tecnología LED de bajo consumo', (SELECT id FROM categories WHERE name = 'Hogar y Jardín' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/lampara-led.jpg', 'active'),
('Cojines Decorativos', 'Set de cojines para sofá con diseños modernos', (SELECT id FROM categories WHERE name = 'Hogar y Jardín' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/cojines-decorativos.jpg', 'active'),
('Organizador de Closet', 'Sistema de organización modular para closet', (SELECT id FROM categories WHERE name = 'Hogar y Jardín' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/organizador-closet.jpg', 'active'),

-- Salud y Belleza (IDs: 21-25)
('Crema Hidratante Facial', 'Crema hidratante con ácido hialurónico', (SELECT id FROM categories WHERE name = 'Salud y Belleza' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'ml' LIMIT 1), '/images/crema-facial.jpg', 'active'),
('Champú Anticaspa', 'Champú medicado para control de caspa', (SELECT id FROM categories WHERE name = 'Salud y Belleza' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'ml' LIMIT 1), '/images/champu-anticaspa.jpg', 'active'),
('Vitaminas Multivitamínico', 'Suplemento vitamínico completo', (SELECT id FROM categories WHERE name = 'Salud y Belleza' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/multivitaminico.jpg', 'active'),
('Protector Solar SPF 50', 'Protector solar de amplio espectro', (SELECT id FROM categories WHERE name = 'Salud y Belleza' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'ml' LIMIT 1), '/images/protector-solar.jpg', 'active'),
('Perfume Unisex', 'Fragancia fresca y duradera', (SELECT id FROM categories WHERE name = 'Salud y Belleza' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'ml' LIMIT 1), '/images/perfume-unisex.jpg', 'active'),

-- Deportes y Recreación (IDs: 26-30)
('Pelota de Fútbol', 'Pelota oficial de fútbol tamaño 5', (SELECT id FROM categories WHERE name = 'Deportes y Recreación' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/pelota-futbol.jpg', 'active'),
('Raqueta de Tenis', 'Raqueta profesional de tenis con grip cómodo', (SELECT id FROM categories WHERE name = 'Deportes y Recreación' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/raqueta-tenis.jpg', 'active'),
('Pesas Ajustables', 'Set de pesas ajustables de 5 a 25 kg', (SELECT id FROM categories WHERE name = 'Deportes y Recreación' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/pesas-ajustables.jpg', 'active'),
('Bicicleta Montaña', 'Bicicleta todo terreno con 21 velocidades', (SELECT id FROM categories WHERE name = 'Deportes y Recreación' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/bicicleta-montana.jpg', 'active'),
('Colchoneta Yoga', 'Colchoneta antideslizante para yoga y ejercicios', (SELECT id FROM categories WHERE name = 'Deportes y Recreación' LIMIT 1), (SELECT id FROM units WHERE abbreviation = 'und' LIMIT 1), '/images/colchoneta-yoga.jpg', 'active')
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description), category_id=VALUES(category_id), unit_id=VALUES(unit_id), image_url=VALUES(image_url), status=VALUES(status);

-- =====================================================
-- 4. SISTEMA DE MEMBRESÍAS Y BENEFICIOS
-- =====================================================

-- Insertar tipos de membresía
INSERT INTO memberships (name, description, level, status) VALUES
('Básica', 'Membresía básica con beneficios esenciales', 1, 'active'),
('Premium', 'Membresía premium con beneficios adicionales', 2, 'active'),
('VIP', 'Membresía VIP con todos los beneficios exclusivos', 3, 'active'),
('Empresarial', 'Membresía especial para empresas', 2, 'active'),
('Estudiante', 'Membresía con descuentos para estudiantes', 1, 'active')
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description), level=VALUES(level), status=VALUES(status);

-- Insertar beneficios
INSERT INTO benefits (name, description, type, value, status, expires_at) VALUES
('Descuento 10%', 'Descuento del 10% en todas las compras', 'discount', '10%', 'active', NULL),
('Descuento 20%', 'Descuento del 20% en productos seleccionados', 'discount', '20%', 'active', NULL),
('Envío Gratis', 'Envío gratuito en todas las compras', 'service', 'free_shipping', 'active', NULL),
('Acceso Prioritario', 'Acceso prioritario a nuevos productos', 'access', 'priority', 'active', NULL),
('Soporte 24/7', 'Soporte técnico las 24 horas', 'service', '24/7', 'active', NULL),
('Descuento Estudiante', 'Descuento especial del 15% para estudiantes', 'discount', '15%', 'active', '2025-12-31'),
('Producto Gratis Mensual', 'Un producto gratis cada mes', 'product', 'monthly_free', 'active', NULL),
('Consulta Nutricional', 'Consulta gratuita con nutricionista', 'service', 'free_consultation', 'active', NULL),
('Descuento Familia', 'Descuento del 25% para compras familiares', 'discount', '25%', 'active', NULL),
('Acceso Beta', 'Acceso anticipado a productos en fase beta', 'access', 'beta_access', 'active', NULL)
ON DUPLICATE KEY UPDATE name=VALUES(name), description=VALUES(description), type=VALUES(type), value=VALUES(value), status=VALUES(status), expires_at=VALUES(expires_at);

-- Completar períodos de membresía
INSERT INTO membershipperiods (customer_id, membership_id, start_date, end_date, price, status, payment_confirmed) VALUES
(9, 3, '2024-03-25', '2025-03-25', 199.99, 'active', TRUE),
(10, 2, '2024-07-12', '2025-07-12', 99.99, 'active', TRUE),
(11, 1, '2024-08-08', '2025-08-08', 49.99, 'active', TRUE),
(12, 2, '2024-04-30', '2025-04-30', 99.99, 'active', TRUE),
(13, 1, '2024-06-20', '2025-06-20', 49.99, 'active', TRUE),
(14, 5, '2024-09-15', '2025-09-15', 29.99, 'active', TRUE),
(15, 2, '2024-05-25', '2025-05-25', 99.99, 'active', TRUE),
(16, 1, '2024-07-08', '2025-07-08', 49.99, 'active', TRUE),
(17, 3, '2024-02-18', '2025-02-18', 199.99, 'active', TRUE),
(18, 2, '2024-08-22', '2025-08-22', 99.99, 'active', TRUE),
(19, 1, '2024-09-05', '2025-09-05', 49.99, 'active', TRUE),
(20, 2, '2024-03-12', '2025-03-12', 99.99, 'active', TRUE)
ON DUPLICATE KEY UPDATE customer_id=VALUES(customer_id), membership_id=VALUES(membership_id), start_date=VALUES(start_date), end_date=VALUES(end_date), price=VALUES(price), status=VALUES(status), payment_confirmed=VALUES(payment_confirmed);

-- Relacionar membresías con beneficios
INSERT INTO membershipbenefits (membership_id, benefit_id) VALUES
-- Membresía Básica
(1, 1), -- Descuento 10%
(1, 3), -- Envío Gratis
-- Membresía Premium
(2, 2), -- Descuento 20%
(2, 3), -- Envío Gratis
(2, 4), -- Acceso Prioritario
(2, 5), -- Soporte 24/7
-- Membresía VIP
(3, 2), -- Descuento 20%
(3, 3), -- Envío Gratis
(3, 4), -- Acceso Prioritario
(3, 5), -- Soporte 24/7
(3, 7), -- Producto Gratis Mensual
(3, 8), -- Consulta Nutricional
(3, 10), -- Acceso Beta
-- Membresía Empresarial
(4, 2), -- Descuento 20%
(4, 3), -- Envío Gratis
(4, 5), -- Soporte 24/7
(4, 9), -- Descuento Familia
-- Membresía Estudiante
(5, 6), -- Descuento Estudiante
(5, 3); -- Envío Gratis

-- =====================================================
-- 5. INVENTARIO Y PRECIOS
-- =====================================================

-- Insertar inventario de productos por empresa
INSERT INTO inventory (product_id, company_id, quantity, price, cost, min_stock, max_stock, status) VALUES
-- TechnoStore (empresa 1)
(1, 1, 50, 899.99, 650.00, 10, 100, 'active'),
(2, 1, 25, 1299.99, 950.00, 5, 50, 'active'),
(3, 1, 75, 149.99, 90.00, 20, 150, 'active'),
(4, 1, 40, 399.99, 280.00, 10, 80, 'active'),
(5, 1, 60, 249.99, 180.00, 15, 120, 'active'),

-- SuperMercados Frescos (empresa 2)
(6, 2, 200, 24.99, 15.00, 50, 500, 'active'),
(7, 2, 150, 18.99, 12.50, 30, 300, 'active'),
(8, 2, 100, 12.99, 8.00, 25, 200, 'active'),
(9, 2, 80, 16.99, 10.00, 20, 150, 'active'),
(10, 2, 120, 8.99, 5.50, 30, 250, 'active'),

-- Moda Urbana (empresa 3)
(11, 3, 100, 29.99, 18.00, 25, 200, 'active'),
(12, 3, 80, 79.99, 45.00, 20, 150, 'active'),
(13, 3, 60, 119.99, 70.00, 15, 120, 'active'),
(14, 3, 40, 89.99, 55.00, 10, 80, 'active'),
(15, 3, 150, 19.99, 12.00, 50, 300, 'active'),

-- Salud Total (empresa 4)
(21, 4, 200, 35.99, 22.00, 50, 400, 'active'),
(22, 4, 150, 18.99, 12.00, 40, 300, 'active'),
(23, 4, 100, 24.99, 15.00, 25, 200, 'active'),
(24, 4, 80, 28.99, 18.00, 20, 150, 'active'),
(25, 4, 60, 65.99, 40.00, 15, 120, 'active'),

-- Deportes Extremos (empresa 5)
(26, 5, 50, 45.99, 28.00, 15, 100, 'active'),
(27, 5, 30, 189.99, 120.00, 10, 60, 'active'),
(28, 5, 25, 299.99, 180.00, 5, 50, 'active'),
(29, 5, 15, 899.99, 550.00, 3, 30, 'active'),
(30, 5, 40, 39.99, 25.00, 10, 80, 'active'),

-- Hogar Ideal (empresa 6)
(16, 6, 80, 89.99, 55.00, 20, 150, 'active'),
(17, 6, 120, 24.99, 15.00, 30, 200, 'active'),
(18, 6, 100, 49.99, 30.00, 25, 180, 'active'),
(19, 6, 200, 15.99, 10.00, 50, 400, 'active'),
(20, 6, 60, 79.99, 50.00, 15, 120, 'active'),

-- Inventario adicional para otras empresas
(1, 11, 30, 920.00, 680.00, 5, 50, 'active'), -- Electrónicos México
(6, 12, 180, 26.50, 16.00, 40, 350, 'active'), -- Alimentos Guadalajara
(11, 13, 90, 32.00, 19.00, 20, 150, 'active'), -- Fashion Buenos Aires
(21, 14, 150, 38.50, 24.00, 35, 250, 'active'), -- Farmacia Santiago
(26, 15, 45, 48.00, 30.00, 12, 80, 'active'); -- Deportes Lima

-- =====================================================
-- 6. ÓRDENES DE COMPRA Y VENTAS
-- =====================================================

-- Insertar órdenes de compra
INSERT INTO orders (customer_id, total_amount, tax_amount, shipping_cost, discount_amount, status, payment_method, shipping_address, billing_address, notes) VALUES
(1, 1049.98, 167.99, 15.00, 105.00, 'completed', 'credit_card', 'Calle 45 #23-10, Medellín', 'Calle 45 #23-10, Medellín', 'Entrega en horario de oficina'),
(2, 74.98, 11.99, 8.00, 0.00, 'completed', 'debit_card', 'Carrera 50 #32-15, Medellín', 'Carrera 50 #32-15, Medellín', 'Productos frescos'),
(3, 199.98, 31.99, 12.00, 20.00, 'completed', 'paypal', 'Calle 80 #45-20, Bogotá', 'Calle 80 #45-20, Bogotá', 'Regalo de cumpleaños'),
(4, 89.98, 14.39, 10.00, 9.00, 'shipped', 'credit_card', 'Avenida 15 #60-30, Cali', 'Avenida 15 #60-30, Cali', 'Urgente'),
(5, 549.98, 87.99, 20.00, 55.00, 'processing', 'bank_transfer', 'Carrera 27 #18-45, Barranquilla', 'Carrera 27 #18-45, Barranquilla', 'Equipo deportivo'),
(6, 164.97, 26.39, 12.00, 0.00, 'completed', 'credit_card', 'Calle 70 #35-25, Bucaramanga', 'Calle 70 #35-25, Bucaramanga', 'Decoración hogar'),
(7, 399.99, 63.99, 15.00, 40.00, 'completed', 'debit_card', 'Carrera 45 #28-12, Floridablanca', 'Carrera 45 #28-12, Floridablanca', 'Tecnología'),
(8, 124.97, 19.99, 8.00, 12.50, 'completed', 'paypal', 'Calle 25 #40-15, Medellín', 'Calle 25 #40-15, Medellín', 'Cuidado personal'),
(9, 920.00, 147.20, 25.00, 92.00, 'pending', 'credit_card', 'Av. Insurgentes 1250, Ciudad de México', 'Av. Insurgentes 1250, Ciudad de México', 'Envío internacional'),
(10, 189.99, 30.39, 18.00, 19.00, 'shipped', 'debit_card', 'Calle Juárez 180, Guadalajara', 'Calle Juárez 180, Guadalajara', 'Equipo deportivo'),
(11, 299.99, 47.99, 20.00, 30.00, 'completed', 'bank_transfer', 'Av. Corrientes 950, Buenos Aires', 'Av. Corrientes 950, Buenos Aires', 'Bicicleta nueva'),
(12, 65.99, 10.55, 12.00, 6.60, 'completed', 'paypal', 'Providencia 1500, Santiago', 'Providencia 1500, Santiago', 'Perfume'),
(13, 45.99, 7.35, 10.00, 0.00, 'processing', 'credit_card', 'Av. Arequipa 3200, Lima', 'Av. Arequipa 3200, Lima', 'Pelota fútbol'),
(14, 129.98, 20.79, 15.00, 13.00, 'completed', 'debit_card', 'Calle 50 #28-40, Medellín', 'Calle 50 #28-40, Medellín', 'Té y miel'),
(15, 79.99, 12.79, 8.00, 8.00, 'completed', 'credit_card', 'Carrera 80 #45-30, Cali', 'Carrera 80 #45-30, Cali', 'Jeans clásicos')
ON DUPLICATE KEY UPDATE customer_id=VALUES(customer_id), total_amount=VALUES(total_amount), tax_amount=VALUES(tax_amount), shipping_cost=VALUES(shipping_cost), discount_amount=VALUES(discount_amount), status=VALUES(status), payment_method=VALUES(payment_method), shipping_address=VALUES(shipping_address), billing_address=VALUES(billing_address), notes=VALUES(notes);

-- Insertar detalles de órdenes
INSERT INTO orderdetails (order_id, product_id, quantity, price, discount_amount, total_amount) VALUES
-- Orden 1 (Juan Carlos)
(1, 1, 1, 899.99, 90.00, 809.99),
(1, 3, 1, 149.99, 15.00, 134.99),
-- Orden 2 (María Elena)
(2, 6, 2, 24.99, 0.00, 49.98),
(2, 10, 3, 8.99, 0.00, 26.97),
-- Orden 3 (Carlos Alberto)
(3, 11, 4, 29.99, 12.00, 107.96),
(3, 15, 3, 19.99, 6.00, 53.97),
-- Orden 4 (Ana Sofía)
(4, 21, 1, 35.99, 3.60, 32.39),
(4, 22, 2, 18.99, 3.80, 34.18),
-- Orden 5 (Luis Fernando)
(5, 27, 1, 189.99, 19.00, 170.99),
(5, 28, 1, 299.99, 30.00, 269.99),
-- Orden 6 (Carmen Rosa)
(6, 16, 1, 89.99, 0.00, 89.99),
(6, 17, 2, 24.99, 0.00, 49.98),
-- Orden 7 (Diego Alejandro)
(7, 4, 1, 399.99, 40.00, 359.99),
-- Orden 8 (Valentina)
(8, 24, 1, 28.99, 2.90, 26.09),
(8, 25, 1, 65.99, 6.60, 59.39),
-- Orden 9 (Andrés Felipe)
(9, 1, 1, 920.00, 92.00, 828.00),
-- Orden 10 (Isabella)
(10, 27, 1, 189.99, 19.00, 170.99),
-- Orden 11 (Santiago)
(11, 29, 1, 299.99, 30.00, 269.99),
-- Orden 12 (Camila)
(12, 25, 1, 65.99, 6.60, 59.39),
-- Orden 13 (Mateo)
(13, 26, 1, 45.99, 0.00, 45.99),
-- Orden 14 (Sofía)
(14, 9, 1, 16.99, 0.00, 16.99),
(14, 10, 2, 8.99, 0.00, 17.98),
-- Orden 15 (Gabriel)
(15, 12, 1, 79.99, 8.00, 71.99);

-- =====================================================
-- 7. SISTEMA DE AFILIADOS Y COMISIONES
-- =====================================================

-- Insertar afiliados
INSERT INTO affiliates (customer_id, referral_code, commission_rate, level, status, total_referrals, total_commission) VALUES
(1, 'JCR2024001', 0.05, 1, 'active', 3, 125.50),
(3, 'CAM2024002', 0.07, 2, 'active', 5, 289.75),
(5, 'LFH2024003', 0.05, 1, 'active', 2, 87.25),
(7, 'DAV2024004', 0.08, 3, 'active', 8, 456.80),
(9, 'AFC2024005', 0.06, 2, 'active', 4, 198.40),
(11, 'ST2024006', 0.05, 1, 'active', 1, 45.20),
(13, 'MS2024007', 0.07, 2, 'active', 6, 334.60),
(15, 'GR2024008', 0.05, 1, 'active', 2, 78.90),
(17, 'SO2024009', 0.06, 2, 'active', 3, 156.30),
(19, 'AR2024010', 0.05, 1, 'active', 1, 52.50);

-- Insertar referidos
INSERT INTO referrals (affiliate_id, referred_customer_id, commission_earned, status) VALUES
(1, 2, 37.50, 'active'),
(1, 4, 45.00, 'active'),
(1, 6, 43.00, 'active'),
(2, 8, 62.50, 'active'),
(2, 10, 84.25, 'active'),
(2, 12, 33.00, 'active'),
(2, 14, 58.75, 'active'),
(2, 16, 51.25, 'active'),
(3, 18, 42.50, 'active'),
(3, 20, 44.75, 'active'),
(4, 1, 89.60, 'active'),
(4, 3, 76.40, 'active'),
(4, 5, 95.20, 'active'),
(4, 7, 68.50, 'active'),
(4, 9, 72.30, 'active'),
(4, 11, 54.80, 'active'),
(5, 13, 46.20, 'active'),
(5, 15, 58.70, 'active'),
(5, 17, 49.50, 'active'),
(5, 19, 44.00, 'active');

-- =====================================================
-- 8. COMENTARIOS Y CALIFICACIONES
-- =====================================================

-- Insertar comentarios de productos
INSERT INTO comments (product_id, customer_id, comment, rating, status) VALUES
(1, 2, 'Excelente teléfono, muy buena calidad de cámara', 5, 'approved'),
(1, 4, 'Buena relación calidad-precio, recomendado', 4, 'approved'),
(2, 6, 'Perfecta para gaming, funciona sin problemas', 5, 'approved'),
(3, 8, 'Muy buenos auriculares, el sonido es claro', 4, 'approved'),
(6, 10, 'Café delicioso, aroma increíble', 5, 'approved'),
(6, 12, 'Muy buen sabor, lo recomiendo', 4, 'approved'),
(11, 14, 'Camiseta cómoda y de buena calidad', 4, 'approved'),
(12, 16, 'Jeans muy cómodos, talla perfecta', 5, 'approved'),
(21, 18, 'Crema hidratante efectiva, piel suave', 4, 'approved'),
(26, 20, 'Pelota de buena calidad, resistente', 5, 'approved'),
(27, 1, 'Raqueta excelente, muy buena para principiantes', 4, 'approved'),
(16, 3, 'Sábanas suaves y cómodas, muy buena compra', 5, 'approved'),
(9, 5, 'Miel pura y deliciosa, sabor natural', 5, 'approved'),
(24, 7, 'Protector solar efectivo, no deja residuos', 4, 'approved'),
(30, 9, 'Colchoneta perfecta para yoga, antideslizante', 5, 'approved');

-- =====================================================
-- 9. DATOS ADICIONALES DE SOPORTE
-- =====================================================

-- Insertar más productos para completar catálogo
INSERT INTO products (name, description, category_id, unit_id, image_url, status) VALUES
-- Libros y Educación
('Libro de Programación', 'Guía completa de programación en Python', 7, 8, '/images/libro-programacion.jpg', 'active'),
('Cuaderno Universitario', 'Cuaderno de 200 hojas para estudiantes', 7, 8, '/images/cuaderno-universitario.jpg', 'active'),
('Calculadora Científica', 'Calculadora con funciones avanzadas', 7, 8, '/images/calculadora-cientifica.jpg', 'active'),

-- Automóviles
('Aceite de Motor', 'Aceite sintético para motores', 8, 4, '/images/aceite-motor.jpg', 'active'),
('Filtro de Aire', 'Filtro de aire para automóviles', 8, 8, '/images/filtro-aire.jpg', 'active'),
('Llantas', 'Llantas radiales para automóviles', 8, 8, '/images/llantas.jpg', 'active'),

-- Arte y Manualidades
('Set de Pinceles', 'Set completo de pinceles para pintura', 10, 8, '/images/set-pinceles.jpg', 'active'),
('Lienzo Canvas', 'Lienzo preparado para pintura', 10, 8, '/images/lienzo-canvas.jpg', 'active'),
('Arcilla Modelar', 'Arcilla para modelado y escultura', 10, 1, '/images/arcilla-modelar.jpg', 'active');

-- Insertar inventario para los nuevos productos
INSERT INTO inventory (product_id, company_id, quantity, price, cost, min_stock, max_stock, status) VALUES
-- Libros y Más (empresa 7)
(31, 7, 100, 45.99, 28.00, 25, 200, 'active'),
(32, 7, 300, 8.99, 5.50, 100, 500, 'active'),
(33, 7, 50, 89.99, 55.00, 15, 100, 'active'),

-- AutoPartes Colombia (empresa 8)
(34, 8, 200, 24.99, 15.00, 50, 400, 'active'),
(35, 8, 150, 18.99, 12.00, 40, 300, 'active'),
(36, 8, 80, 299.99, 180.00, 20, 150, 'active'),

-- Arte y Manualidades (empresa nueva - usando empresa 10)
(37, 10, 120, 29.99, 18.00, 30, 200, 'active'),
(38, 10, 200, 12.99, 8.00, 50, 400, 'active'),
(39, 10, 100, 15.99, 10.00, 25, 200, 'active');

-- =====================================================
-- 10. FINALIZACIÓN Y VERIFICACIÓN
-- =====================================================

-- Verificar conteos de datos insertados
SELECT 
    'countries' as tabla, COUNT(*) as registros FROM countries
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'companies', COUNT(*) FROM companies
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'orderdetails', COUNT(*) FROM orderdetails
UNION ALL
SELECT 'affiliates', COUNT(*) FROM affiliates
UNION ALL
SELECT 'referrals', COUNT(*) FROM referrals
UNION ALL
SELECT 'comments', COUNT(*) FROM comments
UNION ALL
SELECT 'memberships', COUNT(*) FROM memberships
UNION ALL
SELECT 'benefits', COUNT(*) FROM benefits
UNION ALL
SELECT 'membershipperiods', COUNT(*) FROM membershipperiods
UNION ALL
SELECT 'membershipbenefits', COUNT(*) FROM membershipbenefits;

-- Mensaje final
SELECT '¡Inserción de datos completada exitosamente!' as mensaje;

-- =====================================================
-- FIN DEL SCRIPT DE INSERCIÓN DE DATOS
-- =====================================================
