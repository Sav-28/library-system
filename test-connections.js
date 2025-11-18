const mysql = require('mysql2');
require('dotenv').config();

console.log('Starting connection test...');

const connection = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'savio2804',
    database: process.env.DB_NAME || 'library',
    port: process.env.DB_PORT || 3306
});

connection.connect((err) => {
    if (err) {
        console.log('Connection failed:', err);
    } else {
        console.log('Connection successful!');
        
        connection.query('SELECT 1 as test', (err, results) => {
            if (err) {
                console.log('Query failed:', err);
            } else {
                console.log('Query successful:', results);
            }
            connection.end();
        });
    }
});