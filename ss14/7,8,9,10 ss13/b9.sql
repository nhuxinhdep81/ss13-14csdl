create database ss13;
use ss13;
CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY AUTO_INCREMENT,
    balance DECIMAL(15,2) NOT NULL -- Số dư quỹ công ty
)ENGINE=InnoDB;

CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,   -- Tên nhân viên
    salary DECIMAL(10,2) NOT NULL    -- Lương nhân viên
)ENGINE=InnoDB;

CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,                      -- ID nhân viên (FK)
    salary DECIMAL(10,2) NOT NULL,   -- Lương được nhận
    pay_date DATE NOT NULL,          -- Ngày nhận lương
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
)ENGINE=InnoDB;


INSERT INTO company_funds (balance) VALUES (50000.00);

INSERT INTO employees (emp_name, salary) VALUES
('Nguyễn Văn An', 5000.00),
('Trần Thị Bốn', 4000.00),
('Lê Văn Cường', 3500.00),
('Hoàng Thị Dung', 4500.00),
('Phạm Văn Em', 3800.00);
create table transaction_log(
	log_id int primary key auto_increment,
    log_message text not null,
    log_time timestamp default current_timestamp
);

create table banks(
	bank_id int primary key auto_increment,
    bank_name varchar(255) not null,
    status enum('ACTIVE', 'ERROR')
);

INSERT INTO banks (bank_id, bank_name, status) 
VALUES 

(1,'VietinBank', 'ACTIVE'),   

(2,'Sacombank', 'ERROR'),    

(3, 'Agribank', 'ACTIVE');   

-- 2
create table account(
	acc_id int primary key auto_increment,
    emp_id int,
    foreign key (emp_id) references employees(emp_id),
    bank_id int,
    foreign key (bank_id) references banks (bank_id),
    amount_added decimal(15,2),
    total_amount decimal(15,2)
);

-- 3

INSERT INTO account (emp_id, bank_id, amount_added, total_amount) VALUES

(1, 1, 0.00, 12500.00),  

(2, 1, 0.00, 8900.00),   

(3, 1, 0.00, 10200.00),  

(4, 1, 0.00, 15000.00),  

(5, 1, 0.00, 7600.00);
-- 4
delimiter //

create procedure TransferSalaryAll()
begin
    declare emp_id_val int;
    declare emp_salary_val decimal(10,2);
    declare bank_status_val enum('ACTIVE', 'ERROR');
    declare total_balance decimal(15,2);
    declare done int default 0;
    declare error_message text;
    declare total_paid int default 0;
    declare bank_id_val int;

    declare emp_cursor cursor for
    select emp_id, salary from employees;

    declare continue handler for not found set done = 1;

    declare continue handler for sqlexception
    begin
        rollback;
        insert into transaction_log (log_message) values ('Lỗi trong quá trình trả lương');
    end;

    start transaction;

    select status into bank_status_val 
    from banks 
    where bank_id = (select bank_id from account limit 1);

    if bank_status_val = 'ERROR' then
    insert into transaction_log (log_message) 
    values ('Ngân hàng đang bị lỗi, không thể trả lương');
    rollback;
    set done = 1; -- Đánh dấu kết thúc
	end if;

    select balance into total_balance from company_funds limit 1;

    open emp_cursor;

    read_loop: loop
        fetch emp_cursor into emp_id_val, emp_salary_val;
        if done then
            leave read_loop;
        end if;

        select bank_id into bank_id_val 
        from account 
        where emp_id = emp_id_val;

        if bank_id_val is null then
            insert into transaction_log (log_message) 
            values (concat('Nhân viên không có tài khoản ngân hàng'));
            rollback;
            leave read_loop;
        end if;

        if total_balance < emp_salary_val then
            insert into transaction_log (log_message) 
            values ('Quỹ công ty không đủ tiền để trả lương');
            rollback;
            leave read_loop;
        end if;

        update company_funds 
        set balance = balance - emp_salary_val;

        insert into payroll (emp_id, salary, pay_date) 
        values (emp_id_val, emp_salary_val, curdate());

        update account 
        set amount_added = emp_salary_val, 
            total_amount = total_amount + emp_salary_val
        where emp_id = emp_id_val;

        set total_balance = total_balance - emp_salary_val;
        set total_paid = total_paid + 1;
    end loop;

    close emp_cursor;

    insert into transaction_log (log_message) 
    values (concat('Đã trả lương cho ', total_paid, ' nhân viên'));

    commit;
end //

delimiter ;

-- 5
call TransferSalaryAll();
-- 6
select * from company_funds;
select * from payroll;
select * from account;
select * from transaction_log;
