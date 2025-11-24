-- Library Management System Database Schema
-- This script creates all necessary tables for a library management system

-- Create database (uncomment if needed)
-- CREATE DATABASE library_management;
-- USE library_management;

-- Users table for both regular users and admins
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    user_type ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Authors table
CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Books table
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(200) NOT NULL,
    publisher VARCHAR(100),
    publication_year YEAR,
    genre VARCHAR(50),
    description TEXT,
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Book authors relationship table
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    author_order INT DEFAULT 1,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Book transactions (borrowing/returning)
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    transaction_type ENUM('borrow', 'return') NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date DATE,
    return_date DATE NULL,
    status ENUM('active', 'returned', 'overdue') DEFAULT 'active',
    fine_amount DECIMAL(10,2) DEFAULT 0.00,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

-- Categories for better book organization
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- Book categories relationship
CREATE TABLE book_categories (
    book_id INT,
    category_id INT,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- Reservations for books that are currently borrowed
CREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'fulfilled', 'cancelled') DEFAULT 'pending',
    notification_sent BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

-- Fines for overdue books
CREATE TABLE fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    transaction_id INT NOT NULL,
    fine_amount DECIMAL(10,2) NOT NULL,
    fine_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    paid_date TIMESTAMP NULL,
    status ENUM('pending', 'paid') DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE
);

-- Insert sample categories
INSERT INTO categories (category_name, description) VALUES
('Fiction', 'Novels and fictional works'),
('Non-Fiction', 'Educational and informational books'),
('Science', 'Scientific literature and research'),
('History', 'Historical books and biographies'),
('Technology', 'Computer science and technology books'),
('Literature', 'Classic and contemporary literature'),
('Children', 'Books for children and young adults'),
('Reference', 'Dictionaries, encyclopedias, and reference materials');

-- Insert sample admin user
INSERT INTO users (username, email, password_hash, first_name, last_name, user_type) VALUES
('admin', 'admin@library.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Library', 'Administrator', 'admin');

-- Insert sample regular users
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address) VALUES
('john_doe', 'john@email.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John', 'Doe', '555-0123', '123 Main St, City'),
('jane_smith', 'jane@email.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Jane', 'Smith', '555-0456', '456 Oak Ave, City'),
('bob_wilson', 'bob@email.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Bob', 'Wilson', '555-0789', '789 Pine St, City');

-- Insert sample authors
INSERT INTO authors (first_name, last_name, biography) VALUES
('Robert', 'Martin', 'Software engineer and author, known for Clean Code and Clean Architecture'),
('David', 'Thomas', 'Software engineer and co-author of The Pragmatic Programmer'),
('Harper', 'Lee', 'American novelist best known for To Kill a Mockingbird'),
('Jane', 'Austen', 'English novelist known for her social commentary and romantic fiction'),
('F. Scott', 'Fitzgerald', 'American novelist and short story writer'),
('Paulo', 'Coelho', 'Brazilian lyricist and novelist'),
('George', 'Orwell', 'English novelist, essayist, and critic'),
('C.S.', 'Lewis', 'British writer and lay theologian'),
('J.R.R.', 'Tolkien', 'English writer, poet, and philologist');

-- Insert sample books
INSERT INTO books (isbn, title, publisher, publication_year, genre, description, total_copies, available_copies, location) VALUES
('978-0134685991', 'Clean Code', 'Prentice Hall', 2008, 'Technology', 'A handbook of agile software craftsmanship', 3, 3, 'Tech Section A1'),
('978-0132350884', 'Clean Architecture', 'Prentice Hall', 2017, 'Technology', 'A craftsman guide to software structure and design', 2, 2, 'Tech Section A2'),
('978-0201616224', 'The Pragmatic Programmer', 'Addison-Wesley', 1999, 'Technology', 'Your journey to mastery', 2, 2, 'Tech Section B1'),
('978-0061120084', 'To Kill a Mockingbird', 'J.B. Lippincott & Co.', 1960, 'Literature', 'A gripping tale of racial injustice and childhood innocence', 4, 4, 'Literature Section C1'),
('978-0141439518', 'Pride and Prejudice', 'T. Egerton', 1813, 'Literature', 'A romantic novel of manners', 3, 3, 'Literature Section C2'),
('978-0307277671', 'The Great Gatsby', 'Charles Scribner Sons', 1925, 'Literature', 'A tale of the fabulously wealthy Jay Gatsby', 2, 2, 'Literature Section C3'),
('978-0062315007', 'The Alchemist', 'HarperOne', 1988, 'Fiction', 'A philosophical book about a young shepherd', 3, 3, 'Fiction Section D1'),
('978-0143127741', '1984', 'Secker & Warburg', 1949, 'Fiction', 'A dystopian social science fiction novel', 2, 2, 'Fiction Section D2'),
('978-0061122415', 'The Chronicles of Narnia', 'Geoffrey Bles', 1950, 'Children', 'A series of fantasy novels', 5, 5, 'Children Section E1'),
('978-0544003415', 'The Lord of the Rings', 'Allen & Unwin', 1954, 'Fiction', 'An epic high-fantasy novel', 3, 3, 'Fiction Section D3');

-- Link books to authors
INSERT INTO book_authors (book_id, author_id, author_order) VALUES
(1, 1, 1), -- Clean Code by Robert Martin
(2, 1, 1), -- Clean Architecture by Robert Martin
(3, 2, 1), -- The Pragmatic Programmer by David Thomas
(4, 3, 1), -- To Kill a Mockingbird by Harper Lee
(5, 4, 1), -- Pride and Prejudice by Jane Austen
(6, 5, 1), -- The Great Gatsby by F. Scott Fitzgerald
(7, 6, 1), -- The Alchemist by Paulo Coelho
(8, 7, 1), -- 1984 by George Orwell
(9, 8, 1), -- The Chronicles of Narnia by C.S. Lewis
(10, 9, 1); -- The Lord of the Rings by J.R.R. Tolkien

