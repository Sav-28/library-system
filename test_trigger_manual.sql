-- Manual Test Script for Trigger
-- Run this after fix_triggers_complete.sql

USE library;

-- Step 1: Find a book with available_copies > 0
SELECT '=== STEP 1: Finding a test book ===' AS step;
SELECT book_id, title, total_copies, available_copies 
FROM books 
WHERE available_copies > 0 
LIMIT 1;

-- Step 2: Note the book_id from above, then update it to 0
-- Replace <BOOK_ID> with the actual book_id from Step 1
-- UPDATE books SET available_copies = 0 WHERE book_id = <BOOK_ID>;

-- Step 3: Check if notification was created
SELECT '=== STEP 3: Checking for notification ===' AS step;
SELECT * FROM book_notifications 
WHERE notification_type = 'empty' 
ORDER BY notification_date DESC 
LIMIT 5;

-- Step 4: Check the updated book
SELECT '=== STEP 4: Verifying book update ===' AS step;
-- SELECT book_id, title, available_copies FROM books WHERE book_id = <BOOK_ID>;

-- Step 5: Test restock trigger (set available_copies back to > 0)
-- UPDATE books SET available_copies = 3 WHERE book_id = <BOOK_ID>;

-- Step 6: Check restock notification
SELECT '=== STEP 6: Checking restock notification ===' AS step;
SELECT * FROM book_notifications 
WHERE notification_type = 'restocked' 
ORDER BY notification_date DESC 
LIMIT 5;

