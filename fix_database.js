const mysql = require('mysql2');
require('dotenv').config();

// Database connection
const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'library',
    port: process.env.DB_PORT || 3306
});

async function fixDatabase() {
    try {
        console.log('Connecting to MySQL...');
        await db.promise().connect();
        console.log('Connected to MySQL');

        // Check if author column exists
        const [columns] = await db.promise().query(`
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = 'library' 
            AND TABLE_NAME = 'books' 
            AND COLUMN_NAME = 'author'
        `);

        if (columns.length > 0) {
            console.log('Removing author column from books table...');
            await db.promise().query('ALTER TABLE books DROP COLUMN author');
            console.log('Author column removed successfully!');
        } else {
            console.log('Author column does not exist in books table.');
        }

        console.log('Database fix completed successfully!');
        
    } catch (error) {
        console.error('Database fix failed:', error);
        process.exit(1);
    } finally {
        db.end();
    }
}

fixDatabase();
