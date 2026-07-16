-- ============================================================
-- БАЗА ДАННЫХ «ТУРИЗМ» 
-- Программа PostgreSQL
-- АВТОР: Карина Сидорчук
-- ============================================================

-- Удаляем старые таблицы
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS hotels CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS clients CASCADE;

-- ============================================================
-- ТАБЛИЦЫ-СПРАВОЧНИКИ 
-- ============================================================

-- 1. Страны
CREATE TABLE countries (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    visa BOOLEAN DEFAULT FALSE
);

-- 2. Клиенты
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT
);

-- 3. Отели
CREATE TABLE hotels (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    country_id INTEGER REFERENCES countries(id),
    stars INTEGER DEFAULT 3
);

-- 4. Услуги
CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    price INTEGER NOT NULL
);

-- ============================================================
-- ТАБЛИЦА ПЕРЕМЕННОЙ ИНФОРМАЦИИ — ЗАКАЗЫ
-- ============================================================

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    
    -- Внешние ключи (связи со справочниками)
    client_id INTEGER REFERENCES clients(id),
    country_id INTEGER REFERENCES countries(id),
    hotel_id INTEGER REFERENCES hotels(id),
    service_id INTEGER REFERENCES services(id),
    
    -- Данные заказа
    tour_date DATE NOT NULL,
    days_count INTEGER NOT NULL,
    people_count INTEGER NOT NULL,
    total_price INTEGER NOT NULL,
    status TEXT DEFAULT 'Новый'
);

-- ============================================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ============================================================

-- Страны
INSERT INTO countries (name, visa) VALUES
('Россия', FALSE),
('Турция', FALSE),
('Египет', TRUE);

-- Клиенты
INSERT INTO clients (name, phone, email) VALUES
('Иван Иванов', '+7-912-345-67-89', 'ivanov@mail.ru'),
('Мария Петрова', '+7-913-456-78-90', 'petrova@mail.ru');

-- Отели
INSERT INTO hotels (name, country_id, stars) VALUES
('Рэдиссон', 1, 5),
('Золотая бухта', 1, 4),
('Sunset Paradise', 2, 5);

-- Услуги
INSERT INTO services (name, price) VALUES
('Страховка', 1500),
('Трансфер', 3000),
('Экскурсия', 2500);

-- Заказы
INSERT INTO orders (client_id, country_id, hotel_id, service_id, tour_date, days_count, people_count, total_price, status) VALUES
(1, 1, 1, 2, '2025-07-10', 7, 2, 85000, 'Подтверждён'),
(2, 2, 3, 1, '2025-08-05', 10, 3, 258000, 'Новый');

-- ============================================================
-- ПРИМЕРЫ ЗАПРОСОВ (для проверки)
-- ============================================================

-- 1. Все заказы с именами клиентов и названиями стран
SELECT 
    o.id AS "Номер заказа",
    c.name AS "Клиент",
    co.name AS "Страна",
    h.name AS "Отель",
    s.name AS "Услуга",
    o.tour_date AS "Дата тура",
    o.total_price AS "Цена",
    o.status AS "Статус"
FROM orders o
JOIN clients c ON o.client_id = c.id
JOIN countries co ON o.country_id = co.id
JOIN hotels h ON o.hotel_id = h.id
LEFT JOIN services s ON o.service_id = s.id;

-- 2. Сколько заказов в каждой стране
SELECT 
    co.name AS "Страна",
    COUNT(o.id) AS "Количество заказов"
FROM orders o
JOIN countries co ON o.country_id = co.id
GROUP BY co.name;

-- ============================================================
-- ДОПОЛНИТЕЛЬНЫЕ ЗАПРОСЫ (ДОМАШНЕЕ ЗАДАНИЕ)
-- ============================================================

-- 3. Найти самый дорогой заказ (с именем клиента)
SELECT 
    c.name AS "Клиент",
    o.total_price AS "Стоимость",
    co.name AS "Страна",
    o.days_count || ' дней' AS "Длительность"
FROM orders o
JOIN clients c ON o.client_id = c.id
JOIN countries co ON o.country_id = co.id
WHERE o.total_price = (SELECT MAX(total_price) FROM orders);

-- 4. Подсчитать среднюю стоимость тура по странам (с сортировкой по убыванию)
SELECT 
    co.name AS "Страна",
    COUNT(o.id) AS "Количество заказов",
    ROUND(AVG(o.total_price), 0) AS "Средняя цена, руб.",
    MIN(o.total_price) AS "Минимальная цена",
    MAX(o.total_price) AS "Максимальная цена"
FROM orders o
JOIN countries co ON o.country_id = co.id
GROUP BY co.name
ORDER BY AVG(o.total_price) DESC;

-- 5. Найти клиентов, которые уже путешествовали или планируют (все заказы с деталями)
SELECT 
    c.name AS "Клиент",
    c.phone AS "Телефон",
    COUNT(o.id) AS "Количество туров",
    SUM(o.total_price) AS "Общая стоимость всех туров",
    STRING_AGG(DISTINCT co.name, ', ') AS "Посещённые страны",
    MAX(o.tour_date) AS "Ближайший тур"
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
LEFT JOIN countries co ON o.country_id = co.id
GROUP BY c.id, c.name, c.phone
HAVING COUNT(o.id) > 0
ORDER BY SUM(o.total_price) DESC;