
CREATE TABLE malls (
    mall_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(40),
    district VARCHAR(40)
);

CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(40) NOT NULL
);

CREATE TABLE employee_types (
    emp_type_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_type_name VARCHAR(40) NOT NULL
);

CREATE TABLE brand_categories (
    brand_category_id INT AUTO_INCREMENT PRIMARY KEY,
    br_category_name VARCHAR(40) NOT NULL
);

CREATE TABLE bill_categories (
    bill_category_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_category_name VARCHAR(40) NOT NULL
);

CREATE TABLE income_categories (
    income_category_id INT AUTO_INCREMENT PRIMARY KEY,
    income_category_name VARCHAR(40) NOT NULL
);

CREATE TABLE shifts (
    shift_id INT AUTO_INCREMENT PRIMARY KEY,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT chk_shift_times_valid CHECK (end_time > start_time)
);

CREATE TABLE brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_category_id INT,
    brand_name VARCHAR(40) NOT NULL,
    FOREIGN KEY (brand_category_id) REFERENCES brand_categories(brand_category_id)
);

CREATE TABLE stores (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    mall_id INT,
    name VARCHAR(40) NOT NULL,
    square_meters INT NOT NULL,
    floor INT NOT NULL,
    is_open BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_store_sqm_positive CHECK (square_meters > 0),
    FOREIGN KEY (mall_id) REFERENCES malls(mall_id)
);

