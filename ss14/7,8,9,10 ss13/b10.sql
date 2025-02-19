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

 create table student_status(
	student_id int,
    foreign key (student_id) references students(student_id),
    status enum('ACTIVE', 'GRADUATED', 'SUSPENDED')
 );

INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký

-- 2
CREATE TABLE course_fees (

    course_id INT PRIMARY KEY,

    fee DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE

);

CREATE TABLE student_wallets (

    student_id INT PRIMARY KEY,

    balance DECIMAL(10,2) NOT NULL DEFAULT 0,

    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE

);

-- 3
INSERT INTO course_fees (course_id, fee) VALUES

(1, 100.00), -- Lập trình C: 100$

(2, 150.00); -- Cơ sở dữ liệu: 150$

 

INSERT INTO student_wallets (student_id, balance) VALUES

(1, 200.00), -- Nguyễn Văn An có 200$

(2, 50.00);  -- Trần Thị Ba chỉ có 50$

-- 4
delimiter //

create procedure register_course(
    in p_student_name varchar(50),
    in p_course_name varchar(100)
)
begin
    declare studentId int;
    declare courseId int;
    declare availableSeats int;
    declare studentBalance decimal(10,2);
    declare courseFee decimal(10,2);
    declare enrollmentCount int;
    declare statusMessage varchar(50);

    start transaction;

    select student_id into studentId
    from students
    where student_name = p_student_name;

	if studentId is null then
        set statusMessage = 'FAILED: Student does not exist';
        insert into transaction_log (student_id, course_id, action)
        values (null, null, statusMessage);
        rollback;
        signal sqlstate '45000' set message_text = statusMessage;
    end if;

    select course_id, available_seats into courseId, availableSeats
    from courses
    where course_name = p_course_name;

    if courseId is null then
        set statusMessage = 'FAILED: Course does not exist';
        insert into transaction_log (student_id, course_id, action)
        values (studentId, null, statusMessage);
        rollback;
        select statusMessage as message;
    end if;

    select count(*) into enrollmentCount
    from enrollments
    where student_id = studentId and course_id = courseId;

    if enrollmentCount > 0 then
        set statusMessage = 'FAILED: Already enrolled';
        insert into transaction_log (student_id, course_id, action)
        values (studentId, courseId, statusMessage);
        rollback;
        select statusMessage as message;
    end if;

    if availableSeats <= 0 then
        set statusMessage = 'FAILED: No available seats';
        insert into transaction_log (student_id, course_id, action)
        values (studentId, courseId, statusMessage);
        rollback;
        select statusMessage as message;
    end if;

    select balance into studentBalance
    from student_wallets
    where student_id = studentId;

    select fee into courseFee
    from course_fees
    where course_id = courseId;

    if studentBalance < courseFee then
        set statusMessage = 'FAILED: Insufficient balance';
        insert into transaction_log (student_id, course_id, action)
        values (studentId, courseId, statusMessage);
        rollback;
        select statusMessage as message;
    end if;

    insert into enrollments (student_id, course_id)
    values (studentId, courseId);

    update student_wallets
    set balance = balance - courseFee
    where student_id = studentId;

    update courses
    set available_seats = available_seats - 1
    where course_id = courseId;

    set statusMessage = 'REGISTERED';
    insert into transaction_log (student_id, course_id, action)
    values (studentId, courseId, statusMessage);
    commit;
    select statusMessage as message;
end //

delimiter ;

-- 5
call register_course('Nguyễn Văn An', 'Lập trình C');

-- 6 
select * from student_wallets;
