const mysql = require('mysql2');
require('dotenv').config();

// Database connection
const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    port: process.env.DB_PORT || 3306
});

async function createTables() {
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

        // Create tables one by one
        console.log('Creating users table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS users (
                user_id INT PRIMARY KEY AUTO_INCREMENT,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                first_name VARCHAR(50) NOT NULL,
                last_name VARCHAR(50) NOT NULL,
                phone VARCHAR(20),
                address TEXT,
                user_type ENUM('user', 'admin') DEFAULT 'user',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        `);

        console.log('Creating authors table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS authors (
                author_id INT PRIMARY KEY AUTO_INCREMENT,
                first_name VARCHAR(50) NOT NULL,
                last_name VARCHAR(50) NOT NULL,
                biography TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        `);

        console.log('Creating books table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS books (
                book_id INT PRIMARY KEY AUTO_INCREMENT,
                isbn VARCHAR(20) UNIQUE,
                title VARCHAR(200) NOT NULL,
                publisher VARCHAR(100),
                publication_year YEAR,
                genre VARCHAR(50),
                description TEXT,
                total_copies INT DEFAULT 1,
                available_copies INT DEFAULT 1,
                location VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        `);

        console.log('Creating book_authors table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS book_authors (
                book_id INT,
                author_id INT,
                author_order INT DEFAULT 1,
                PRIMARY KEY (book_id, author_id),
                FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
                FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
            )
        `);

        console.log('Creating transactions table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS transactions (
                transaction_id INT PRIMARY KEY AUTO_INCREMENT,
                user_id INT NOT NULL,
                book_id INT NOT NULL,
                transaction_type ENUM('borrow', 'return') NOT NULL,
                transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                due_date DATE,
                return_date DATE NULL,
                status ENUM('active', 'returned', 'overdue') DEFAULT 'active',
                fine_amount DECIMAL(10,2) DEFAULT 0.00,
                notes TEXT,
                FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
            )
        `);

        console.log('Creating categories table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS categories (
                category_id INT PRIMARY KEY AUTO_INCREMENT,
                category_name VARCHAR(50) UNIQUE NOT NULL,
                description TEXT
            )
        `);

        console.log('Creating book_categories table...');
        await db.promise().query(`
            CREATE TABLE IF NOT EXISTS book_categories (
                book_id INT,
                category_id INT,
                PRIMARY KEY (book_id, category_id),
                FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
                FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
            )
        `);

        console.log('Inserting sample data...');
        
        // Insert sample categories
        await db.promise().query(`
            INSERT IGNORE INTO categories (category_name, description) VALUES
            ('Fiction', 'Novels and fictional works'),
            ('Non-Fiction', 'Educational and informational books'),
            ('Science', 'Scientific literature and research'),
            ('History', 'Historical books and biographies'),
            ('Technology', 'Computer science and technology books'),
            ('Literature', 'Classic and contemporary literature'),
            ('Children', 'Books for children and young adults'),
            ('Reference', 'Dictionaries, encyclopedias, and reference materials')
        `);

        // Insert sample admin user
        await db.promise().query(`
            INSERT IGNORE INTO users (username, email, password_hash, first_name, last_name, user_type) VALUES
            ('admin', 'admin@library.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Library', 'Administrator', 'admin')
        `);

        // Insert sample regular users
        await db.promise().query(`
            INSERT IGNORE INTO users (username, email, password_hash, first_name, last_name, phone, address) VALUES
            ('john_doe', 'john@email.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John', 'Doe', '555-0123', '123 Main St, City'),
            ('jane_smith', 'jane@email.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Jane', 'Smith', '555-0456', '456 Oak Ave, City'),
            ('bob_wilson', 'bob@email.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Bob', 'Wilson', '555-0789', '789 Pine St, City')
        `);

        // Insert sample authors
        await db.promise().query(`
            INSERT IGNORE INTO authors (first_name, last_name, biography) VALUES
            ('Robert', 'Martin', 'Software engineer and author, known for Clean Code and Clean Architecture'),
            ('David', 'Thomas', 'Software engineer and co-author of The Pragmatic Programmer'),
            ('Harper', 'Lee', 'American novelist best known for To Kill a Mockingbird'),
            ('Jane', 'Austen', 'English novelist known for her social commentary and romantic fiction'),
            ('F. Scott', 'Fitzgerald', 'American novelist and short story writer'),
            ('Paulo', 'Coelho', 'Brazilian lyricist and novelist'),
            ('George', 'Orwell', 'English novelist, essayist, and critic'),
            ('C.S.', 'Lewis', 'British writer and lay theologian'),
            ('J.R.R.', 'Tolkien', 'English writer, poet, and philologist')
        `);

        // Insert sample books
        await db.promise().query(`
            INSERT IGNORE INTO books (isbn, title, publisher, publication_year, genre, description, total_copies, available_copies, location) VALUES
            ('978-0134685991', 'Clean Code', 'Prentice Hall', 2008, 'Technology', 'A handbook of agile software craftsmanship', 3, 3, 'Tech Section A1'),
            ('978-0132350884', 'Clean Architecture', 'Prentice Hall', 2017, 'Technology', 'A craftsman guide to software structure and design', 2, 2, 'Tech Section A2'),
            ('978-0201616224', 'The Pragmatic Programmer', 'Addison-Wesley', 1999, 'Technology', 'Your journey to mastery', 2, 2, 'Tech Section B1'),
            ('978-0061120084', 'To Kill a Mockingbird', 'J.B. Lippincott & Co.', 1960, 'Literature', 'A gripping tale of racial injustice and childhood innocence', 4, 4, 'Literature Section C1'),
            ('978-0141439518', 'Pride and Prejudice', 'T. Egerton', 1813, 'Literature', 'A romantic novel of manners', 3, 3, 'Literature Section C2'),
            ('978-0307277671', 'The Great Gatsby', 'Charles Scribner Sons', 1925, 'Literature', 'A tale of the fabulously wealthy Jay Gatsby', 2, 2, 'Literature Section C3'),
            ('978-0062315007', 'The Alchemist', 'HarperOne', 1988, 'Fiction', 'A philosophical book about a young shepherd', 3, 3, 'Fiction Section D1'),
            ('978-0143127741', '1984', 'Secker & Warburg', 1949, 'Fiction', 'A dystopian social science fiction novel', 2, 2, 'Fiction Section D2'),
            ('978-0061122415', 'The Chronicles of Narnia', 'Geoffrey Bles', 1950, 'Children', 'A series of fantasy novels', 5, 5, 'Children Section E1'),
            ('978-0544003415', 'The Lord of the Rings', 'Allen & Unwin', 1954, 'Fiction', 'An epic high-fantasy novel', 3, 3, 'Fiction Section D3')
        `);

        // Link books to authors
        await db.promise().query(`
            INSERT IGNORE INTO book_authors (book_id, author_id, author_order) VALUES
            (1, 1, 1), (2, 1, 1), (3, 2, 1), (4, 3, 1), (5, 4, 1),
            (6, 5, 1), (7, 6, 1), (8, 7, 1), (9, 8, 1), (10, 9, 1)
        `);

        // Link books to categories
        await db.promise().query(`
            INSERT IGNORE INTO book_categories (book_id, category_id) VALUES
            (1, 5), (2, 5), (3, 5), (4, 6), (5, 6), (6, 6), (7, 1), (8, 1), (10, 1), (9, 7)
        `);

        console.log('Database setup completed successfully!');
        console.log('You can now start the server with: npm start');
        
    } catch (error) {
        console.error('Database setup failed:', error);
        process.exit(1);
    } finally {
        db.end();
    }
}

createTables();
