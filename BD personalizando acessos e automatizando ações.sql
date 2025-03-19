CREATE database IF NOT EXISTS acesso_automatizado_db;
USE acesso_automatizado_db;

-- Localidades
CREATE TABLE IF NOT EXISTS locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO locations (name) VALUES
('São Paulo'), ('Rio de Janeiro'), ('Belo Horizonte');

-- Departamentos
CREATE TABLE IF NOT EXISTS departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location_id INT,
    manager_id INT,
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

INSERT INTO departments (name, location_id) VALUES
('TI', 1),
('Financeiro', 2),
('RH', 3);

-- Empregados
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT,
    is_manager BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

INSERT INTO employees (name, department_id, is_manager) VALUES
('Carlos Silva', 1, TRUE),
('Ana Pereira', 1, FALSE),
('Marcos Lima', 2, TRUE),
('Juliana Costa', 2, FALSE),
('Renata Souza', 3, TRUE),
('Paulo Mendes', 3, FALSE);

-- Vincula gerente após employees existirem
ALTER TABLE departments
    ADD CONSTRAINT fk_manager
    FOREIGN KEY (manager_id) REFERENCES employees(id);

-- Projetos
CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

INSERT INTO projects (name, department_id) VALUES
('Sistema Interno', 1),
('Auditoria 2024', 2),
('Treinamento RH', 3);

-- Atribuição de projetos
CREATE TABLE IF NOT EXISTS project_assignments (
    project_id INT,
    employee_id INT,
    PRIMARY KEY (project_id, employee_id),
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

INSERT INTO project_assignments (project_id, employee_id) VALUES
(1, 1), (1, 2),
(2, 3), (2, 4),
(3, 5), (3, 6),
(3, 1);

-- Dependentes
CREATE TABLE IF NOT EXISTS dependents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

INSERT INTO dependents (employee_id, name, relationship) VALUES
(1, 'Lucas Silva', 'Filho'),
(1, 'Mariana Silva', 'Filha'),
(3, 'João Lima', 'Filho'),
(6, 'Pedro Mendes', 'Filho');

UPDATE departments SET manager_id = 1 WHERE id = 1;
UPDATE departments SET manager_id = 3 WHERE id = 2;
UPDATE departments SET manager_id = 5 WHERE id = 3;

-- VIEWS PERSONALIZADAS (PARTE 1)

-- 1. Número de empregados por departamento e localidade
CREATE OR REPLACE VIEW vw_empregados_por_departamento_localidade AS
SELECT 
    d.name AS departamento,
    l.name AS localidade,
    COUNT(e.id) AS total_empregados
FROM employees e
JOIN departments d ON e.department_id = d.id
JOIN locations l ON d.location_id = l.id
GROUP BY d.name, l.name;

-- 2. Lista de departamentos e seus gerentes
CREATE OR REPLACE VIEW vw_departamentos_gerentes AS
SELECT 
    d.name AS departamento,
    e.name AS gerente
FROM departments d
JOIN employees e ON d.manager_id = e.id;

-- 3. Projetos com maior número de empregados
CREATE OR REPLACE VIEW vw_projetos_com_mais_empregados AS
SELECT 
    p.name AS projeto,
    COUNT(pa.employee_id) AS total_empregados
FROM projects p
JOIN project_assignments pa ON p.id = pa.project_id
GROUP BY p.name
ORDER BY total_empregados DESC;

-- 4. Lista de projetos, departamentos e gerentes
CREATE OR REPLACE VIEW vw_projetos_departamentos_gerentes AS
SELECT 
    p.name AS projeto,
    d.name AS departamento,
    e.name AS gerente
FROM projects p
JOIN departments d ON p.department_id = d.id
JOIN employees e ON d.manager_id = e.id;

-- 5. Empregados com dependentes e se são gerentes
CREATE OR REPLACE VIEW vw_empregados_com_dependentes_e_se_sao_gerentes AS
SELECT 
    e.name AS empregado,
    CASE WHEN COUNT(d.id) > 0 THEN 'Sim' ELSE 'Não' END AS possui_dependentes,
    CASE WHEN e.is_manager = 1 THEN 'Sim' ELSE 'Não' END AS e_gerente
FROM employees e
LEFT JOIN dependents d ON e.id = d.employee_id
GROUP BY e.id;

-- USUÁRIOS E PERMISSÕES (PARTE 1)

CREATE USER IF NOT EXISTS 'gerente'@'localhost' IDENTIFIED BY 'senha123';
CREATE USER IF NOT EXISTS 'empregado'@'localhost' IDENTIFIED BY 'senha123';

-- Permissões para gerente
GRANT SELECT ON vw_empregados_por_departamento_localidade TO 'gerente'@'localhost';
GRANT SELECT ON vw_departamentos_gerentes TO 'gerente'@'localhost';
GRANT SELECT ON vw_projetos_com_mais_empregados TO 'gerente'@'localhost';
GRANT SELECT ON vw_projetos_departamentos_gerentes TO 'gerente'@'localhost';
GRANT SELECT ON vw_empregados_com_dependentes_e_se_sao_gerentes TO 'gerente'@'localhost';

-- Permissões para empregado
GRANT SELECT ON vw_projetos_com_mais_empregados TO 'empregado'@'localhost';
GRANT SELECT ON vw_empregados_com_dependentes_e_se_sao_gerentes TO 'empregado'@'localhost';

FLUSH PRIVILEGES;

-- CENÁRIO E-COMMERCE + TRIGGERS (PARTE 2)

-- Usuários do e-commerce
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
('Alice Santos', 'alice@email.com'),
('Bruno Lima', 'bruno@email.com');

-- Colaboradores do e-commerce
CREATE TABLE IF NOT EXISTS employees_ecom (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    role VARCHAR(50),
    salary DECIMAL(10,2),
    hired_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employees_ecom (name, role, salary) VALUES
('Carla Souza', 'Analista', 4000.00),
('Diego Ramos', 'Supervisor', 6000.00);

-- Logs de usuários excluídos
CREATE TABLE IF NOT EXISTS deleted_users (
    user_id INT,
    name VARCHAR(100),
    email VARCHAR(100),
    deleted_at DATETIME
);

-- Histórico de salário
CREATE TABLE IF NOT EXISTS salary_history (
    employee_id INT,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    updated_at DATETIME
);

-- TRIGGER 1 – Antes de excluir usuário
DELIMITER $$
CREATE TRIGGER trg_before_delete_user
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    INSERT INTO deleted_users (user_id, name, email, deleted_at)
    VALUES (OLD.id, OLD.name, OLD.email, NOW());
END $$
DELIMITER ;

-- TRIGGER 2 – Antes de atualizar salário
DELIMITER $$
CREATE TRIGGER trg_before_update_salary
BEFORE UPDATE ON employees_ecom
FOR EACH ROW
BEGIN
    IF OLD.salary != NEW.salary THEN
        INSERT INTO salary_history (employee_id, old_salary, new_salary, updated_at)
        VALUES (OLD.id, OLD.salary, NEW.salary, NOW());
    END IF;
END $$
DELIMITER ;