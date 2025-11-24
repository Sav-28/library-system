-- Diagnose the author field error
USE library;

-- Step 1: Check actual table structure
DESCRIBE books;

-- Step 2: List all columns in books table
SHOW COLUMNS FROM books;

-- Step 3: Check if there are any triggers that might reference 'author'
SHOW TRIGGERS FROM library;

-- Step 4: Check trigger definitions
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_STATEMENT
FROM information_schema.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'library'
AND EVENT_OBJECT_TABLE = 'books';

-- Step 5: Check for any views that might have author
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- Step 6: Check MySQL strict mode settings
SHOW VARIABLES LIKE 'sql_mode';