-- Link books to categories
INSERT INTO book_categories (book_id, category_id) VALUES
(1, 5), (2, 5), (3, 5), -- Technology books
(4, 6), (5, 6), (6, 6), -- Literature books
(7, 1), (8, 1), (10, 1), -- Fiction books
(9, 7); -- Children book

-- Create indexes for better performance
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_authors_name ON authors(last_name, first_name);
CREATE INDEX idx_book_authors_book_id ON book_authors(book_id);
CREATE INDEX idx_book_authors_author_id ON book_authors(author_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_book_id ON transactions(book_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- Create a view for active borrowings
CREATE VIEW active_borrowings AS
SELECT 
    t.transaction_id,
    u.username,
    u.first_name,
    u.last_name,
    b.title,
    GROUP_CONCAT(
        CONCAT(a.first_name, ' ', a.last_name) 
        ORDER BY ba.author_order 
        SEPARATOR ', '
    ) as authors,
    t.transaction_date,
    t.due_date,
    DATEDIFF(CURDATE(), t.due_date) as days_overdue
FROM transactions t
JOIN users u ON t.user_id = u.user_id
JOIN books b ON t.book_id = b.book_id
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
WHERE t.status = 'active' AND t.transaction_type = 'borrow'
GROUP BY t.transaction_id, u.username, u.first_name, u.last_name, b.title, t.transaction_date, t.due_date;

-- Create a view for book availability
CREATE VIEW book_availability AS
SELECT 
    b.book_id,
    b.title,
    b.total_copies,
    b.available_copies,
    (b.total_copies - b.available_copies) as borrowed_copies,
    CASE 
        WHEN b.available_copies > 0 THEN 'Available'
        ELSE 'Not Available'
    END as availability_status
FROM books b;

-- =============================================
-- NOTIFICATION TABLE (MUST BE CREATED BEFORE TRIGGERS)
-- =============================================

-- Create notification table for empty books
CREATE TABLE IF NOT EXISTS book_notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    notification_type ENUM('empty', 'low_stock', 'restocked') DEFAULT 'empty',
    notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

-- Create index for better performance on notifications
CREATE INDEX idx_notifications_type ON book_notifications(notification_type);
CREATE INDEX idx_notifications_date ON book_notifications(notification_date);
CREATE INDEX idx_notifications_read ON book_notifications(is_read);

-- =============================================
-- DATABASE TRIGGER FOR BOOK NOTIFICATIONS
-- =============================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS tr_book_empty_notification;
DROP TRIGGER IF EXISTS tr_book_restocked_notification;
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Trigger: Notify when books become unavailable (available_copies = 0)
DELIMITER $$
CREATE TRIGGER tr_book_empty_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    -- Check if book became empty (available_copies = 0)
    IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
        -- Insert notification into book_notifications table
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'empty', NOW(), 
                CONCAT('Book "', NEW.title, '" is now out of stock'));
    END IF;
END$$

-- Trigger: Notify when books are running low (available_copies < 2)
CREATE TRIGGER tr_book_low_stock_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    -- Check if book is running low (available_copies < 2 and was previously >= 2)
    IF NEW.available_copies < 2 AND OLD.available_copies >= 2 AND NEW.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
    END IF;
END$$
DELIMITER ;


-- =============================================
-- VIEWS FOR NOTIFICATION MANAGEMENT
-- =============================================

-- View for unread notifications
CREATE VIEW unread_notifications AS
SELECT 
    n.notification_id,
    n.book_id,
    n.title,
    n.notification_type,
    n.notification_date,
    n.message,
    b.location,
    b.total_copies,
    b.available_copies
FROM book_notifications n
JOIN books b ON n.book_id = b.book_id
WHERE n.is_read = FALSE
ORDER BY n.notification_date DESC;

-- View for empty books summary
CREATE VIEW empty_books_summary AS
SELECT 
    b.book_id,
    b.title,
    b.total_copies,
    b.available_copies,
    b.location,
    n.notification_date as empty_since,
    DATEDIFF(CURDATE(), n.notification_date) as days_empty
FROM books b
JOIN book_notifications n ON b.book_id = n.book_id
WHERE b.available_copies = 0 
AND n.notification_type = 'empty'
ORDER BY n.notification_date DESC;

-- =============================================
-- UTILITY PROCEDURES FOR NOTIFICATION MANAGEMENT
-- =============================================

-- Procedure to mark notifications as read
DELIMITER $$
CREATE PROCEDURE sp_mark_notifications_read(IN notification_ids TEXT)
BEGIN
    -- Mark specific notifications as read
    SET @sql = CONCAT('UPDATE book_notifications SET is_read = TRUE WHERE notification_id IN (', notification_ids, ')');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- Procedure to clean up old notifications (older than 30 days)
CREATE PROCEDURE sp_cleanup_old_notifications()
BEGIN
    DELETE FROM book_notifications 
    WHERE notification_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND is_read = TRUE;
END$$

-- Procedure to get notification statistics
CREATE PROCEDURE sp_get_notification_stats()
BEGIN
    SELECT 
        notification_type,
        COUNT(*) as count,
        COUNT(CASE WHEN is_read = FALSE THEN 1 END) as unread_count
    FROM book_notifications 
    WHERE notification_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY notification_type;
END$$

DELIMITER ;
