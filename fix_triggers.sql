-- Fix Database Triggers
-- This script recreates the triggers in the correct order
-- Run this if your triggers are not working

USE library;

-- First, ensure the book_notifications table exists
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

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_notifications_type ON book_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_date ON book_notifications(notification_date);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON book_notifications(is_read);

-- Drop existing triggers if they exist (to recreate them)
DROP TRIGGER IF EXISTS tr_book_empty_notification;
DROP TRIGGER IF EXISTS tr_book_restocked_notification;
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Recreate triggers
DELIMITER $$

-- Trigger: Notify when books become empty
CREATE TRIGGER tr_book_empty_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    -- Check if book became empty (available_copies = 0)
    IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'empty', NOW(), 
                CONCAT('Book "', NEW.title, '" is now out of stock'));
    END IF;
END$$

-- Trigger: Notify when books are restocked
CREATE TRIGGER tr_book_restocked_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    -- Check if book was restocked (available_copies > 0 and was previously 0)
    IF NEW.available_copies > 0 AND OLD.available_copies = 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'restocked', NOW(), 
                CONCAT('Book "', NEW.title, '" has been restocked (', NEW.available_copies, ' copies available)'));
    END IF;
END$$

-- Trigger: Notify when books are running low (less than 2 copies)
CREATE TRIGGER tr_book_low_stock_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    -- Check if book is running low (available_copies <= 2 and was previously > 2)
    IF NEW.available_copies <= 2 AND OLD.available_copies > 2 AND NEW.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
    END IF;
END$$

DELIMITER ;

-- Verify triggers were created
SELECT 
    TRIGGER_NAME, 
    EVENT_MANIPULATION, 
    EVENT_OBJECT_TABLE, 
    ACTION_TIMING
FROM information_schema.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'library' 
AND TRIGGER_NAME LIKE 'tr_book%';

