# Library Management System

A comprehensive library management system built with Node.js, Express, MySQL, and modern web technologies. This system provides separate interfaces for library users and administrators to manage books, borrowing, and library operations.

## Features

### User Interface
- **User Registration & Login**: Secure authentication system
- **Book Search & Browse**: Search books by title, author, ISBN, genre
- **Book Borrowing**: Borrow available books with due date tracking
- **My Books**: View borrowed books and return them
- **Responsive Design**: Works on desktop and mobile devices

### Admin Interface
- **Admin Authentication**: Secure admin login system
- **Dashboard**: Statistics overview (total books, users, active borrows, overdue books)
- **Book Management**: Add, edit, delete books with full details
- **User Management**: View all registered users
- **Transaction Management**: Monitor all borrowing transactions
- **Real-time Statistics**: Live updates of library metrics

### Database Features
- **Comprehensive Schema**: Users, books, transactions, categories, reservations, fines
- **Sample Data**: Pre-populated with sample books and users
- **Optimized Queries**: Indexed for performance
- **Data Integrity**: Foreign key constraints and data validation

## Technology Stack

- **Backend**: Node.js, Express.js
- **Database**: MySQL
- **Authentication**: JWT (JSON Web Tokens)
- **Password Security**: bcryptjs for password hashing
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Styling**: Modern CSS with gradients and animations
- **Icons**: Font Awesome

## Installation & Setup

### Prerequisites
- Node.js (v14 or higher)
- MySQL (v5.7 or higher)
- npm or yarn package manager

### 1. Clone/Download the Project
```bash
# If using git
git clone <repository-url>
cd library-management-system

# Or download and extract the files to your desired directory
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Database Setup

#### Option A: Using MySQL Command Line
```sql
-- Create database
CREATE DATABASE library_management;

-- Use the database
USE library_management;

-- Run the schema file
SOURCE database_schema.sql;
```

#### Option B: Using MySQL Workbench or phpMyAdmin
1. Create a new database named `library_management`
2. Import the `database_schema.sql` file

### 4. Environment Configuration
1. Copy `env.example` to `.env`
2. Update the database credentials in `.env`:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=your_mysql_username
DB_PASSWORD=your_mysql_password
DB_NAME=library_management
DB_PORT=3306

# JWT Secret (change this to a secure random string)
JWT_SECRET=your-super-secret-jwt-key-change-this

# Server Configuration
PORT=3000
```

### 5. Start the Server
```bash
# Development mode (with auto-restart)
npm run dev

# Or production mode
npm start
```

### 6. Access the Application
- **User Interface**: http://localhost:3000
- **Admin Interface**: http://localhost:3000/admin

## Default Login Credentials

### Admin Account
- **Username**: admin
- **Password**: password (hashed in database)
- **Email**: admin@library.com

### Sample User Accounts
- **Username**: john_doe, **Password**: password
- **Username**: jane_smith, **Password**: password
- **Username**: bob_wilson, **Password**: password

*Note: All sample passwords are hashed in the database. Use the registration form to create new accounts.*

## Database Schema

### Core Tables
- **users**: User accounts (both regular users and admins)
- **books**: Library book catalog
- **transactions**: Borrowing and returning records
- **categories**: Book categories for organization
- **book_categories**: Many-to-many relationship between books and categories
- **reservations**: Book reservation system
- **fines**: Overdue book fines

### Key Features
- **User Types**: Regular users and administrators
- **Book Availability**: Track total and available copies
- **Transaction History**: Complete borrowing/returning history
- **Overdue Tracking**: Automatic overdue detection
- **Search Optimization**: Indexed fields for fast searching

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Books (Public)
- `GET /api/books` - Get all books (with search filters)
- `GET /api/books/:id` - Get specific book details

### User Operations (Authenticated)
- `POST /api/transactions/borrow` - Borrow a book
- `POST /api/transactions/return` - Return a book
- `GET /api/transactions/my-books` - Get user's borrowed books

### Admin Operations (Admin Only)
- `GET /api/admin/users` - Get all users
- `POST /api/admin/books` - Add new book
- `PUT /api/admin/books/:id` - Update book
- `DELETE /api/admin/books/:id` - Delete book
- `GET /api/admin/transactions` - Get all transactions
- `GET /api/admin/statistics` - Get library statistics

## Usage Guide

### For Library Users
1. **Register**: Create a new account or use existing credentials
2. **Search Books**: Use the search form to find books by various criteria
3. **Borrow Books**: Click "Borrow Book" on available books
4. **Manage Books**: View your borrowed books in "My Books" section
5. **Return Books**: Return books before or on the due date

### For Administrators
1. **Login**: Use admin credentials to access admin panel
2. **Dashboard**: View library statistics and overview
3. **Book Management**: Add, edit, or remove books from the catalog
4. **User Management**: Monitor registered users
5. **Transaction Monitoring**: Track all borrowing activities

## Security Features

- **Password Hashing**: All passwords are securely hashed using bcryptjs
- **JWT Authentication**: Secure token-based authentication
- **Input Validation**: Server-side validation for all inputs
- **SQL Injection Protection**: Parameterized queries
- **Admin Access Control**: Separate admin authentication required

## Customization

### Adding New Book Categories
```sql
INSERT INTO categories (category_name, description) VALUES 
('Science Fiction', 'Science fiction and fantasy books');
```

### Modifying Due Date Period
Update the borrowing logic in `server.js`:
```javascript
// Change from 14 days to 21 days
due_date.setDate(due_date.getDate() + 21);
```

### Adding New User Fields
1. Update the database schema
2. Modify the registration form in `user.html`
3. Update the API endpoints in `server.js`

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Verify MySQL is running
   - Check database credentials in `.env`
   - Ensure database exists and schema is imported

2. **Port Already in Use**
   - Change the PORT in `.env` file
   - Kill existing processes using the port

3. **Authentication Issues**
   - Clear browser localStorage
   - Check JWT_SECRET in `.env`
   - Verify user exists in database

4. **Missing Dependencies**
   - Run `npm install` to install all dependencies
   - Check Node.js version compatibility

### Database Issues
```sql
-- Reset database (WARNING: This will delete all data)
DROP DATABASE library_management;
CREATE DATABASE library_management;
USE library_management;
SOURCE database_schema.sql;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Check the troubleshooting section
- Review the API documentation
- Ensure all prerequisites are met
- Verify database setup and configuration

## Future Enhancements

- Email notifications for due dates
- Book reservation system
- Fine calculation and payment
- Advanced reporting and analytics
- Mobile app integration
- Multi-library support
- Barcode scanning integration
