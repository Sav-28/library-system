-- Run these commands ONE BY ONE in MySQL command line
-- Copy and paste each section separately

USE library;

-- Step 1: Ensure table exists
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

-- Step 2: Drop any existing triggers (if they exist)
DROP TRIGGER IF EXISTS tr_book_empty_notification;
DROP TRIGGER IF EXISTS tr_book_restocked_notification;
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Step 3: Create Trigger 1 - Empty notification
-- Copy everything from DELIMITER $$ to DELIMITER ; as ONE block
DELIMITER $$
CREATE TRIGGER tr_book_empty_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'empty', NOW(), 
                CONCAT('Book "', NEW.title, '" is now out of stock'));
    END IF;
END$$
DELIMITER ;

-- Step 4: Create Trigger 2 - Restocked notification
DELIMITER $$
CREATE TRIGGER tr_book_restocked_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    IF NEW.available_copies > 0 AND OLD.available_copies = 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'restocked', NOW(), 
                CONCAT('Book "', NEW.title, '" has been restocked (', NEW.available_copies, ' copies available)'));
    END IF;
END$$
DELIMITER ;

-- Step 5: Create Trigger 3 - Low stock notification
DELIMITER $$
CREATE TRIGGER tr_book_low_stock_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    IF NEW.available_copies <= 2 AND OLD.available_copies > 2 AND NEW.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
    END IF;
END$$
DELIMITER ;

-- Step 6: Verify triggers were created
SHOW TRIGGERS LIKE 'tr_book%';

