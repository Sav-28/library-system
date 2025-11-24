-- Fix the borrow issue by checking and fixing triggers/MySQL mode
USE library;

-- Step 1: Check current triggers
SHOW TRIGGERS WHERE `Table` = 'books';

-- Step 2: Check MySQL strict mode
SHOW VARIABLES LIKE 'sql_mode';

-- Step 3: Temporarily disable triggers to test (uncomment to test)
-- DROP TRIGGER IF EXISTS tr_book_empty_notification;
-- DROP TRIGGER IF EXISTS tr_book_restocked_notification;
-- DROP TRIGGER IF EXISTS tr_book_low_stock_notification;

-- Step 4: If triggers are the issue, recreate them with better error handling
-- (Run the trigger creation from fix_triggers_complete.sql)

-- Step 5: Alternative - Temporarily disable strict mode for testing
-- SET SESSION sql_mode = '';

-- Step 6: Test the UPDATE directly
-- UPDATE books SET available_copies = available_copies - 1 WHERE book_id = 1;

