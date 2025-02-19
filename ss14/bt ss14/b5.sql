CREATE DATABASE ss14_first;
USE ss14_first;
-- 1. Bảng customers (Khách hàng)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng orders (Đơn hàng)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- 3. Bảng products (Sản phẩm)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng order_items (Chi tiết đơn hàng)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 5. Bảng inventory (Kho hàng)
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- 6. Bảng payments (Thanh toán)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);


-- 2
delimiter //

create trigger before_insert_check_payment
before insert on payments
for each row
begin
    declare orderTotal decimal(10,2);

    select total_amount into orderTotal from orders where order_id = new.order_id;

    if new.amount < orderTotal then
        signal sqlstate '45000' 
        set message_text = 'số tiền thanh toán không khớp với tổng đơn hàng!';
    end if;
end //
delimiter ;

-- 3
CREATE TABLE order_logs (

    log_id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,

    old_status ENUM('Pending', 'Completed', 'Cancelled'),

    new_status ENUM('Pending', 'Completed', 'Cancelled'),

    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE

);

-- 4
delimiter //

create trigger after_update_order_status
after update on orders
for each row
begin
    if old.status <> new.status then
        insert into order_logs (order_id, old_status, new_status, log_date)
        values (new.order_id, old.status, new.status, now());
    end if;
end //
delimiter ;


-- 5
delimiter //

create procedure sp_update_order_status_with_payment(
    in orderId int,
    in newStatus enum('Pending', 'Completed', 'Cancelled'),
    in paymentAmount decimal(10,2),
    in paymentMethod enum('Credit Card', 'PayPal', 'Bank Transfer', 'Cash')
)
begin
    declare currentStatus enum('Pending', 'Completed', 'Cancelled');

    start transaction;

    select status into currentStatus from orders where order_id = orderId;

    if currentStatus = newStatus then
        signal sqlstate '45000' set message_text = 'đơn hàng đã có trạng thái này!';
        rollback;
    else
        if newStatus = 'Completed' then
            insert into payments (order_id, payment_date, amount, payment_method, status)
            values (orderId, now(), paymentAmount, paymentMethod, 'Completed');
        end if;
        update orders set status = newStatus where order_id = orderId;
        commit;
    end if;
end //
delimiter ;

-- 6
insert into customers (name, email, phone, address) 
values ('Nguyen Van A', 'a@example.com', '0123456789', 'Hanoi');

insert into products (name, price, description) 
values ('Laptop', 1500.00, 'Laptop cao cấp'), 
       ('Phone', 800.00, 'Điện thoại thông minh');

insert into orders (customer_id, total_amount, status) 
values (1, 2300.00, 'Pending');

insert into order_items (order_id, product_id, quantity, price) 
values (1, 1, 1, 1500.00), 
       (1, 2, 1, 800.00);

call sp_update_order_status_with_payment(1, 'Completed', 2300.00, 'Credit Card');

-- 7
select * from order_logs;

-- 8
drop trigger  before_insert_check_payment;
drop trigger after_update_order_status;
drop procedure sp_update_order_status_with_payment;
