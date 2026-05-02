create database bookmyshow;
use bookmyshow;

create table user(
  user_id int auto_increment primary key,
  name varchar(100) not null,
  email varchar(100) unique not null,
  phone char(10) unique not null,
  password_hash varchar(255) not null,
  created_at timestamp default current_timestamp
);

create table theater(
  theater_id int auto_increment primary key,
  name varchar(100) not null,
  city varchar(50) not null,
  address varchar(255) not null
);

create table booking_seat(
  booking_id int not null,
  seat_id int not null,
  seat_status enum('booked','cancelled') not null default 'booked',
  primary key(booking_id,seat_id),
  foreign key(booking_id)references booking(booking_id) on delete cascade,
  foreign key(seat_id) references seat(seat_id) on delete cascade
);

create table seat(
  seat_id int auto_increment primary key,
  screen_id int not null,
  row_label char(1) not null,
  seat_number int not null,
  category enum('silver','gold','platinum') not null,
  foreign key(screen_id) references screen(screen_id) on delete cascade,
  unique(screen_id,row_label,seat_number)
);

create table movie(
  movie_id int auto_increment primary key,
  title varchar(150) not null,
  genre varchar(50) not null,
  language varchar(30) not null,
  duration_mins int not null,
  release_date date not null
);

create table Shows(
  show_id int auto_increment primary key,
  movie_id int not null,
  screen_id int not null,
  show_time datetime not null,
  price decimal(8,2) not null,
  foreign key(movie_id) references movie(movie_id) on delete cascade,
  foreign key(screen_id) references screen(screen_id) on delete cascade,
  unique(screen_id,show_id)
);

create table booking(
  booking_id int auto_increment primary key,
  user_id int not null,
  show_id int not null,
  booked_at timestamp default current_timestamp,
  status enum('confirmed','cancelled','pending')not null default 'pending',
  total_amount decimal(8,2) not null,
  foreign key(user_id) references user(user_id) on delete cascade,
  foreign key(show_id) references shows(show_id) on delete cascade
);

create table payment(
  payment_id int auto_increment primary key,
  booking_id int not null,
  method enum('upi','card','netbanking','wallet') not null,
  status enum('success','failed','refunded') not null,
  paid_at timestamp default current_timestamp,
  foreign key(booking_id) references booking(booking_id) on delete cascade
  );
  
delimiter $$
  create trigger prevent_double_booking
  before insert on booking_seat
  for each row
  begin
     declare seat_taken int;
     select count(*) into seat_taken
     from booking_seat bs
     join booking b on bs.booking_id=b.booking_id
     where bs.seat_id=new.seat_id
       and b.show_id=(
             select show_id from booking
             where booking_id=new.booking_id
		)
        and bs.seat_status='booked';
        
        if seat_taken>0 then
           signal sqlstate '45000'
           set message_text='seat is already booked for this show';
		end if;
end$$
delimiter ;

delimiter $$
create trigger after_booking_cancelled
after update on booking
for each row
begin
  if new.status='cancelled' and old.status!='cancelled' then
    update booking_seat
    set seat_status='cancelled'
    where booking_id =new.booking_id;
  end if;
end$$

delimiter ;

use bookmyshow;
CREATE VIEW available_shows AS
SELECT 
    s.show_id,
    m.title AS movie_name,
    m.language,
    m.duration_mins,
    t.name AS theater_name,
    t.city,
    sc.screen_name,
    s.show_time,
    s.price
FROM SHOWS s
JOIN MOVIE m ON s.movie_id = m.movie_id
JOIN SCREEN sc ON s.screen_id = sc.screen_id
JOIN THEATER t ON sc.theater_id = t.theater_id
WHERE s.show_time > NOW();

CREATE VIEW booking_summary AS
SELECT
    b.booking_id,
    u.name AS user_name,
    u.email,
    m.title AS movie_name,
    t.name AS theater_name,
    sc.screen_name,
    s.show_time,
    se.row_label,
    se.seat_number,
    se.category,
    b.total_amount,
    b.status AS booking_status,
    p.method AS payment_method,
    p.status AS payment_status
