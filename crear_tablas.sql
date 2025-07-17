CREATE TABLE countries (
    isocode VARCHAR(6) PRIMARY KEY,
    name VARCHAR(50),
    alphatwo VARCHAR(2) UNIQUE,
    alphathree VARCHAR(4) UNIQUE
);


CREATE TABLE stateregions (
    id INTEGER PRIMARY KEY,
    name VARCHAR(60),
    code VARCHAR(10),
    ccc3166 VARCHAR(6),
    country_id VARCHAR(6),
    subdivision_id INTEGER,
    FOREIGN KEY (country_id) REFERENCES countries(isocode)
);

CREATE TABLE subdivisioncategories (
    id INTEGER PRIMARY KEY,
    description VARCHAR(40)
);


CREATE TABLE citiesormunicipalities (
    code VARCHAR(6) PRIMARY KEY,
    name VARCHAR(60),
    statereg_id INTEGER,
    FOREIGN KEY (statereg_id) REFERENCES stateregions(id)
);


CREATE TABLE typesidentifications (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60),
    suffix VARCHAR(5)
);

CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60)
);


CREATE TABLE audiences (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60)
);

CREATE TABLE uniformmeasure (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60)
);


CREATE TABLE companies (
    id VARCHAR(20) PRIMARY KEY,
    typ_id INTEGER,
    name VARCHAR(80),
    code VARCHAR(10),
    category_id INTEGER,
    city_id VARCHAR(6),
    audience_id INTEGER,
    telephone VARCHAR(15),
    email VARCHAR(80),
    FOREIGN KEY (typ_id) REFERENCES typesidentifications(id),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code),
    FOREIGN KEY (audience_id) REFERENCES audiences(id)
);


CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80),
    nidy VARCHAR(6),
    city_id VARCHAR(6),
    audience_id INTEGER,
    telephone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(120),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code),
    FOREIGN KEY (audience_id) REFERENCES audiences(id)
);

CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80),
    detail TEXT,
    price DOUBLE,
    category_id INTEGER,
    image VARCHAR(80),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);


CREATE TABLE companyproducts (
    company_id VARCHAR(20),
    product_id INTEGER,
    price DOUBLE,
    unitmeasure_id INTEGER,
    PRIMARY KEY (company_id, product_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (unitmeasure_id) REFERENCES uniformmeasure(id)
);
CREATE TABLE favorites (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    company_id VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (company_id) REFERENCES companies(id)
);
CREATE TABLE details_favorites (
    id INTEGER PRIMARY KEY,
    favorite_id INTEGER,
    product_id INTEGER,
    FOREIGN KEY (favorite_id) REFERENCES favorites(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE TABLE memberships (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50),
    description TEXT
);
CREATE TABLE periods (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50)
);
CREATE TABLE membershipperiods (
    membership_id INTEGER,
    period_id INTEGER,
    price DOUBLE,
    PRIMARY KEY (membership_id, period_id),
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (period_id) REFERENCES periods(id)
);
CREATE TABLE benefits (
    id INTEGER PRIMARY KEY,
    description VARCHAR(80),
    detail TEXT
);
CREATE TABLE membershipbenefits (
    membership_id INTEGER,
    period_id INTEGER,
    audience_id INTEGER,
    benefit_id INTEGER,
    PRIMARY KEY (membership_id, period_id, audience_id, benefit_id),
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (period_id) REFERENCES periods(id),
    FOREIGN KEY (audience_id) REFERENCES audiences(id),
    FOREIGN KEY (benefit_id) REFERENCES benefits(id)
);
CREATE TABLE audiencebenefits (
    audience_id INTEGER,
    benefit_id INTEGER,
    PRIMARY KEY (audience_id, benefit_id),
    FOREIGN KEY (audience_id) REFERENCES audiences(id),
    FOREIGN KEY (benefit_id) REFERENCES benefits(id)
);
CREATE TABLE polls (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80),
    description TEXT,
    isactive BOOLEAN,
    categorypoll_id INTEGER,
    FOREIGN KEY (categorypoll_id) REFERENCES categories_polls(id)
);
CREATE TABLE categories_polls (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80)
);
CREATE TABLE rates (
    customer_id INTEGER,
    company_id VARCHAR(20),
    poll_id INTEGER,
    daterating DATETIME,
    rating DOUBLE,
    PRIMARY KEY (customer_id, company_id, poll_id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);
CREATE TABLE quality_products (
    product_id INTEGER,
    customer_id INTEGER,
    poll_id INTEGER,
    company_id VARCHAR(20),
    daterating DATETIME,
    rating DOUBLE,
    PRIMARY KEY (product_id, customer_id, poll_id, company_id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id),
    FOREIGN KEY (company_id) REFERENCES companies(id)
);
