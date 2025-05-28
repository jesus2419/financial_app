-- =========================
-- Tabla: accounts
-- =========================
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL CHECK(type IN ('cash', 'debit', 'credit')),
    bank_name TEXT,
    credit_limit REAL,
    cut_off_day INTEGER,
    description TEXT
);

-- =========================
-- Tabla: categories
-- =========================
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
    icon TEXT,
    color TEXT
);

-- Categorías iniciales
INSERT INTO categories (name, type, icon, color) VALUES
-- Ingresos
('Sueldo', 'income', '💼', '#4CAF50'),
('Transferencia', 'income', '🔁', '#2196F3'),
('Venta', 'income', '🛒', '#8BC34A'),

-- Gastos
('Alimentos', 'expense', '🍽️', '#FF5722'),
('Gasolina', 'expense', '⛽', '#795548'),
('Renta', 'expense', '🏠', '#9C27B0'),
('Deuda', 'expense', '📉', '#F44336'),
('Entretenimiento', 'expense', '🎮', '#03A9F4'),
('Ahorro', 'expense', '💰', '#FF9800'),
('Educación', 'expense', '📚', '#3F51B5'),
('Salud', 'expense', '🏥', '#E91E63');

-- =========================
-- Tabla: transactions
-- =========================
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER,
    description TEXT,
    date TEXT NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- =========================
-- Tabla: transfers
-- =========================
CREATE TABLE transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_account_id INTEGER NOT NULL,
    to_account_id INTEGER NOT NULL,
    amount REAL NOT NULL CHECK(amount > 0),
    date TEXT NOT NULL,
    description TEXT,
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(id)
);

-- =========================
-- Tabla: mandatory_payments
-- =========================
CREATE TABLE mandatory_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER,
    name TEXT NOT NULL,
    amount REAL NOT NULL CHECK(amount > 0),
    due_date TEXT NOT NULL,
    frequency TEXT CHECK(frequency IN ('once', 'weekly', 'biweekly', 'monthly')) DEFAULT 'once',
    category_id INTEGER,
    notes TEXT,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- =========================
-- Tabla: mandatory_payment_logs
-- =========================
CREATE TABLE mandatory_payment_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mandatory_payment_id INTEGER NOT NULL,
    transaction_id INTEGER,
    paid_amount REAL NOT NULL,
    paid_date TEXT NOT NULL,
    FOREIGN KEY (mandatory_payment_id) REFERENCES mandatory_payments(id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);
