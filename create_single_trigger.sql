-- Create single trigger for when books become unavailable
USE library;

-- Step 1: Ensure book_notifications table exists
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

-- Step 2: Drop all existing triggers to start fresh
DROP TRIGGER IF EXISTS tr_book_empty_notification;
DROP TRIGGER IF EXISTS tr_book_restocked_notification;
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Step 3: Create single trigger for when books become unavailable
DELIMITER $$
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
DELIMITER ;

-- Step 4: Verify trigger was created
SHOW TRIGGERS WHERE `Table` = 'books';

