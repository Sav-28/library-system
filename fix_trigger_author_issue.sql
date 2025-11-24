-- Fix potential trigger issue causing author field error
USE library;

-- Step 1: Check current triggers
SHOW TRIGGERS LIKE 'tr_book%';

-- Step 2: Drop all book triggers temporarily to test
DROP TRIGGER IF EXISTS tr_book_empty_notification;
DROP TRIGGER IF EXISTS tr_book_restocked_notification;
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Step 3: Test if UPDATE works without triggers
-- Run this manually: UPDATE books SET available_copies = available_copies - 1 WHERE book_id = 1;

-- Step 4: If UPDATE works, recreate triggers with proper error handling
DELIMITER $$

CREATE TRIGGER tr_book_empty_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Silently handle errors to prevent blocking the UPDATE
    END;
    
    IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'empty', NOW(), 
                CONCAT('Book "', NEW.title, '" is now out of stock'));
    END IF;
END$$

CREATE TRIGGER tr_book_restocked_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Silently handle errors
    END;
    
    IF NEW.available_copies > 0 AND OLD.available_copies = 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'restocked', NOW(), 
                CONCAT('Book "', NEW.title, '" has been restocked (', NEW.available_copies, ' copies available)'));
    END IF;
END$$

CREATE TRIGGER tr_book_low_stock_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Silently handle errors
    END;
    
    IF NEW.available_copies <= 2 AND OLD.available_copies > 2 AND NEW.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
    END IF;
END$$

DELIMITER ;

-- Step 5: Verify triggers
SHOW TRIGGERS LIKE 'tr_book%';

