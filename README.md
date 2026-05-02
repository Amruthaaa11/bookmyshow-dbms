# BookMyShow — DBMS Project

A BookMyShow-like web application built as a Database Management Systems project.

## Technologies Used
- Frontend: HTML, Bootstrap 5
- Backend: Python, Flask
- Database: MySQL

## Project Structure
```
bookmyshow/
├── app.py              # Flask routes
├── db.py               # MySQL connection
├── requirements.txt    # Python dependencies
├── schema.sql          # Database tables
├── insert_data.sql     # Sample data
├── triggers.sql        # Triggers, views, stored procedure
├── queries.sql         # Complex SQL queries
├── templates/
│   ├── login.html
│   ├── register.html
│   ├── index.html
│   ├── movie.html
│   ├── booking.html
│   └── confirmation.html
└── static/
    ├── style.css
    └── script.js
```

## Features
- User registration and login
- Browse movies
- View available shows per movie
- Select seats with real-time availability
- Book tickets with payment method selection
- Booking confirmation page
- Double booking prevention via database trigger
- Auto seat cancellation via database trigger

## Database Objects
- 9 Tables: USER, THEATER, SCREEN, SEAT, MOVIE, SHOWS, BOOKING, BOOKING_SEAT, PAYMENT
- 2 Triggers: prevent_double_booking, after_booking_cancelled
- 2 Views: available_shows, booking_summary
- 1 Stored Procedure: book_seats
- 5 Complex Queries in queries.sql

## Setup Instructions

### Step 1: Install Python dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Setup MySQL database
Open MySQL Workbench and run these files in order:
1. schema.sql
2. insert_data.sql
3. triggers.sql

### Step 3: Update database password
Open db.py and replace yourpassword with your MySQL root password:
```python
password="yourpassword"
```

### Step 4: Run the app
```bash
python app.py
```

### Step 5: Open browser
```
http://127.0.0.1:5000
```

## Sample Login Credentials
| Name | Email | Password |
|------|-------|----------|
| Rahul Sharma | rahul@gmail.com | hash_rahul |
| Priya Menon | priya@gmail.com | hash_priya |
| Arjun Reddy | arjun@gmail.com | hash_arjun |
