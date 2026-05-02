use bookmyshow;
INSERT INTO USER(name,email,phone,password_hash)values
('Rahul Sharma','rahul@gmail.com','987653212','hash_rahul'),
('Priya Menon','priya@gmail.com','876543210','hash_priya'),
('Arjun Reddy','arjun@gamil.com','789654321','hash_arjun');

insert into theater(name,city,address)values
('PVR Cinemad','Bangalore','Forum Mall,Kormanagala'),
('INOX Movies','Bangalore','Garuda Mall,MG Road');

insert into screen(theater_id,screen_name,total_seats)values
(1,'Screen 1',10),
(1,'Screen 2',10),
(2,'Screen 1',10),
(2,'Screen 2',10);

-- Screen 1 (PVR Screen 1) - Row A Silver, Row B Gold
INSERT INTO SEAT (screen_id, row_label, seat_number, category) VALUES
(1, 'A', 1, 'Silver'), (1, 'A', 2, 'Silver'), (1, 'A', 3, 'Silver'),
(1, 'A', 4, 'Silver'), (1, 'A', 5, 'Silver'),
-- Row A seats 1-5, all Silver category
(1, 'B', 1, 'Gold'), (1, 'B', 2, 'Gold'), (1, 'B', 3, 'Gold'),
(1, 'B', 4, 'Gold'), (1, 'B', 5, 'Gold');
-- Row B seats 1-5, all Gold category
-- seat_ids 1-10 are assigned automatically

-- Screen 2 (PVR Screen 2)
INSERT INTO SEAT (screen_id, row_label, seat_number, category) VALUES
(2, 'A', 1, 'Silver'), (2, 'A', 2, 'Silver'), (2, 'A', 3, 'Silver'),
(2, 'A', 4, 'Silver'), (2, 'A', 5, 'Silver'),
(2, 'B', 1, 'Gold'), (2, 'B', 2, 'Gold'), (2, 'B', 3, 'Gold'),
(2, 'B', 4, 'Gold'), (2, 'B', 5, 'Gold');
-- seat_ids 11-20 are assigned automatically

-- Screen 3 (INOX Screen 1)
INSERT INTO SEAT (screen_id, row_label, seat_number, category) VALUES
(3, 'A', 1, 'Silver'), (3, 'A', 2, 'Silver'), (3, 'A', 3, 'Silver'),
(3, 'A', 4, 'Silver'), (3, 'A', 5, 'Silver'),
(3, 'B', 1, 'Gold'), (3, 'B', 2, 'Gold'), (3, 'B', 3, 'Gold'),
(3, 'B', 4, 'Gold'), (3, 'B', 5, 'Gold');
-- seat_ids 21-30 are assigned automatically

-- Screen 4 (INOX Screen 2)
INSERT INTO SEAT (screen_id, row_label, seat_number, category) VALUES
(4, 'A', 1, 'Silver'), (4, 'A', 2, 'Silver'), (4, 'A', 3, 'Silver'),
(4, 'A', 4, 'Silver'), (4, 'A', 5, 'Silver'),
(4, 'B', 1, 'Platinum'), (4, 'B', 2, 'Platinum'), (4, 'B', 3, 'Platinum'),
(4, 'B', 4, 'Platinum'), (4, 'B', 5, 'Platinum');
-- Row B here is Platinum instead of Gold, just to add variety
-- seat_ids 31-40 are assigned automatically

INSERT INTO MOVIE (title, genre, language, duration_mins, release_date) VALUES
('RRR', 'Action', 'Telugu', 182, '2022-03-25'),
-- movie_id = 1, duration 182 mins
('KGF Chapter 2', 'Action', 'Kannada', 168, '2022-04-14'),
-- movie_id = 2, duration 168 mins
('Jawan', 'Thriller', 'Hindi', 169, '2023-09-07');
-- movie_id = 3, duration 169 mins

INSERT INTO SHOWS(movie_id,screen_id,show_time,price)values
(1,1,'2026-04-01 10:00:00',150.00),
(1,2,'2026-04-01 14:00:00',180.00),
(2,3,'2026-04-01 11:00:00',160.00),
(3,4,'2026-04-01 18:00:00',200.00);

INSERT INTO BOOKING (user_id, show_id, status, total_amount) VALUES
(1, 17, 'Confirmed', 300.00),
(2, 19, 'Confirmed', 160.00);

INSERT INTO BOOKING_SEAT (booking_id, seat_id, seat_status) VALUES
(9, 1, 'Booked'),
(9, 2, 'Booked'),
(10, 21, 'Booked');

INSERT INTO PAYMENT (booking_id, method, status) VALUES
(9, 'UPI', 'Success'),
(10, 'Card', 'Success');