FROM BOOKING b
JOIN USER u ON b.user_id = u.user_id
JOIN SHOWS s ON b.show_id = s.show_id
JOIN MOVIE m ON s.movie_id = m.movie_id
JOIN SCREEN sc ON s.screen_id = sc.screen_id
JOIN THEATER t ON sc.theater_id = t.theater_id
JOIN BOOKING_SEAT bs ON b.booking_id = bs.booking_id
JOIN SEAT se ON bs.seat_id = se.seat_id
JOIN PAYMENT p ON b.booking_id = p.booking_id;

DELIMITER $$

CREATE procedure book_seats(
  IN p_user_id int,
  in p_show_id int,
  in p_seat_ids text,
  in p_payment_method enum('upi','card','netbanking','wallet'),
  out p_booking_id int 
)
begin
  declare seat_price decimal(8,2);
  declare seat_count int;
  declare total decimal(8,2);
  
  declare exit handler for sqlexception
  begin
    rollback;
  end;
  start transaction;
  select price into seat_price
  from shows
  where show_id =p_show_id;
  
  set seat_count=(length(p_seat_ids)-length(REPLACE(p_seat_ids,',',''))+1);
  set total=seat_price*seat_count;
  insert into booking(user_id,show_id,status,total_amount)
  values(p_user_id,p_show_id,'confirmed','total');
  
  set p_booking_id=last_insert_id();
  INSERT INTO BOOKING_SEAT(booking_id, seat_id, seat_status)
        SELECT p_booking_id, TRIM(value), 'Booked'
        FROM JSON_TABLE(
            CONCAT('["', REPLACE(p_seat_ids, ',', '","'), '"]'),
            '$[*]' COLUMNS(value VARCHAR(10) PATH '$')
        ) AS seat_list;
    insert into payment(booking_id,method,status)
    values(p_booking_id,p_payment_method,'success');
  commit;
end$$

delimiter ;
#QUERY 1: TO SELECT AVAILABEL SEATS FROM A SHOW(EXCLUDING THE PREBOOKED SEATS)
select
  se.seat_id,
  se.row_label,
  se.seat_number,
  se.category
from seat se
where se.screen_id=(
  select screen_id from shows where show_id=1
)
and se.seat_id not in(
  select bs.seat_id
  from booking_seat bs
  join booking b on bs.booking_id=b.booking_id
  where b.show_id=1
  and bs.seat_status='booked'
);

#QUERY 2:TOTAL REVENUE PER MOVIE

SELECT
  m.title as movie_name,
  count(distinct b.booking_id)as total_bookings,
  sum(b.total_amount) as total_revenue
from booking b
join shows s on b.show_id=s.show_id
join movie m on s.movie_id=m.movie_id
where b.status='confirmed'
group by m.movie_id,m.title;

#QUERY 3:MOST BOOKED MOVIES THIS WEEK

select
  m.title as movie_name,
  count(bs.seat_id) as seats_booked
from booking_seat bs
join booking b on bs.booking_id=b.booking_id
join shows s on b.show_id=s.show_id
join movie m on s.movie_id=m.movie_id
where b.booked_at>=date_sub(now(),interval 7 day)
and bs.seat_status='booked'
group by m.movie_id,m.title
order by seats_booked desc
limit 5;

#QUERY 4:SHOWS WITH AVAILALE SEAT COUNT
select
  s.show_id,
  m.title as movie_name,
  sc.screen_name,
  s.show_time,
  s.price,
  sc.total_seats-count(bs.seat_id) as available_seats
from shows s
join movie m on s.movie_id=m.movie_id
join screen sc on s.screen_id=sc.screen_id
left join booking b on s.show_id=b.show_id and b.status='confirmed'
left join booking_seat bs on b.booking_id=bs.booking_id and bs.seat_status='booked'
where s.show_time>now()
group by s.show_id,m.title,sc.screen_name,s.show_time,s.price,sc.total_seats
having available_seats>0;


select
  b.booking_id,
  m.title as movie_name,
  t.name as theater_name,
  s.show_time,
  se.row_label,
  se.seat_number,
  se.category,
  b.total_amount,
  b.status,
  p.method as payment_method
from booking b
join shows s on b.show_id=s.show_id
join movie m on s.movie_id=m.movie_id
join screen sc on s.screen_id=sc.screen_id
join theater t on sc.theater_id = t.theater_id
join booking_seat bs on b.booking_id=bs.booking_id
join seat se on bs.seat_id=se.seat_id
join payment p on b.booking_id=p.booking_id
where b.user_id=1;


