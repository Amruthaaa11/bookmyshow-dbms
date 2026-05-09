from flask import Flask, render_template, request, redirect, url_for, session
from db import get_connection, get_cursor


# ============================================================
#  app.py — Main Flask application
#  Run with: python app.py
#  Then open: http://127.0.0.1:5000
# ============================================================

app = Flask(__name__)
app.secret_key = 'bookmyshow_secret'


# ============================================================
#  Route 1: Home — redirect to login
# ============================================================
@app.route('/')
def home():
    return redirect('/login')


# ============================================================
#  Route 2: Login
# ============================================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        connection = get_connection()
        cursor = get_cursor(connection)

        cursor.execute(
            "SELECT * FROM USER WHERE email = %s AND password_hash = %s",
            (email, password)
        )
        user = cursor.fetchone()

        cursor.close()
        connection.close()

        if user:
            session['user_id'] = user['user_id']
            session['name'] = user['name']
            return redirect('/index')
        else:
            return render_template('login.html', error='Invalid email or password')

    return render_template('login.html')


# ============================================================
#  Route 3: Register
# ============================================================
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        phone = request.form['phone']
        password = request.form['password']

        connection = get_connection()
        cursor = get_cursor(connection)

        try:
            cursor.execute(
                "INSERT INTO USER (name, email, phone, password_hash) VALUES (%s, %s, %s, %s)",
                (name, email, '+91'+phone, password)
            )
            connection.commit()
            cursor.close()
            connection.close()
            return redirect('/login')

        except:
            cursor.close()
            connection.close()
            return render_template('register.html', error='Email or phone already exists')

    return render_template('register.html')


# ============================================================
#  Route 4: Index — show all movies
# ============================================================
@app.route('/index')
def index():
    if 'user_id' not in session:
        return redirect('/login')

    connection = get_connection()
    cursor = get_cursor(connection)

    cursor.execute("SELECT * FROM MOVIE")
    movies = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template('index.html', movies=movies)


# ============================================================
#  Route 5: Movie detail — show available shows
# ============================================================
@app.route('/movie/<int:movie_id>')
def movie(movie_id):
    if 'user_id' not in session:
        return redirect('/login')

    connection = get_connection()
    cursor = get_cursor(connection)

    cursor.execute("SELECT * FROM MOVIE WHERE movie_id = %s", (movie_id,))
    movie = cursor.fetchone()

    cursor.execute(
        "SELECT * FROM available_shows WHERE movie_id = %s",
        (movie_id,)
    )
    shows = cursor.fetchall()

    # get availability for each show
    cursor.execute(
        """SELECT 
            sh.show_id,
            CASE 
                WHEN COUNT(bs.seat_id) >= sc.total_seats THEN 'Housefull'
                ELSE 'Available'
            END as availability
        FROM SHOWS sh
        JOIN SCREEN sc ON sh.screen_id = sc.screen_id
        LEFT JOIN BOOKING b ON sh.show_id = b.show_id AND b.status = 'confirmed'
        LEFT JOIN BOOKING_SEAT bs ON b.booking_id = bs.booking_id AND bs.seat_status = 'Booked'
        WHERE sh.movie_id = %s
        GROUP BY sh.show_id, sc.total_seats""",
        (movie_id,)
    )
    availability = {row['show_id']: row['availability'] for row in cursor.fetchall()}

    cursor.close()
    connection.close()

    return render_template('movie.html', movie=movie, shows=shows, availability=availability)

# ============================================================
#  Route 6: Booking — seat selection
# ============================================================
@app.route('/booking/<int:show_id>')
def booking(show_id):
    if 'user_id' not in session:
        return redirect('/login')

    connection = get_connection()
    cursor = get_cursor(connection)

    cursor.execute(
        """SELECT s.*, m.title FROM SHOWS s
           JOIN MOVIE m ON s.movie_id = m.movie_id
           WHERE s.show_id = %s""",
        (show_id,)
    )
    show = cursor.fetchone()

    cursor.execute(
        """SELECT s.*,
           CASE 
               WHEN s.category='silver' THEN sh.base_price
               WHEN s.category='gold' THEN ROUND(sh.base_price*1.5,2)
            END as seat_price
            FROM SEAT s
            JOIN shows sh ON sh.show_id=%s
            WHERE s.screen_id=%s""",
        (show_id,show['screen_id'])
    )
    seats = cursor.fetchall()

    cursor.execute(
        """SELECT bs.seat_id FROM BOOKING_SEAT bs
           JOIN BOOKING b ON bs.booking_id = b.booking_id
           WHERE b.show_id = %s AND bs.seat_status = 'Booked'""",
        (show_id,)
    )
    booked_seats = [row['seat_id'] for row in cursor.fetchall()]

    cursor.close()
    connection.close()

    return render_template('booking.html',
                           show=show,
                           seats=seats,
                           booked_seats=booked_seats)


