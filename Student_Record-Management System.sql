create table Students(
student_id int primary key,
name varchar,
email varchar,
city varchar
)
copy Students from 'D:/SQL SOFTRONIX/PROJECTS/Student Record Management System/students.csv'
delimiter ',' csv header


create table Instructors(
instructor_id int primary key,
name varchar,
email varchar,
expertise varchar
)
copy Instructors from 'D:/SQL SOFTRONIX/PROJECTS/Student Record Management System/instructors.csv'
delimiter ',' csv header


create table Courses (
course_id int primary key,
title varchar,
category varchar,
instructor_id int,
foreign key (instructor_id)
references Instructors(instructor_id),
price int
)
copy Courses from 'D:/SQL SOFTRONIX/PROJECTS/Student Record Management System/courses.csv'
delimiter ',' csv header


create table Enrollments(
enrollment_id int primary key,
student_id int,
foreign key(student_id)
references Students(student_id),
course_id int,
foreign key(course_id)
references Courses (course_id),
enrollment_date date
)

SET datestyle = 'ISO, DMY';
copy Enrollments from 'D:/SQL SOFTRONIX/PROJECTS/Student Record Management System/enrollments.csv'
delimiter ',' csv header

-------1--------
select title,price from Courses 
where category='Data Science' and price<2000
order by price asc

-------2--------
select category,count(*) as total_courses 
from Courses group by category

-------3--------
select C.category ,count(enrollment_id) as Total_Enrollments
from Courses as C inner join Enrollments as E
on C.course_id=E.course_id group by C.category having count(enrollment_id)>150

-------4--------
select title,price from Courses order by price desc limit 5

-------5--------
select *from Students where city='London' order by student_id limit 5 offset 5

-----------------------------PART 2 :--> ADVANCED QUERIES  --------------------------------------------

-------6--------
select C.title,Ins.name as Instructor_name from Courses as C 
inner join Instructors as Ins on C.instructor_id=Ins.instructor_id

-------7--------
select Ins.name as Instructor_name,C.title as Course_Title 
from Instructors as Ins left join 
Courses as C on Ins.instructor_id=C.instructor_id

-------8--------
select Stu.name as Student_Name ,C.title as Course_Title,Ins.name as Instructors_Name from Students as Stu 
inner join Enrollments as E on Stu.student_id=E.student_id inner join Courses as C on E.course_id=C.course_id
inner join Instructors as  Ins on C.instructor_id=Ins.instructor_id where Stu.city='New York'

-------9--------
select distinct Stu.name as Students_Name ,Stu.city as Students_City from Students as Stu 
inner join Enrollments as E on Stu.student_id=E.student_id 
inner join Courses as C on E.course_id=C.course_id where category='Cloud'

-------10--------
select title,price from Courses
where price >(select avg(price)from Courses)

-------11--------
select  Ins.name,Ins.expertise from Instructors as Ins  inner join Courses as C on Ins.instructor_id=C.instructor_id
group by Ins.instructor_id,Ins.name,Ins.expertise order by count(C.course_id) desc

-------12--------
select name from Students 
union 
select name from Instructors

-------13--------
SELECT course_id
FROM Enrollments
WHERE EXTRACT(YEAR FROM enrollment_date) IN (2024, 2025)
GROUP BY course_id
HAVING COUNT(DISTINCT EXTRACT(YEAR FROM enrollment_date)) = 2

-------14--------
select distinct  course_id from Enrollments where extract(year from enrollment_date) =2025
except 
select distinct course_id from Enrollments where extract(year from enrollment_date)=2024

-------15--------
select title,category,price,rank() 
over(partition by category order by price desc)
as Course_rank from Courses;

-------16--------
select title,category,price ,avg(price) 
over(partition by category)as category_avg_price,
price-avg(price) over(partition by category) 
as Price_Difference from Courses


-----------------------------PART 3 :--> DATABASE MANAGEMENT AND SECURITY QUESTIONS--------------------------------------------

-------17--------
create or replace function get_course_enrollment_count(p_course_id int)
returns int as $$
declare enrollment_count int;
begin 
select count(*) into enrollment_count 
from Enrollments
where course_id=p_course_id;
return enrollment_count;
end;
$$ language plpgsql;

select get_course_enrollment_count(25)

-------18--------
create table course_price_audit(
audit_id serial primary key,
course_id int,
old_price int,
new_price int
)

-------19--------
---Creating a function for price update 
create or replace function course_price_Update()
returns trigger as $$
begin
insert into course_price_audit(
course_id,
old_price,
new_price
)
values(
old.course_id,
old.price,
new.price
);
return new;
end;
$$ language plpgsql;


---creating a Trigger for updated price
create trigger Update_Course_PriceData
after update of price on Courses
for each row
execute function course_price_Update()

update Courses 
set price =35000 where course_id=5

------------------***XXXX****----------------
------20------------
ALTER TABLE Enrollments
ALTER COLUMN enrollment_id
ADD GENERATED ALWAYS AS IDENTITY;

create or replace procedure add_new_enrollment(in p_student_id int,in p_course_id int, in p_enrollment_date date default current_date)
language plpgsql
as $$
begin 
insert into Enrollments(student_id,
course_id,
enrollment_date
)values(p_student_id,
p_course_id,
p_enrollment_date
);
end;
$$;

call add_new_enrollment(30,2,'2025-06-01')
call add_new_enrollment(30,2)

--------------21-------------
select
    (
        extract(year from current_date) * 12
        + extract(month from current_date)
    )
    -
    (
        extract(year from min(enrollment_date)) * 12
        + extract(month from min(enrollment_date))
    ) as months_passed
from Enrollments;

-------22------------------------------------------
select upper(name),email from Students where UPPER(name)  like '%JACKSON%';
--------------23------------------------------------
create role auditor
grant select on 
Enrollments to auditor
grant select on Students
to auditor
revoke  select (city)
on Students from auditor
---------------------24---------------------------------
create view v_instructor_performance as
select Ins.name as Instructor_Name,
C.title as Course_Title,
count(*) as Total_Enrollments

from Instructors as Ins 
inner join Courses as C
on Ins.instructor_id=C.instructor_id 
left join Enrollments as E 
on C.course_id=E.course_id

group by Ins.instructor_id,Ins.name,C.course_id,C.title

select *from v_instructor_performance

------------------------25--------------------------------------------
create index idx_courses_category
on Courses(category)

select *from Courses where Category='Data Science'