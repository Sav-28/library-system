-- Test script to diagnose trigger issues
USE library;

-- 1. Check if triggers exist
SELECT 
    TRIGGER_NAME, 
    EVENT_MANIPULATION, 
    EVENT_OBJECT_TABLE, 
    ACTION_TIMING,
    ACTION_STATEMENT
FROM information_schema.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'library' 
AND TRIGGER_NAME LIKE 'tr_book%';

-- 2. Check if book_notifications table exists
SHOW TABLES LIKE 'book_notifications';

-- 3. Check table structure
DESCRIBE book_notifications;

-- 4. Check current books data
SELECT book_id, title, total_copies, available_copies 
FROM books 
LIMIT 5;

-- 5. Check existing notifications
SELECT * FROM book_notifications ORDER BY notification_date DESC LIMIT 10;

-- 6. Test the trigger manually
-- First, get a book with available_copies > 0
SELECT book_id, title, available_copies FROM books WHERE available_copies > 0 LIMIT 1;

-- Then update it to 0 (replace BOOK_ID with actual ID from above query)
-- UPDATE books SET available_copies = 0 WHERE book_id = 1;

-- Check if notification was created
-- SELECT * FROM book_notifications WHERE notification_type = 'empty' ORDER BY notification_date DESC LIMIT 5;

