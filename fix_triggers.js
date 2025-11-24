const mysql = require('mysql2');
const fs = require('fs');
require('dotenv').config();

// Database connection
const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    port: process.env.DB_PORT || 3306,
    database: process.env.DB_NAME || 'library',
    multipleStatements: true
});

async function fixTriggers() {
    try {
        console.log('Connecting to MySQL...');
        await db.promise().connect();
        console.log('Connected to MySQL');

        // Step 1: Create book_notifications table if it doesn't exist
        console.log('\n=== Step 1: Creating book_notifications table ===');
        await db.promise().execute(`
            CREATE TABLE IF NOT EXISTS book_notifications (
                notification_id INT PRIMARY KEY AUTO_INCREMENT,
                book_id INT NOT NULL,
                title VARCHAR(200) NOT NULL,
                notification_type ENUM('empty', 'low_stock', 'restocked') DEFAULT 'empty',
                notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                message TEXT,
                is_read BOOLEAN DEFAULT FALSE,
                FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        `);
        console.log('✓ book_notifications table created/verified');

        // Create indexes
        try {
            await db.promise().execute(`CREATE INDEX idx_notifications_type ON book_notifications(notification_type)`);
            await db.promise().execute(`CREATE INDEX idx_notifications_date ON book_notifications(notification_date)`);
            await db.promise().execute(`CREATE INDEX idx_notifications_read ON book_notifications(is_read)`);
            console.log('✓ Indexes created/verified');
        } catch (err) {
            if (err.code !== 'ER_DUP_KEYNAME') {
                console.log('⚠ Index creation warning (may already exist):', err.message);
            }
        }

        // Step 2: Drop existing triggers
        console.log('\n=== Step 2: Dropping existing triggers ===');
        try {
            await db.promise().execute(`DROP TRIGGER IF EXISTS tr_book_empty_notification`);
            await db.promise().execute(`DROP TRIGGER IF EXISTS tr_book_restocked_notification`);
            await db.promise().execute(`DROP TRIGGER IF EXISTS tr_book_low_stock_notification`);
            console.log('✓ Existing triggers dropped');
        } catch (err) {
            console.log('⚠ Trigger drop warning:', err.message);
        }

        // Step 3: Create triggers using raw query (bypasses DELIMITER issues)
        console.log('\n=== Step 3: Creating triggers ===');
        
        // Read the trigger SQL from the schema file
        const schema = fs.readFileSync('database_schema.sql', 'utf8');
        
        // Extract trigger creation part
        const triggerStart = schema.indexOf('-- Trigger: Notify when books become empty');
        const triggerEnd = schema.indexOf('DELIMITER ;', triggerStart) + 'DELIMITER ;'.length;
        const triggerSQL = schema.substring(triggerStart, triggerEnd);
        
        // Remove DELIMITER commands and execute
        const cleanTriggerSQL = triggerSQL
            .replace(/DELIMITER \$\$/g, '')
            .replace(/DELIMITER ;/g, '')
            .replace(/\$\$/g, ';');
        
        // Split into individual trigger statements
        const triggers = cleanTriggerSQL.split(/CREATE TRIGGER/).filter(t => t.trim().length > 0);
        
        for (let i = 0; i < triggers.length; i++) {
            const triggerSQL = 'CREATE TRIGGER' + triggers[i].trim();
            // Remove the last semicolon and add proper delimiter handling
            const finalSQL = triggerSQL.replace(/;(\s*)$/, '');
            
            try {
                // Execute each trigger creation
                await db.promise().query(finalSQL);
                const triggerName = finalSQL.match(/CREATE TRIGGER\s+(\w+)/i)?.[1];
                console.log(`✓ Trigger created: ${triggerName}`);
            } catch (err) {
                console.error(`✗ Error creating trigger:`, err.message);
                // Try alternative method - execute the full block
                console.log('Trying alternative method...');
            }
        }

        // Alternative: Create triggers one by one with proper syntax
        console.log('\n=== Creating triggers (alternative method) ===');
        
        const emptyTriggerSQL = `
            CREATE TRIGGER tr_book_empty_notification
            AFTER UPDATE ON books
            FOR EACH ROW
            BEGIN
                IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
                    INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
                    VALUES (NEW.book_id, NEW.title, 'empty', NOW(), 
                            CONCAT('Book "', NEW.title, '" is now out of stock'));
                END IF;
            END
        `;
        
        const restockedTriggerSQL = `
            CREATE TRIGGER tr_book_restocked_notification
            AFTER UPDATE ON books
            FOR EACH ROW
            BEGIN
                IF NEW.available_copies > 0 AND OLD.available_copies = 0 THEN
                    INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
                    VALUES (NEW.book_id, NEW.title, 'restocked', NOW(), 
                            CONCAT('Book "', NEW.title, '" has been restocked (', NEW.available_copies, ' copies available)'));
                END IF;
            END
        `;
        
        const lowStockTriggerSQL = `
            CREATE TRIGGER tr_book_low_stock_notification
            AFTER UPDATE ON books
            FOR EACH ROW
            BEGIN
                IF NEW.available_copies <= 2 AND OLD.available_copies > 2 AND NEW.available_copies > 0 THEN
                    INSERT INTO book_notifications (book_id, title, notification_type, notification_date, message)
                    VALUES (NEW.book_id, NEW.title, 'low_stock', NOW(), 
                            CONCAT('Book "', NEW.title, '" is running low (', NEW.available_copies, ' copies remaining)'));
                END IF;
            END
        `;

        // Use a different approach - execute via mysql command or use connection.query with proper delimiter handling
        // For now, let's use a workaround with stored procedures or direct SQL execution
        
        console.log('\n⚠ Note: Due to DELIMITER limitations in Node.js mysql2,');
        console.log('   please run fix_triggers_complete.sql directly in MySQL client');
        console.log('   OR use: mysql -u root -p library < fix_triggers_complete.sql');

        // Step 4: Verify triggers
        console.log('\n=== Step 4: Verifying triggers ===');
        const [triggers] = await db.promise().execute(`
            SELECT 
                TRIGGER_NAME, 
                EVENT_MANIPULATION, 
                EVENT_OBJECT_TABLE, 
                ACTION_TIMING
            FROM information_schema.TRIGGERS 
            WHERE TRIGGER_SCHEMA = ? 
            AND TRIGGER_NAME LIKE 'tr_book%'
        `, [process.env.DB_NAME || 'library']);
        
        if (triggers.length === 3) {
            console.log('✓ All 3 triggers exist:');
            triggers.forEach(t => {
                console.log(`  - ${t.TRIGGER_NAME} (${t.EVENT_MANIPULATION} ${t.ACTION_TIMING})`);
            });
        } else {
            console.log(`⚠ Only ${triggers.length} trigger(s) found. Expected 3.`);
            console.log('Please run fix_triggers_complete.sql manually in MySQL client.');
        }

        console.log('\n=== Fix process completed ===');
        console.log('\nTo test the trigger:');
        console.log('1. UPDATE books SET available_copies = 0 WHERE book_id = 1;');
        console.log('2. SELECT * FROM book_notifications WHERE notification_type = "empty";');
        
    } catch (error) {
        console.error('Error fixing triggers:', error);
        console.error('\nPlease run fix_triggers_complete.sql manually in MySQL client.');
    } finally {
        db.end();
    }
}

fixTriggers();

