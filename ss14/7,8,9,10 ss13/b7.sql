-- 1
create database ss13;
use ss13;

CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY AUTO_INCREMENT,
    balance DECIMAL(15,2) NOT NULL -- Số dư quỹ công ty
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,   -- Tên nhân viên
    salary DECIMAL(10,2) NOT NULL    -- Lương nhân viên
);

CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,                      -- ID nhân viên (FK)
    salary DECIMAL(10,2) NOT NULL,   -- Lương được nhận
    pay_date DATE NOT NULL,          -- Ngày nhận lương
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);


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

-- 2
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

-- 4
alter table company_funds
add column bank_id int;

alter table company_funds
add foreign key(bank_id) references banks(bank_id);

-- 5
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;

INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2);

-- 6
delimiter //
	create trigger CheckBankStatus
    before 
    insert
    on payroll
    for each row
    begin
    if()
    end //
delimiter //










