CREATE DATABASE ss14_second;
USE ss14_second;
-- 1. Bảng departments (Phòng ban)
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(255) NOT NULL
);

-- 2. Bảng employees (Nhân viên)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
);

-- 3. Bảng attendance (Chấm công)
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    total_hours DECIMAL(5,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 4. Bảng salaries (Bảng lương)
CREATE TABLE salaries (
    employee_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 5. Bảng salary_history (Lịch sử lương)
CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 2
delimiter //
create procedure IncreaseSalary(
    in empId int,
    in newSalary decimal(10,2),
    in reason text
)
begin
    declare oldSalary decimal(10,2);
    
    start transaction;

    select base_salary into oldSalary from salaries where employee_id = empId;

    if oldSalary is null then
        signal sqlstate '45000' set message_text = 'nhân viên không tồn tại!';
        rollback;
    else

        insert into salary_history (employee_id, old_salary, new_salary, reason)
        values (empId, oldSalary, newSalary, reason);

        update salaries 
        set base_salary = newSalary
        where employee_id = empId;

        commit;
    end if;
end //

delimiter ;

-- 3
call IncreaseSalary(1, 5000.00, 'tăng lương định kỳ');

-- 4
delimiter //

create procedure DeleteEmployee(
    in empId int
)
begin
    declare oldSalary decimal(10,2);

    start transaction;
    select base_salary into oldSalary from salaries where employee_id = empId;

    if oldSalary is null then
        signal sqlstate '45000' set message_text = 'nhân viên không tồn tại!';
        rollback;
    else
        insert into salary_history (employee_id, old_salary, new_salary, reason)
        values (empId, oldSalary, 0, 'nhân viên bị xóa khỏi hệ thống');

        delete from salaries where employee_id = empId;

        delete from employees where employee_id = empId;

        commit;
    end if;
end //
delimiter ;

-- 5
call DeleteEmployee(2);


