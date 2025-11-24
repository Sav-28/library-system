-- Fix the 'author' column issue in books table
-- This script will check and fix the author column

USE library;

-- Step 1: Check current structure
DESCRIBE books;

-- Step 2: Check if author column exists and its properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT,
    COLUMN_TYPE
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'library' 
AND TABLE_NAME = 'books' 
AND COLUMN_NAME = 'author';

-- Step 3: Fix the author column
-- Option A: If author column exists but shouldn't, remove it
-- ALTER TABLE books DROP COLUMN author;

-- Option B: If author column should exist, make it nullable or add default
-- Make it nullable (recommended if you want to keep it)
ALTER TABLE books MODIFY COLUMN author VARCHAR(255) NULL;

-- OR add a default value
-- ALTER TABLE books MODIFY COLUMN author VARCHAR(255) DEFAULT NULL;

-- Step 4: Verify the fix
DESCRIBE books;

