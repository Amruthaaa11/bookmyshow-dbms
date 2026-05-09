use bookmyshow;

SELECT 
s.show_id,sc.total_seats,count(bs.seat_id) as booked_seats,
case
when count(bs.seat_id)>=sc.total_seats then 'HOUSEFULL'
else 'AVAILABLE'
end as availability
from shows s
join screen sc on s.screen_id=sc.screen_id
left join booking b on s.show_id=b.show_id and b.status='confirmed'
left join booking_seat bs on b.booking_id=bs.booking_id and bs.seat_status='Booked'
group by s.show_id,sc.total_seats;

UPDATE SCREEN SET total_seats = 2 WHERE screen_id = 2;

UPDATE SCREEN SET total_seats = 10 WHERE screen_id = 2;