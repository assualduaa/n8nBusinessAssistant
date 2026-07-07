-- Append-only update: adds appointments/product_sales for 2026-07-05 and 2026-07-06
-- Safe to run against the LIVE salon-mysql container -- does NOT touch existing rows.
-- Run with:
--   docker exec -i salon-mysql mysql -u salon_app -p<your_password> salon < append_2026-07-05_06.sql

INSERT INTO appointments (appointment_id,customer_id,employee_id,branch_id,service_id,appointment_date,appointment_time,status,amount) VALUES
(374,5,7,3,7,'2026-07-05','13:15','Completed',8000.0),
(375,1,2,1,3,'2026-07-05','19:45','Completed',1500.0),
(376,6,5,2,2,'2026-07-05','12:15','Completed',2500.0),
(377,2,2,1,6,'2026-07-05','11:30','Completed',1000.0),
(378,20,2,1,7,'2026-07-05','13:15','Completed',8000.0),
(379,9,5,2,2,'2026-07-05','16:30','Cancelled',0.0),
(380,6,6,2,3,'2026-07-05','16:30','No-show',0.0),
(381,29,4,2,7,'2026-07-06','19:45','Cancelled',0.0),
(382,16,7,3,8,'2026-07-06','18:45','Completed',300.0),
(383,28,2,1,4,'2026-07-06','14:15','Cancelled',0.0),
(384,17,8,3,2,'2026-07-06','09:15','No-show',0.0);

INSERT INTO product_sales (sale_id,appointment_id,customer_id,employee_id,branch_id,product_id,sale_date,quantity,amount) VALUES
(140,375,1,2,1,2,'2026-07-05',1,700.0),
(141,378,20,2,1,5,'2026-07-05',2,1500.0);
