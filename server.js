const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database connection
const db = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'library',
    port: process.env.DB_PORT || 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test database connection
db.promise().execute('SELECT 1')
    .then(() => {
        console.log('Connected to MySQL database');
    })
    .catch((err) => {
        console.error('Database connection failed:', err);
    });

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Authentication middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
};

// Admin middleware
const requireAdmin = (req, res, next) => {
    if (req.user.user_type !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
    }
    next();
};

// Routes

// Authentication routes
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        const [users] = await db.promise().execute(
            'SELECT * FROM users WHERE username = ? OR email = ?',
            [username, username]
        );

        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = users[0];
        const validPassword = await bcrypt.compare(password, user.password_hash);

        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { 
                user_id: user.user_id, 
                username: user.username, 
                user_type: user.user_type 
            },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: {
                user_id: user.user_id,
                username: user.username,
                first_name: user.first_name,
                last_name: user.last_name,
                user_type: user.user_type
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/auth/register', async (req, res) => {
    try {
        const { username, email, password, first_name, last_name, phone, address } = req.body;
        
        // Check if user already exists
        const [existingUsers] = await db.promise().execute(
            'SELECT * FROM users WHERE username = ? OR email = ?',
            [username, email]
        );

        if (existingUsers.length > 0) {
            return res.status(400).json({ error: 'Username or email already exists' });
        }

        // Hash password
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);

        // Insert new user
        const [result] = await db.promise().execute(
            'INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [username, email, password_hash, first_name, last_name, phone, address]
        );

        res.status(201).json({ message: 'User registered successfully', user_id: result.insertId });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Book routes
app.get('/api/books', async (req, res) => {
    try {
        const { search, author, genre, available } = req.query;
        let query = `
            SELECT b.*, 
                   GROUP_CONCAT(DISTINCT c.category_name) as categories,
                   GROUP_CONCAT(
                       CONCAT(a.first_name, ' ', a.last_name) 
                       ORDER BY ba.author_order 
                       SEPARATOR ', '
                   ) as authors,
                   CASE WHEN b.available_copies > 0 THEN 'Available' ELSE 'Not Available' END as availability_status
            FROM books b
            LEFT JOIN book_categories bc ON b.book_id = bc.book_id
            LEFT JOIN categories c ON bc.category_id = c.category_id
            LEFT JOIN book_authors ba ON b.book_id = ba.book_id
            LEFT JOIN authors a ON ba.author_id = a.author_id
            WHERE 1=1
        `;
        const params = [];

        if (search) {
            query += ' AND (b.title LIKE ? OR b.isbn LIKE ? OR CONCAT(a.first_name, " ", a.last_name) LIKE ?)';
            const searchTerm = `%${search}%`;
            params.push(searchTerm, searchTerm, searchTerm);
        }

        if (author) {
            query += ' AND CONCAT(a.first_name, " ", a.last_name) LIKE ?';
            params.push(`%${author}%`);
        }

        if (genre) {
            query += ' AND b.genre LIKE ?';
            params.push(`%${genre}%`);
        }

        if (available === 'true') {
            query += ' AND b.available_copies > 0';
        }

        query += ' GROUP BY b.book_id ORDER BY b.title';

        const [books] = await db.promise().execute(query, params);
        res.json(books);
    } catch (error) {
        console.error('Get books error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/books/:id', async (req, res) => {
    try {
        const [books] = await db.promise().execute(`
            SELECT b.*, 
                   GROUP_CONCAT(DISTINCT c.category_name) as categories,
                   GROUP_CONCAT(
                       CONCAT(a.first_name, ' ', a.last_name) 
                       ORDER BY ba.author_order 
                       SEPARATOR ', '
                   ) as authors
            FROM books b
            LEFT JOIN book_categories bc ON b.book_id = bc.book_id
            LEFT JOIN categories c ON bc.category_id = c.category_id
            LEFT JOIN book_authors ba ON b.book_id = ba.book_id
            LEFT JOIN authors a ON ba.author_id = a.author_id
            WHERE b.book_id = ?
            GROUP BY b.book_id
        `, [req.params.id]);

        if (books.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        // Get detailed author information for the book
        const [authors] = await db.promise().execute(`
            SELECT a.author_id, a.first_name, a.last_name, ba.author_order
            FROM book_authors ba
            JOIN authors a ON ba.author_id = a.author_id
            WHERE ba.book_id = ?
            ORDER BY ba.author_order
        `, [req.params.id]);

        const book = books[0];
        book.authors = authors;

        res.json(book);
    } catch (error) {
        console.error('Get book error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Transaction routes
app.post('/api/transactions/borrow', authenticateToken, async (req, res) => {
    try {
        const { book_id } = req.body;
        const user_id = req.user.user_id;

        // Check if book is available
        const [books] = await db.promise().execute(
            'SELECT * FROM books WHERE book_id = ?',
            [book_id]
        );

        if (books.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        if (books[0].available_copies <= 0) {
            return res.status(400).json({ error: 'Book is not available' });
        }

        // Check if user already has this book borrowed
        const [existingBorrows] = await db.promise().execute(
            'SELECT * FROM transactions WHERE user_id = ? AND book_id = ? AND status = "active" AND transaction_type = "borrow"',
            [user_id, book_id]
        );

        if (existingBorrows.length > 0) {
            return res.status(400).json({ error: 'You already have this book borrowed' });
        }

        // Calculate due date (14 days from now)
        const due_date = new Date();
        due_date.setDate(due_date.getDate() + 14);

        // Create transaction
        await db.promise().execute(
            'INSERT INTO transactions (user_id, book_id, transaction_type, due_date) VALUES (?, ?, "borrow", ?)',
            [user_id, book_id, due_date]
        );

        // Update available copies - use explicit value calculation to avoid trigger issues
        const newAvailableCopies = Math.max(0, books[0].available_copies - 1);
        
        // Try to update with error handling for trigger/strict mode issues
        try {
            await db.promise().execute(
                'UPDATE books SET available_copies = ? WHERE book_id = ?',
                [newAvailableCopies, book_id]
            );
        } catch (updateError) {
            // If error is about 'author' field, try disabling strict mode temporarily
            if (updateError.message && updateError.message.includes('author')) {
                console.warn('Author field error detected, attempting workaround...');
                // Try with explicit column list to avoid trigger issues
                await db.promise().execute(
                    'UPDATE books SET available_copies = ?, updated_at = NOW() WHERE book_id = ?',
                    [newAvailableCopies, book_id]
                );
            } else {
                throw updateError; // Re-throw if it's a different error
            }
        }

        res.json({ message: 'Book borrowed successfully' });
    } catch (error) {
        console.error('Borrow book error:', error);
        console.error('Error details:', {
            message: error.message,
            code: error.code,
            errno: error.errno,
            sqlState: error.sqlState,
            sqlMessage: error.sqlMessage
        });
        
        // Return user-friendly error message
        let errorMessage = 'Failed to borrow book';
        if (error.message && error.message.includes('author')) {
            errorMessage = 'Database configuration error. Please contact administrator.';
        } else if (error.message) {
            errorMessage = error.message;
        }
        
        res.status(500).json({ error: errorMessage });
    }
});

app.post('/api/transactions/return', authenticateToken, async (req, res) => {
    try {
        const { transaction_id } = req.body;
        const user_id = req.user.user_id;

        // Get transaction details
        const [transactions] = await db.promise().execute(
            'SELECT * FROM transactions WHERE transaction_id = ? AND user_id = ? AND status = "active"',
            [transaction_id, user_id]
        );

        if (transactions.length === 0) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        const transaction = transactions[0];

        // Update transaction
        await db.promise().execute(
            'UPDATE transactions SET status = "returned", return_date = NOW() WHERE transaction_id = ?',
            [transaction_id]
        );

        // Update available copies
        await db.promise().execute(
            'UPDATE books SET available_copies = available_copies + 1 WHERE book_id = ?',
            [transaction.book_id]
        );

        res.json({ message: 'Book returned successfully' });
    } catch (error) {
        console.error('Return book error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/transactions/my-books', authenticateToken, async (req, res) => {
    try {
        const user_id = req.user.user_id;
        
        const [transactions] = await db.promise().execute(`
            SELECT t.*, b.title, b.isbn,
                   GROUP_CONCAT(
                       CONCAT(a.first_name, ' ', a.last_name) 
                       ORDER BY ba.author_order 
                       SEPARATOR ', '
                   ) as author,
                   CASE 
                       WHEN t.due_date < CURDATE() AND t.status = 'active' THEN 'overdue'
                       ELSE t.status
                   END as current_status,
                   DATEDIFF(CURDATE(), t.due_date) as days_overdue
            FROM transactions t
            JOIN books b ON t.book_id = b.book_id
            LEFT JOIN book_authors ba ON b.book_id = ba.book_id
            LEFT JOIN authors a ON ba.author_id = a.author_id
            WHERE t.user_id = ? AND t.transaction_type = 'borrow'
            GROUP BY t.transaction_id, b.title, b.isbn, t.transaction_date, t.due_date, t.status
            ORDER BY t.transaction_date DESC
        `, [user_id]);

        res.json(transactions);
    } catch (error) {
        console.error('Get my books error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Author routes
app.get('/api/authors', async (req, res) => {
    try {
        const [authors] = await db.promise().execute(
            'SELECT * FROM authors ORDER BY last_name, first_name'
        );
        res.json(authors);
    } catch (error) {
        console.error('Get authors error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/admin/authors', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { first_name, last_name, biography } = req.body;
        
        const [result] = await db.promise().execute(
            'INSERT INTO authors (first_name, last_name, biography) VALUES (?, ?, ?)',
            [first_name, last_name, biography]
        );
        
        res.status(201).json({ message: 'Author added successfully', author_id: result.insertId });
    } catch (error) {
        console.error('Add author error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Admin routes
app.get('/api/admin/users', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const [users] = await db.promise().execute(
            'SELECT user_id, username, email, first_name, last_name, phone, address, user_type, created_at FROM users ORDER BY created_at DESC'
        );
        res.json(users);
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/admin/books', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { isbn, title, authors, publisher, publication_year, genre, description, total_copies, location } = req.body;
        
        // Insert book (without author column)
        const [result] = await db.promise().execute(
            'INSERT INTO books (isbn, title, publisher, publication_year, genre, description, total_copies, available_copies, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [isbn, title, publisher, publication_year, genre, description, total_copies, total_copies, location]
        );
        
        const bookId = result.insertId;
        
        // Insert book-author relationships
        if (authors && authors.length > 0) {
            for (const author of authors) {
                // Check if author already exists
                const [existingAuthors] = await db.promise().execute(
                    'SELECT author_id FROM authors WHERE first_name = ? AND last_name = ?',
                    [author.first_name, author.last_name]
                );
                
                let authorId;
                if (existingAuthors.length > 0) {
                    // Use existing author
                    authorId = existingAuthors[0].author_id;
                } else {
                    // Insert new author
                    const [authorResult] = await db.promise().execute(
                        'INSERT INTO authors (first_name, last_name) VALUES (?, ?)',
                        [author.first_name, author.last_name]
                    );
                    authorId = authorResult.insertId;
                }
                
                await db.promise().execute(
                    'INSERT INTO book_authors (book_id, author_id, author_order) VALUES (?, ?, ?)',
                    [bookId, authorId, author.author_order]
                );
            }
        }
        
        res.status(201).json({ message: 'Book added successfully', book_id: bookId });
    } catch (error) {
        console.error('Add book error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/books/:id', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { isbn, title, authors, publisher, publication_year, genre, description, total_copies, location } = req.body;
        const book_id = req.params.id;

        // Get current book info to preserve total_copies and available_copies
        const [currentBooks] = await db.promise().execute(
            'SELECT total_copies, available_copies FROM books WHERE book_id = ?',
            [book_id]
        );

        if (currentBooks.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        const currentBook = currentBooks[0];
        // Preserve original total_copies and available_copies - do not allow editing them
        // This prevents indirect manipulation of available copies
        const preservedTotalCopies = currentBook.total_copies;
        const preservedAvailableCopies = currentBook.available_copies;

        // Update book (without author column) - preserve total_copies and available_copies
        await db.promise().execute(
            'UPDATE books SET isbn = ?, title = ?, publisher = ?, publication_year = ?, genre = ?, description = ?, total_copies = ?, available_copies = ?, location = ? WHERE book_id = ?',
            [isbn, title, publisher, publication_year, genre, description, preservedTotalCopies, preservedAvailableCopies, location, book_id]
        );

        // Remove existing author relationships
        await db.promise().execute(
            'DELETE FROM book_authors WHERE book_id = ?',
            [book_id]
        );

        // Insert new book-author relationships
        if (authors && authors.length > 0) {
            for (const author of authors) {
                // Check if author already exists
                const [existingAuthors] = await db.promise().execute(
                    'SELECT author_id FROM authors WHERE first_name = ? AND last_name = ?',
                    [author.first_name, author.last_name]
                );
                
                let authorId;
                if (existingAuthors.length > 0) {
                    // Use existing author
                    authorId = existingAuthors[0].author_id;
                } else {
                    // Insert new author
                    const [authorResult] = await db.promise().execute(
                        'INSERT INTO authors (first_name, last_name) VALUES (?, ?)',
                        [author.first_name, author.last_name]
                    );
                    authorId = authorResult.insertId;
                }
                
                await db.promise().execute(
                    'INSERT INTO book_authors (book_id, author_id, author_order) VALUES (?, ?, ?)',
                    [book_id, authorId, author.author_order]
                );
            }
        }

        res.json({ message: 'Book updated successfully' });
    } catch (error) {
        console.error('Update book error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.delete('/api/admin/books/:id', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const book_id = req.params.id;

        await db.promise().execute('DELETE FROM books WHERE book_id = ?', [book_id]);

        res.json({ message: 'Book deleted successfully' });
    } catch (error) {
        console.error('Delete book error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/transactions', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const [transactions] = await db.promise().execute(`
            SELECT t.*, u.username, u.first_name, u.last_name, b.title,
                   GROUP_CONCAT(
                       CONCAT(a.first_name, ' ', a.last_name) 
                       ORDER BY ba.author_order 
                       SEPARATOR ', '
                   ) as author,
                   CASE 
                       WHEN t.due_date < CURDATE() AND t.status = 'active' THEN 'overdue'
                       ELSE t.status
                   END as current_status,
                   DATEDIFF(CURDATE(), t.due_date) as days_overdue
            FROM transactions t
            JOIN users u ON t.user_id = u.user_id
            JOIN books b ON t.book_id = b.book_id
            LEFT JOIN book_authors ba ON b.book_id = ba.book_id
            LEFT JOIN authors a ON ba.author_id = a.author_id
            GROUP BY t.transaction_id, u.username, u.first_name, u.last_name, b.title, t.transaction_date, t.due_date, t.status
            ORDER BY t.transaction_date DESC
        `);

        res.json(transactions);
    } catch (error) {
        console.error('Get transactions error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/statistics', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const [totalBooks] = await db.promise().execute('SELECT COUNT(*) as count FROM books');
        const [totalUsers] = await db.promise().execute('SELECT COUNT(*) as count FROM users WHERE user_type = "user"');
        const [activeBorrows] = await db.promise().execute('SELECT COUNT(*) as count FROM transactions WHERE status = "active"');
        const [overdueBooks] = await db.promise().execute(`
            SELECT COUNT(*) as count FROM transactions 
            WHERE status = "active" AND due_date < CURDATE()
        `);

        res.json({
            totalBooks: totalBooks[0].count,
            totalUsers: totalUsers[0].count,
            activeBorrows: activeBorrows[0].count,
            overdueBooks: overdueBooks[0].count
        });
    } catch (error) {
        console.error('Get statistics error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Serve static files - only main interface
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/user', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Library Management System: http://localhost:${PORT}`);
    console.log(`Login as User or Admin from the main interface`);
});
