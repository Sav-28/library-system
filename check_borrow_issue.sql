-- Check what's causing the borrow issue
USE library;

-- 1. Check table structure
DESCRIBE books;

-- 2. Check all triggers on books table
SHOW TRIGGERS WHERE `Table` = 'books';

-- 3. Check MySQL mode
SHOW VARIABLES LIKE 'sql_mode';

-- 4. Test the UPDATE query directly (replace 1 with actual book_id)
-- SELECT book_id, available_copies FROM books WHERE book_id = 1;
-- UPDATE books SET available_copies = available_copies - 1 WHERE book_id = 1;

-- 5. Check if there are any views that might interfere
SHOW FULL TABLES WHERE Table_type = 'VIEW';

