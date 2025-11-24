-- Create trigger for when available copies are less than 2
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

-- Step 2: Drop existing low stock trigger if it exists
DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Step 3: Create trigger for low stock (available_copies < 2)
DELIMITER $$
CREATE TRIGGER tr_book_low_stock_notification
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    -- Check if book is running low (available_copies < 2 and was previously >= 2)
    -- Also ensure it's not already empty (available_copies > 0)
    IF NEW.available_copies < 2 AND OLD.available_copies >= 2 AND NEW.available_copies > 0 THEN
        INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
        VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
    END IF;
END$$
DELIMITER ;

-- Step 4: Verify trigger was created
SHOW TRIGGERS WHERE `Table` = 'books';

-- Step 5: Test the trigger
-- Find a book with available_copies >= 2
-- SELECT book_id, title, available_copies FROM books WHERE available_copies >= 2 LIMIT 1;
-- Update it to 1 (replace <BOOK_ID> with actual ID)
-- UPDATE books SET available_copies = 1 WHERE book_id = <BOOK_ID>;
-- Check notification
-- SELECT * FROM book_notifications WHERE notification_type = 'low_stock' ORDER BY notification_date DESC LIMIT 5;

