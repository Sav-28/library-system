const mysql = require('mysql2');
const fs = require('fs');
require('dotenv').config();

// Database connection
const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    port: process.env.DB_PORT || 3306,
    multipleStatements: true
});

async function setupDatabase() {
    try {
        console.log('Connecting to MySQL...');
        await db.promise().connect();
        console.log('Connected to MySQL');

        // Create database if it doesn't exist
        const dbName = process.env.DB_NAME || 'library';
        console.log(`Creating database '${dbName}' if it doesn't exist...`);
        await db.promise().query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\``);
        await db.promise().query(`USE \`${dbName}\``);
        console.log(`Using database '${dbName}'`);

        // Read the schema file
        const schema = fs.readFileSync('database_schema.sql', 'utf8');
        
        console.log('Executing database schema...');
        await db.promise().execute(schema);
        console.log('Database schema executed successfully!');
        
        console.log('Database setup completed successfully!');
        console.log('You can now start the server with: npm start');
        
    } catch (error) {
        console.error('Database setup failed:', error);
        process.exit(1);
    } finally {
        db.end();
    }
}

setupDatabase();
