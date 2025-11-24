-- Complete Fix for Database Triggers
-- This script will diagnose and fix all trigger issues

USE library;

-- Step 1: Check current state
SELECT '=== CHECKING CURRENT STATE ===' AS status;

-- Check if book_notifications table exists
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✓ book_notifications table exists'
        ELSE '✗ book_notifications table DOES NOT exist'
    END AS table_status
FROM information_schema.tables 
WHERE table_schema = 'library' 
AND table_name = 'book_notifications';

-- Check if triggers exist
SELECT 
    CASE 
        WHEN COUNT(*) = 3 THEN '✓ All 3 triggers exist'
        WHEN COUNT(*) > 0 THEN CONCAT('⚠ Only ', COUNT(*), ' trigger(s) exist')
        ELSE '✗ NO triggers exist'
    END AS trigger_status,
    GROUP_CONCAT(TRIGGER_NAME) AS existing_triggers
FROM information_schema.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'library' 
AND TRIGGER_NAME LIKE 'tr_book%';

-- Step 2: Create/Ensure book_notifications table exists
SELECT '=== CREATING/UPDATING book_notifications TABLE ===' AS status;

CREATE TABLE IF NOT EXISTS book_notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    notification_type ENUM('empty', 'low_stock', 'restocked') DEFAULT 'empty',
    notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_notifications_type ON book_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_date ON book_notifications(notification_date);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON book_notifications(is_read);

-- Step 3: Drop existing triggers (if any) to recreate them
SELECT '=== DROPPING EXISTING TRIGGERS ===' AS status;

DROP TRIGGER IF EXISTS tr_book_empty_notification;
DROP TRIGGER IF EXISTS tr_book_restocked_notification;
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Step 4: Recreate triggers with proper error handling
SELECT '=== CREATING TRIGGERS ===' AS status;

DELIMITER $$

-- Trigger 1: Notify when books become empty
CREATE TRIGGER tr_book_empty_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Log error but don't fail the update
        GET DIAGNOSTICS CONDITION 1
            @sqlstate = RETURNED_SQLSTATE,
            @errno = MYSQL_ERRNO,
            @text = MESSAGE_TEXT;
        -- You can log this to an error table if needed
    END;
    
    -- Check if book became empty (available_copies = 0)
    IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'empty', NOW(), 
                CONCAT('Book "', NEW.title, '" is now out of stock'));
    END IF;
END$$

-- Trigger 2: Notify when books are restocked
CREATE TRIGGER tr_book_restocked_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @sqlstate = RETURNED_SQLSTATE,
            @errno = MYSQL_ERRNO,
            @text = MESSAGE_TEXT;
    END;
    
    -- Check if book was restocked (available_copies > 0 and was previously 0)
    IF NEW.available_copies > 0 AND OLD.available_copies = 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'restocked', NOW(), 
                CONCAT('Book "', NEW.title, '" has been restocked (', NEW.available_copies, ' copies available)'));
    END IF;
END$$

-- Trigger 3: Notify when books are running low
CREATE TRIGGER tr_book_low_stock_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @sqlstate = RETURNED_SQLSTATE,
            @errno = MYSQL_ERRNO,
            @text = MESSAGE_TEXT;
    END;
    
    -- Check if book is running low (available_copies <= 2 and was previously > 2)
    IF NEW.available_copies <= 2 AND OLD.available_copies > 2 AND NEW.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
    END IF;
END$$

DELIMITER ;

-- Step 5: Verify triggers were created
SELECT '=== VERIFYING TRIGGERS ===' AS status;

SELECT 
    TRIGGER_NAME, 
    EVENT_MANIPULATION, 
    EVENT_OBJECT_TABLE, 
    ACTION_TIMING,
    CREATED
FROM information_schema.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'library' 
AND TRIGGER_NAME LIKE 'tr_book%'
ORDER BY TRIGGER_NAME;

-- Step 6: Test the trigger (optional - uncomment to test)
SELECT '=== TEST INSTRUCTIONS ===' AS status;
SELECT 'To test the trigger, run:' AS instruction;
SELECT '1. Find a book: SELECT book_id, title, available_copies FROM books WHERE available_copies > 0 LIMIT 1;' AS step1;
SELECT '2. Update it: UPDATE books SET available_copies = 0 WHERE book_id = <ID_FROM_STEP1>;' AS step2;
SELECT '3. Check notification: SELECT * FROM book_notifications WHERE notification_type = ''empty'' ORDER BY notification_date DESC LIMIT 1;' AS step3;

