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
create procedure sp_createOrder(
    in customerId int,
    in productId int,
    in quantity int,
    in price decimal(10,2)
)
begin
    declare stockQuantity int;
    declare orderId int;
    
    start transaction;
    
    select stock_quantity into stockQuantity 
    from inventory where product_id = productId;
    
    if stockQuantity < quantity then
        rollback;
        signal sqlstate '45000' set message_text = 'Không đủ hàng trong kho!';
    else

        insert into orders (customer_id, order_date, total_amount, status) 
        values (customerId, now(), 0, 'Pending');
        
        set orderId = last_insert_id();

        insert into order_items (order_id, product_id, quantity, price) 
        values (orderId, productId, quantity, price);

        update orders 
        set total_amount = quantity * price 
        where order_id = orderId;

        update inventory 
        set stock_quantity = stock_quantity - quantity 
        where product_id = productId;
        commit;
    end if;
end //
delimiter ;

-- 3
delimiter //
create procedure sp_paymentOrder(
    in orderId int,
    in paymentMethod varchar(20)
)
begin
    declare orderStatus varchar(20);
    declare totalAmount decimal(10,2);
    
    start transaction;
    select status, total_amount into orderStatus, totalAmount
    from orders where order_id = orderId;
    
    if orderStatus <> 'Pending' then
        rollback;
        signal sqlstate '45000' 
        set message_text = 'Chỉ thanh toán đơn hàng ở trạng thái Pending!';
    else

        insert into payments (order_id, payment_date, amount, payment_method, status) 
        values (orderId, now(), totalAmount, paymentMethod, 'Completed');
        update orders 
        set status = 'Completed' 
        where order_id = orderId;
        commit;
    end if;
end //
delimiter ;

call sp_paymentOrder(1,'Credit Card')
-- 4
delimiter //
create procedure sp_cancelOrder(
    in orderId int
)
begin
    declare orderStatus varchar(20);
    
    start transaction;
    select status into orderStatus 
    from orders where order_id = orderId;
    if orderStatus <> 'Pending' then
        rollback;
        signal sqlstate '45000' set message_text = 'Chỉ có thể hủy đơn hàng ở trạng thái Pending!';
    else
        update inventory i
        join order_items oi on i.product_id = oi.product_id
        set i.stock_quantity = i.stock_quantity + oi.quantity
        where oi.order_id = orderId;

        delete from order_items where order_id = orderId;
        update orders 
        set status = 'Cancelled' 
        where order_id = orderId;
        commit;
    end if;
end //
delimiter ;

call sp_cancelOrder(1);
-- 5

drop procedure sp_createOrder;
drop procedure sp_paymentOrder;
drop procedure sp_cancelOrder;