# ============================================================
#  Route 7: Confirm booking
# ============================================================
@app.route('/confirm_booking', methods=['POST'])
def confirm_booking():
    if 'user_id' not in session:
        return redirect('/login')

    show_id = int(request.form['show_id'])
    seat_ids = request.form['seat_ids']
    payment_method = request.form['payment_method']
    user_id = session['user_id']

    if not seat_ids:
        return redirect('/booking/' + str(show_id))

    connection = get_connection()
    cursor = get_cursor(connection)

    try:
        # get price per seat based on category
        seat_id_list = [int(s) for s in seat_ids.split(',')]
        total = 0.0
        for seat_id in seat_id_list:
            cursor.execute(
                """SELECT 
                   CASE
                       WHEN s.category='silver' THEN sh.base_price
                       WHEN s.category='gold' THEN ROUND(sh.base_price*1.5,2)
                    END as seat_price
                    FROM SEAT s
                    JOIN SHOWS sh ON sh.show_id=%s
                    WHERE s.seat_id=%s""",
                    (show_id, seat_id)
            )
            result = cursor.fetchone()
            total += float(str(result['seat_price']))

        # create booking
        cursor.execute(
            "INSERT INTO BOOKING (user_id, show_id, status, total_amount) VALUES (%s, %s, 'confirmed', %s)",
            (user_id, show_id, total)
        )
        booking_id = cursor.lastrowid

        # insert each seat
        for seat_id in seat_id_list:
            cursor.execute(
                "INSERT INTO BOOKING_SEAT (booking_id, seat_id, seat_status) VALUES (%s, %s, 'Booked')",
                (booking_id, seat_id)
            )

        # insert payment
        cursor.execute(
            "INSERT INTO PAYMENT (booking_id, method, status) VALUES (%s, %s, 'Success')",
            (booking_id, payment_method)
        )

        connection.commit()
        cursor.close()
        connection.close()

        return redirect('/confirmation/' + str(booking_id))

    except Exception as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return render_template('booking.html', error=str(e))
# ============================================================
#  Route 8: Confirmation page
# ============================================================
@app.route('/confirmation/<int:booking_id>')
def confirmation(booking_id):
    if 'user_id' not in session:
        return redirect('/login')

    connection = get_connection()
    cursor = get_cursor(connection)

    cursor.execute(
        "SELECT * FROM booking_summary WHERE booking_id = %s",
        (booking_id,)
    )
    booking = cursor.fetchone()

    cursor.close()
    connection.close()

    return render_template('confirmation.html', booking=booking)


# ============================================================
#  Route 9: Logout
# ============================================================
@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')


#=============================================================
#Route 10:My bookings
#=============================================================
@app.route('/my_bookings')
def my_bookings():
    if 'user_id' not in session:
        return redirect('/login')

    connection = get_connection()
    cursor = get_cursor(connection)

    filter = request.args.get('filter', 'all')

    if filter == 'confirmed':
        cursor.execute(
            "SELECT * FROM booking_summary WHERE user_id = %s AND booking_status = 'confirmed'",
            (session['user_id'],)
        )
    elif filter == 'cancelled':
        cursor.execute(
            "SELECT * FROM booking_summary WHERE user_id = %s AND booking_status = 'cancelled'",
            (session['user_id'],)
        )
    else:
        cursor.execute(
            "SELECT * FROM booking_summary WHERE user_id = %s",
            (session['user_id'],)
        )

    bookings = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template('my_bookings.html', bookings=bookings, filter=filter)

#=============================================================
#Route 11:Cancel Booking
#=============================================================
@app.route('/cancel_booking/<int:booking_id>')
def cancel_booking(booking_id):
    if 'user_id' not in session:
        return redirect('/login')
    
    connection=get_connection()
    cursor=get_cursor(connection)

    try:
        cursor.execute(
            "UPDATE BOOKING SET status='Cancelled' WHERE booking_id=%s and user_id=%s",
            (booking_id,session['user_id'])
        )

        cursor.execute(
            "UPDATE BOOKING_SEAT SET seat_status='Cancelled' WHERE booking_id=%s",
            (booking_id,)
        )

        connection.commit()

    except Exception as e:
        connection.rollback()
    
    finally:
        cursor.close()
        connection.close()

    return redirect('/my_bookings')
# ============================================================
#  Route 12: User Profile
# ============================================================
@app.route('/profile', methods=['GET', 'POST'])
def profile():
    if 'user_id' not in session:
        return redirect('/login')

    connection = get_connection()
    cursor = get_cursor(connection)

    success = None

    if request.method == 'POST':
        phone = request.form['phone']
        cursor.execute(
            "UPDATE USER SET phone = %s WHERE user_id = %s",
            ('+91' + phone, session['user_id'])
        )
        connection.commit()
        success = 'Phone number updated successfully!'

    cursor.execute(
        "SELECT * FROM USER WHERE user_id = %s",
        (session['user_id'],)
    )
    user = cursor.fetchone()

    cursor.close()
    connection.close()

    return render_template('profile.html', user=user, success=success)
# ============================================================
#  Run the app
# ============================================================
if __name__ == '__main__':
    app.run(debug=True)