CREATE TABLE store_brands (
    store_id INT,
    brand_id INT,
    PRIMARY KEY (store_id, brand_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE CASCADE,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE CASCADE
);

CREATE TABLE employees (
    tc_id CHAR(11) PRIMARY KEY,
    department_id INT,
    emp_type_id INT,
    store_id INT,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(40) NOT NULL,
    salary DECIMAL(12,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    hire_date DATE NOT NULL,
    CONSTRAINT chk_employee_salary_positive CHECK (salary > 0),
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (emp_type_id) REFERENCES employee_types(emp_type_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

CREATE TABLE employee_phones (
    phone_id INT AUTO_INCREMENT PRIMARY KEY,
    tc_id CHAR(11),
    phone_number VARCHAR(15) NOT NULL,
    phone_type VARCHAR(20) DEFAULT 'Mobil',
    FOREIGN KEY (tc_id) REFERENCES employees(tc_id) ON DELETE CASCADE
);

CREATE TABLE employee_emails (
    email_id INT AUTO_INCREMENT PRIMARY KEY,
    tc_id CHAR(11),
    email_address VARCHAR(100) NOT NULL,
    email_type VARCHAR(20) DEFAULT 'İş',
    FOREIGN KEY (tc_id) REFERENCES employees(tc_id) ON DELETE CASCADE
);

CREATE TABLE employee_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    tc_id CHAR(11),
    city VARCHAR(40),
    district VARCHAR(40),
    street VARCHAR(100),
    apartment_no VARCHAR(20),
    FOREIGN KEY (tc_id) REFERENCES employees(tc_id) ON DELETE CASCADE
);

CREATE TABLE employee_shifts (
    tc_id CHAR(11),
    shift_id INT,
    shift_date DATE NOT NULL,
    PRIMARY KEY (tc_id, shift_id, shift_date),
    FOREIGN KEY (tc_id) REFERENCES employees(tc_id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES shifts(shift_id)
);

CREATE TABLE maintenance_logs (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT,
    tc_id CHAR(11),
    maintenance_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    issue_desc VARCHAR(255) NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (tc_id) REFERENCES employees(tc_id)
);

CREATE TABLE leases (
    lease_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(12,2) NOT NULL,
    is_leases_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_lease_rent_positive CHECK (monthly_rent > 0),
    CONSTRAINT chk_lease_dates_valid CHECK (end_date > start_date),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

CREATE TABLE bills (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT,
    bill_category_id INT,
    amount DECIMAL(12,2) NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    is_bill_paid BOOLEAN DEFAULT FALSE,
    paid_at DATETIME NULL,
    CONSTRAINT chk_bill_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_bill_dates_valid CHECK (due_date >= issue_date),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (bill_category_id) REFERENCES bill_categories(bill_category_id)
);

CREATE TABLE billboards (
    ad_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT,
    floor INT,
    daily_rate DECIMAL(12,2) NOT NULL,
    is_bill_board_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_billboard_rate_positive CHECK (daily_rate > 0),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

CREATE TABLE revenues (
    revenue_id INT AUTO_INCREMENT PRIMARY KEY,
    mall_id INT,
    income_category_id INT,
    amount DECIMAL(12,2) NOT NULL,
    revenue_date DATE NOT NULL,
    CONSTRAINT chk_revenue_amount_positive CHECK (amount > 0),
    FOREIGN KEY (mall_id) REFERENCES malls(mall_id),
    FOREIGN KEY (income_category_id) REFERENCES income_categories(income_category_id)
);


CREATE INDEX index_employees_name ON employees(first_name, last_name);
CREATE INDEX index_stores_status ON stores(is_open);

CREATE OR REPLACE VIEW view_active_employee_directory AS
SELECT
    e.first_name,
    e.last_name,
    d.department_name,
    et.emp_type_name,
    s.name AS store_name,
    p.phone_number
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
LEFT JOIN employee_types et ON e.emp_type_id = et.emp_type_id
LEFT JOIN stores s ON e.store_id = s.store_id
LEFT JOIN employee_phones p ON e.tc_id = p.tc_id
WHERE e.is_active = TRUE;

CREATE OR REPLACE VIEW view_department_stats AS
SELECT
    d.department_id,
    d.department_name,
    COUNT(e.tc_id) AS total_employees
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

CREATE OR REPLACE VIEW view_all_stores AS
SELECT
    s.store_id,
    m.name AS mall_name,
    s.name AS store_name,
    s.square_meters,
    s.floor,
    s.is_open
FROM stores s
JOIN malls m ON s.mall_id = m.mall_id;


DELIMITER //

CREATE TRIGGER trg_check_minimum_salary
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.salary < 17000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Salary cannot be less than the minimum wage (17000)!';
    END IF;
END //
DELIMITER ;


DELIMITER //


CREATE PROCEDURE sp_add_store_with_brand (
    IN p_mall_id INT,
    IN p_name VARCHAR(40),
    IN p_sqm INT,
    IN p_floor INT,
    IN p_is_open BOOLEAN,
    IN p_brand_id INT
)
BEGIN
    DECLARE v_new_store_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO stores (mall_id, name, square_meters, floor, is_open)
        VALUES (p_mall_id, p_name, p_sqm, p_floor, p_is_open);


        SET v_new_store_id = LAST_INSERT_ID();


        INSERT INTO store_brands (store_id, brand_id)
        VALUES (v_new_store_id, p_brand_id);
    COMMIT;
END //


CREATE PROCEDURE sp_hire_new_employee (
    IN p_tc_id CHAR(11),
    IN p_first_name VARCHAR(40),
    IN p_last_name VARCHAR(40),
    IN p_department_id INT,
    IN p_type_id INT,
    IN p_store_id INT,
    IN p_salary DECIMAL(12,2),
    IN p_phone_number VARCHAR(15),
    IN p_city VARCHAR(40),
    IN p_district VARCHAR(40),
    IN p_street VARCHAR(100),
    IN p_apartment_no VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO employees (tc_id, first_name, last_name, department_id, emp_type_id, store_id, salary, hire_date)
        VALUES (p_tc_id, p_first_name, p_last_name, p_department_id, p_type_id, p_store_id, p_salary, CURRENT_DATE);

        INSERT INTO employee_phones (tc_id, phone_number, phone_type)
        VALUES (p_tc_id, p_phone_number, 'Mobil');

        INSERT INTO employee_addresses (tc_id, city, district, street, apartment_no)
        VALUES (p_tc_id, p_city, p_district, p_street, p_apartment_no);
    COMMIT;
END //

DELIMITER ;



INSERT INTO malls (name, city, district)
VALUES ('NCity', 'Izmit', 'Kocaeli');


INSERT INTO departments (department_name)
VALUES ('Management'), ('Security'), ('Cleaning'), ('IT'), ('Sales');


INSERT INTO employee_types (emp_type_name)
VALUES ('Full-Time'), ('Part-Time'), ('Contractor');


INSERT INTO brand_categories (br_category_name)
VALUES ('Fashion'), ('Electronics'), ('Food & Beverage'), ('Cosmetics');


INSERT INTO bill_categories (bill_category_name)
VALUES ('Electricity'), ('Water'), ('Internet & Phone'), ('Heating');


INSERT INTO income_categories (income_category_name)
VALUES ('Rent Revenue'), ('Billboard Revenue'), ('Event Ticket'), ('Parking');


INSERT INTO shifts (start_time, end_time)
VALUES ('08:00:00', '16:00:00'), ('16:00:00', '23:59:00');



INSERT INTO brands (brand_category_id, brand_name) VALUES
(1, 'Zara'),
(2, 'Apple'),
(3, 'Starbucks'),
(4, 'Sephora');


INSERT INTO stores (mall_id, name, square_meters, floor, is_open) VALUES
(1, 'Zara', 650, 1, TRUE),
(1, 'Apple Center', 320, 1, TRUE),
(1, 'Starbucks Lounge', 150, 0, TRUE),
(1, 'Sephora Boutique', 200, 2, FALSE);





INSERT INTO employees (tc_id, department_id, emp_type_id, store_id, first_name, last_name, salary, is_active, hire_date) VALUES
('10000000001', 1, 1, NULL, 'Michael', 'Scott', 45000.00, TRUE, '2022-01-10'),
('10000000002', 1, 1, NULL, 'Sarah', 'Connor', 42000.00, TRUE, '2022-02-15'),
('10000000003', 4, 1, NULL, 'Elliot', 'Alderson', 38000.00, TRUE, '2022-05-20'),
('10000000004', 4, 1, NULL, 'Grace', 'Hopper', 39000.00, TRUE, '2022-06-11'),
('10000000005', 2, 1, NULL, 'John', 'Wick', 25000.00, TRUE, '2023-01-05'),
('10000000006', 2, 2, NULL, 'Bruce', 'Wayne', 18000.00, TRUE, '2023-03-12'),
('10000000007', 2, 1, NULL, 'Clark', 'Kent', 25000.00, TRUE, '2023-04-18'),
('10000000008', 3, 1, NULL, 'Walter', 'White', 20000.00, TRUE, '2023-07-22'),
('10000000009', 3, 2, NULL, 'Jesse', 'Pinkman', 17500.00, TRUE, '2023-08-30'),
('10000000010', 3, 3, NULL, 'Marie', 'Curie', 19000.00, TRUE, '2024-01-10'),
('10000000011', 5, 1, 1, 'Rachel', 'Green', 28000.00, TRUE, '2024-02-14'),
('10000000012', 5, 1, 1, 'Monica', 'Geller', 29000.00, TRUE, '2024-02-15'),
('10000000013', 5, 2, 1, 'Phoebe', 'Buffay', 18500.00, TRUE, '2024-03-01'),
('10000000014', 5, 1, 2, 'Steve', 'Jobs', 35000.00, TRUE, '2024-04-10'),
('10000000015', 5, 1, 2, 'Tim', 'Cook', 34000.00, TRUE, '2024-04-12'),
('10000000016', 5, 2, 2, 'Ada', 'Lovelace', 19500.00, TRUE, '2024-05-20'),
('10000000017', 5, 1, 3, 'Howard', 'Schultz', 26000.00, TRUE, '2024-06-05'),
('10000000018', 5, 2, 3, 'Penny', 'Hofstadter', 18000.00, TRUE, '2024-06-15'),
('10000000019', 5, 1, 4, 'Estee', 'Lauder', 27000.00, FALSE, '2024-07-01'),
('10000000020', 5, 2, 4, 'Coco', 'Chanel', 17500.00, TRUE, '2024-07-10');



INSERT INTO employee_phones (tc_id, phone_number, phone_type) VALUES
('10000000001', '555-0101', 'Mobile'), ('10000000002', '555-0102', 'Mobil'),
('10000000003', '555-0103', 'Mobile'), ('10000000004', '555-0104', 'Mobil'),
('10000000005', '555-0105', 'Mobile'), ('10000000006', '555-0106', 'Mobil'),
('10000000007', '555-0107', 'Mobile'), ('10000000008', '555-0108', 'Mobil'),
('10000000009', '555-0109', 'Mobile'), ('10000000010', '555-0110', 'Mobil'),
('10000000011', '555-0111', 'Mobile'), ('10000000012', '555-0112', 'Mobil'),
('10000000013', '555-0113', 'Mobile'), ('10000000014', '555-0114', 'Mobil'),
('10000000015', '555-0115', 'Mobile'), ('10000000016', '555-0116', 'Mobil'),
('10000000017', '555-0117', 'Mobile'), ('10000000018', '555-0118', 'Mobil'),
('10000000019', '555-0119', 'Mobile'), ('10000000020', '555-0120', 'Mobil');


INSERT INTO employee_emails (tc_id, email_address, email_type) VALUES
('10000000001', 'm.scott@mall.com', 'work'), ('10000000014', 'steve.j@apple.com', 'work');


INSERT INTO employee_addresses (tc_id, city, district, street, apartment_no) VALUES
('10000000001', 'New York', 'Brooklyn', '5th Avenue', '12B'),
('10000000014', 'New York', 'Queens', 'Main Street', '4A');


INSERT INTO employee_shifts (tc_id, shift_id, shift_date) VALUES
('10000000005', 1, '2024-10-01'), ('10000000006', 2, '2024-10-01'),
('10000000011', 1, '2024-10-01'), ('10000000014', 1, '2024-10-01');




INSERT INTO maintenance_logs (store_id, tc_id, maintenance_date, issue_desc, is_resolved) VALUES
(2, '10000000003', '2024-09-15 10:00:00', 'AC unit is leaking water', TRUE),
(4, '10000000004', '2024-09-28 14:30:00', 'Front glass door mechanism broken', FALSE);



INSERT INTO leases (store_id, start_date, end_date, monthly_rent, is_leases_active) VALUES
(1, '2023-01-01', '2028-01-01', 120000.00, TRUE),
(2, '2023-06-01', '2026-06-01', 95000.00, TRUE),
(3, '2024-01-01', '2027-01-01', 45000.00, TRUE);



INSERT INTO bills (store_id, bill_category_id, amount, issue_date, due_date, is_bill_paid, paid_at) VALUES
(1, 1, 4500.50, '2024-09-01', '2024-09-15', TRUE, '2024-09-10 09:15:00'),
(2, 1, 3200.00, '2024-09-01', '2024-09-15', TRUE, '2024-09-12 14:00:00'),
(3, 2, 850.75, '2024-08-01', '2024-08-15', FALSE, NULL),
(4, 1, 1200.00, '2024-08-01', '2024-08-15', FALSE, NULL);



INSERT INTO billboards (store_id, floor, daily_rate, is_bill_board_active) VALUES
(1, 1, 500.00, TRUE),
(2, 1, 650.00, TRUE);



INSERT INTO revenues (mall_id, income_category_id, amount, revenue_date) VALUES
(1, 1, 120000.00, '2024-09-01'),
(1, 1, 95000.00, '2024-09-01'),
(1, 3, 15000.00, '2024-09-15');

