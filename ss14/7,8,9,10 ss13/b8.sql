create database ss13;
use ss13;
CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(50)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_name VARCHAR(100),
    available_seats INT NOT NULL
);

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
INSERT INTO students (student_name) VALUES ('Nguyễn Văn An'), ('Trần Thị Ba');

INSERT INTO courses (course_name, available_seats) VALUES 
('Lập trình C', 25), 
('Cơ sở dữ liệu', 22);

create table transaction_log(
	history_id int primary key auto_increment,
    student_id int,
    foreign key(student_id) references students(student_id),
    course_id int,
    foreign key (course_id) references courses(course_id),
    action varchar(50),
    timestamp datetime default current_timestamp
);
 -- 2
 create table student_status(
	student_id int,
    foreign key (student_id) references students(student_id),
    status enum('ACTIVE', 'GRADUATED', 'SUSPENDED')
 );

-- 3
INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký

-- 4

delimiter //
create trigger check_student_status
before insert on enrollments
for each row
begin
    declare student_status_val enum('ACTIVE', 'GRADUATED', 'SUSPENDED');
    
    select status into student_status_val from student_status where student_id = new.student_id;
    
    if student_status_val in ('GRADUATED', 'SUSPENDED') then
        signal sqlstate '45000'
        set message_text = 'FAILED: Student not eligible';
    end if;
end //
delimiter ;

delimiter //
create procedure enroll_student(
    in p_student_name varchar(50),
    in p_course_name varchar(100)
)
begin
    declare student_id_val int;
    declare course_id_val int;
    declare available_seats_val int;
    declare error_message text;
    
    declare exit handler for sqlexception
    begin
        rollback;
        insert into transaction_log (student_id, course_id, action) 
        values (student_id_val, course_id_val, 'FAILED: Transaction error');
    end;
    
    start transaction;

    select student_id into student_id_val from students where student_name = p_student_name;
    if student_id_val is null then
        set error_message = 'FAILED: Student does not exist';
        insert into transaction_log (student_id, course_id, action) 
        values (null, null, error_message);
        rollback;
    end if;

    select course_id, available_seats into course_id_val, available_seats_val from courses 
    where course_name = p_course_name;
    if course_id_val is null then
        set error_message = 'FAILED: Course does not exist';
        insert into transaction_log (student_id, course_id, action)
        values (student_id_val, null, error_message);
        rollback;
    end if;
    
    if exists (select 1 from enrollments where student_id = student_id_val and course_id = course_id_val)
    then
        set error_message = 'FAILED: Already enrolled';
        insert into transaction_log (student_id, course_id, action) 
        values (student_id_val, course_id_val, error_message);
        rollback;
    end if;
    
    if available_seats_val > 0 then
        insert into enrollments (student_id, course_id) 
        values (student_id_val, course_id_val);
        
        update courses 
        set available_seats = available_seats - 1 
        where course_id = course_id_val;
        
        insert into transaction_log (student_id, course_id, action) 
        values (student_id_val, course_id_val, 'REGISTERED');
        commit;
    else
        set error_message = 'FAILED: No available seats';
        insert into transaction_log (student_id, course_id, action) 
        values (student_id_val, course_id_val, error_message);
        rollback;
    end if;
end //
delimiter ;

-- 5
delimiter ;
call enroll_student('Nguyễn Văn An', 'Lập trình C');

-- 6
select * from enrollments;
select * from courses;
select * from transaction_log;




