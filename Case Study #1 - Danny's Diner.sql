create database dany;
use dany;
------
-- Case Study #1 - Danny's Diner
CREATE TABLE sales (customer_id VARCHAR(1),order_date DATE,product_id INTEGER);
INSERT INTO sales VALUES
  ('A', '2021-01-01', '1'),('A', '2021-01-01', '2'),('A', '2021-01-07', '2'),('A', '2021-01-10', '3'),('A', '2021-01-11', '3'),('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),('B', '2021-01-02', '2'),('B', '2021-01-04', '1'),('B', '2021-01-11', '1'),('B', '2021-01-16', '3'),('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),('C', '2021-01-01', '3'),('C', '2021-01-07', '3');
--------
CREATE TABLE menu (product_id INTEGER,product_name VARCHAR(5),price INTEGER);
INSERT INTO menu VALUES('1', 'sushi', '10'),('2', 'curry', '15'),('3', 'ramen', '12');
--------
CREATE TABLE members (customer_id VARCHAR(1),join_date DATE);
INSERT INTO members VALUES('A', '2021-01-07'),('B', '2021-01-09');
-------
-- 1. What is the total amount each customer spent at the restaurant?

select customer_id,sum(price)price from sales join menu using(product_id) group by (1);

-- 2. How many days has each customer visited the restaurant?

select customer_id,count(distinct(order_date))days from sales group by (1);

-- 3. What was the first item from the menu purchased by each customer?

with sub as (select distinct(customer_id),product_id,order_date from sales 
where order_date in(select min(order_date)from sales group by customer_id) 
order by order_date)
select distinct(customer_id),product_name from sub join menu using(product_id);

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name,count(product_id)frequency from menu join sales using(product_id) group by (1) order by (2) desc limit 1;

-- 5. Which item was the most popular for each customer?
        
WITH rk as (select customer_id,product_id,count(product_id)total_order,rank()over(partition by customer_id order by count(product_id)desc)as ranks
from sales group by (1),(2))
select r.customer_id,m.product_name,total_order from rk r join menu m using(product_id) where r.ranks=1 order by r.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

with a as(select customer_id,product_name,order_date,dense_rank() over(partition by customer_id order by order_date)as dates 
from sales join menu m using(product_id)
where order_date >any(select order_date from sales join 
members on sales.order_date=members.join_date))
select * from a where dates=1;

-- 7. Which item was purchased just before the customer became a member?

with a as(select mb.customer_id customer_id,m.product_name product,order_date,dense_rank() over(partition by mb.customer_id order by order_date desc)as dates 
from members mb join  sales s on mb.customer_id=s.customer_id
join menu m on m.product_id=s.product_id
where s.order_date < mb.join_date)
select customer_id,product,order_date from a where dates=1;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,count(s.product_id)total_items,sum(m.price)amount from sales s join menu m on s.product_id=m.product_id 
join members mb on mb.customer_id=s.customer_id
where s.order_date<mb.join_date
group by (1) order by (1) ;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id,sum(case when product_name like 'sus%' then price*20 else price*10 end )as points
from sales join menu using(product_id) group by (1);

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
select s.customer_id, sum(case when m.product_name like 's%' then 0 else 2*10 end) as pts
from sales s join members b on s.customer_id=b.customer_id
join menu m on m.product_id=s.product_id
where order_date>join_date group by (1);
--

select * from sales;
select * from menu;
select * from members;
-----
