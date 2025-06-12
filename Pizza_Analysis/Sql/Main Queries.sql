show databases;
use pizzas_project;
show tables;

select * from orders limit 3;
select count(*) from orders;
select * from orders where order_id is null or date is null 
or time is null;

select * from order_details limit 3;
select count(*) from order_details;
select * from order_details where order_details_id is null
or order_id is null or pizza_id is null or quantity is null;

select * from pizza_types limit 3;
select count(*) from pizza_types;
select * from pizza_types where pizza_type_id is null or name 
is null or category is null or ingredients is null;

select * from pizzas limit 3;
select count(*) from pizzas;
select * from pizzas where pizza_id is null or pizza_type_id 
is null or size is null or price is null;

-- Beginner Level 
-- 1. Show all pizzas with their sizes and prices
select * from pizzas;

-- 2. List all unique pizza categories.
select distinct category from pizza_types;

-- 3. Find all pizzas with price greater than $ 20
select * from pizzas where price > 20;

-- 4. List all pizzas of size 'L'
select * from pizzas where size = 'L';

-- 5. Sort the pizza types by name alphabetically
select * from pizza_types order by name;


-- Intermediate Level
--  6. Show each pizza with its name, category, ingredients, size and price
SELECT pt.name, pt.category, pt.ingredients, p.size, p.price 
FROM pizza_types AS pt INNER JOIN pizzas AS p 
ON p.pizza_type_id = pt.pizza_type_id;

-- 7. Show pizza name, size, quantity and price in one table
select pt.name, size, quantity, price from pizza_types as pt inner join
(select p.pizza_type_id, p.size, od.quantity, p.price 
from order_details as od inner join pizzas as p 
on od.pizza_id = p.pizza_id) as d
on pt.pizza_type_id = d.pizza_type_id;

--                     OR

SELECT pt.name, p.size, od.quantity, p.price as Price 
FROM order_details AS od INNER JOIN pizzas AS p 
ON od.pizza_id = p.pizza_id INNER JOIN 
pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id;

-- 7.1 How many pizzas of each type were ordered (total quantity)
SELECT pt.name as Name, sum(od.quantity) as Total_Qty FROM 
order_details AS od INNER JOIN pizzas AS p 
ON od.pizza_id = p.pizza_id INNER JOIN 
pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id 
group by pt.name order by Total_Qty desc;

-- 8. What is the most frequently ordered pizza?
SELECT pt.name as Pizza_Name, sum(od.quantity) as Total_Qty FROM 
order_details AS od INNER JOIN pizzas AS p 
ON od.pizza_id = p.pizza_id INNER JOIN 
pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id 
group by pt.name order by Total_Qty desc limit 3;

-- 9. Find the total revenue (price * quantity) for each pizza type.
select pt.name as Pizza_Name, sum(rev.price * rev.quantity) as Total_Revenue 
from pizza_types as pt inner join
(select p.pizza_type_id, p.price, od.quantity from pizzas as p 
inner join order_details as od on p.pizza_id = od.pizza_id) as rev
on pt.pizza_type_id = rev.pizza_type_id
group by pt.name order by Total_Revenue desc;

-- 10. Find the total number of orders placed each day.
SELECT date as Date, COUNT(order_id) AS Total_Orders
FROM orders GROUP BY date ORDER BY date;

-- Advanced Level
-- 11. Which day had the highest total sales revenue?
select struc.date as Date, round(sum(struc.quantity * struc.price),2)
as Total_Revenue from
(select o.date, od.quantity, p.price from orders as o inner join
order_details as od on o.order_id = od.order_id inner join
pizzas as p on od.pizza_id = p.pizza_id) as struc
group by Date order by Total_Revenue desc;

-- 12. Find the top 2 most popular pizza categories by quantity sold.
select pt.category as Category, sum(od.quantity) Total_Qty 
from pizza_types as pt inner join pizzas as p on
pt.pizza_type_id = p.pizza_type_id inner join order_details as od
on p.pizza_id = od.pizza_id group by Category 
order by Total_Qty desc limit 2;

-- 13. Find the average number of pizzas ordered per order.
select round(avg(Total_Qty),2) as avg_pizzas_per_order from 
(select order_id, sum(quantity) as Total_Qty from order_details
group by order_id) as sub;

-- 14. For each pizza, calculate its percentage share in total revenue.
select Name, Total_Revenue, round((Total_Revenue/Total_Sum)* 100, 2)
as Revenue_Percentage from
(select pt.name as Name, sum(od.quantity*p.price) as Total_Revenue 
from pizza_types as pt inner join pizzas as p 
on pt.pizza_type_id = p.pizza_type_id 
inner join order_details as od on p.pizza_id = od.pizza_id
group by Name) as tab,
(select sum(od.quantity*p.price) as Total_Sum from pizzas as p
inner join order_details as od on p.pizza_id = od.pizza_id) as total
order by Revenue_Percentage desc;

-- 15. Rank pizzas by total revenue within each category.
select pt.category as Category, pt.name as Pizza_Name, 
round(sum(p.price * od.quantity),2) as Total_Rev, 
rank()over(partition by Category order by 
sum(p.price * od.quantity) desc) as Ranking from pizza_types as pt 
inner join pizzas as p on pt.pizza_type_id = p.pizza_type_id 
inner join order_details as od on p.pizza_id = od.pizza_id 
group by Category, Pizza_Name order by Category, Ranking;


-- 16. Find the top-selling pizza size overall.
select p.size as Pizza_Size, sum(od.quantity) as Total_Qty from pizzas as p 
inner join order_details as od on p.pizza_id = od.pizza_id
group by Pizza_Size order by Total_Qty desc limit 1;

-- 17. Which orders had more than 10 pizzas in total and their date?
select od.order_id as Order_ID, o.date as Date, 
sum(od.quantity) as Qty from order_details as od 
inner join orders as o on od.order_id = o.order_id group by 
order_id, o.date having Qty > 10 order by Qty desc;

-- 18. Find all orders that included a ‘BBQ Chicken’ pizza.
select distinct o.order_id, o.date, o.time from orders as o 
inner join order_details as od on o.order_id = od.order_id 
inner join pizzas as p on od.pizza_id = p.pizza_id 
inner join pizza_types as pt on 
p.pizza_type_id = pt.pizza_type_id where pt.name 
like '%Barbecue Chicken%';

-- 19. Compare average price of pizzas in each category.
select pt.category as Category, round(avg(p.price), 2) 
as Avg_Price from pizza_types as pt inner join pizzas as p 
on pt.pizza_type_id = p.pizza_type_id group by Category
order by Avg_Price desc;

-- 20. Find which pizza size generates the most revenue.
select p.size as Pizza_Size, 
round(sum(p.price * od.quantity), 2) as Total_Revenue 
from pizzas as p inner join order_details as od on p.pizza_id = od.pizza_id
group by Pizza_Size order by Total_Revenue desc limit 1;

-- 21. Create a view showing daily revenue trends.
create view daily_revenue_trend as 
select o.date as Date, round(sum(od.quantity * p.price), 2) 
as Total_Revenue from orders as o inner join 
order_details as od on o.order_id = od.order_id inner join
pizzas as p on p.pizza_id = od.pizza_id group by Date
order by Date;
SELECT * FROM daily_revenue_trend;

-- 22. Generate a report showing top 3 pizzas by revenue 
--     for each category.
select * from
(select pt.name as Pizza_Name, pt.category as Pizza_Category,
round(sum(p.price * od.quantity),2) as Total_Rev,
rank() over (partition by pt.category 
order by sum(p.price * od.quantity) desc) as Ranking 
from pizza_types as pt inner join pizzas as p on
pt.pizza_type_id = p.pizza_type_id inner join 
order_details as od on p.pizza_id = od.pizza_id group by 
Pizza_Name, Pizza_Category) as ranked_pizzas
where Ranking <= 3 order by Pizza_Category, Ranking;

-- Advanced + Complex Level
-- 23. Daily Category Revenue Breakdown
-- For each date, show the total revenue per pizza category, 
-- sorted by highest revenue first per day.
select o.date, pt.category, sum(p.price * od.quantity) as Revenue
from orders as o join order_details as od on 
o.order_id = od.order_id join pizzas as p on od.pizza_id = p.pizza_id
join pizza_types as pt on p.pizza_type_id = pt.pizza_type_id
group by o.date, pt.category order by o.date, pt.category;

-- 24. Best-Selling Pizza Each Day
-- For each day, find the pizza that generated the highest revenue.
select * from
(select o.date as Date, pt.name as 'Pizza Name',
round(sum(p.price * od.quantity), 2) as Revenue,
dense_rank() over (partition by 
o.date order by sum(p.price * od.quantity) desc) 
as Ranking from orders as o join order_details as od 
on o.order_id = od.order_id join pizzas as p on 
od.pizza_id = p.pizza_id join pizza_types as pt on 
p.pizza_type_id = pt.pizza_type_id group by o.date, pt.name) as ranked
where Ranking = 1 order by Date;

-- 25. Pizza Popularity Over Time
-- Find the monthly trend of total quantity sold for each pizza category.
select date_format(o.date, '%Y-%m') as Month, 
pt.category as 'Pizza Category', sum(od.quantity) as Total_Qty 
from orders as o join order_details as od on 
o.order_id = od.order_id join pizzas as p on od.pizza_id = p.pizza_id
join pizza_types as pt on p.pizza_type_id = pt.pizza_type_id
group by Month, pt.category order by Month, pt.category;


-- 26. High Revenue Orders
-- List all orders where the total value exceeded $260. 
-- Show the order_id, date, and total_order_value.
select o.order_id as 'Order ID', o.date as Date, 
round(sum(od.quantity * p.price), 2) as Revenue from orders as o
join order_details as od on o.order_id = od.order_id join 
pizzas as p on od.pizza_id = p.pizza_id group by o.order_id,
o.date having Revenue > 260 order by o.date, Revenue;

-- 27. Percentage Share of Each Pizza in its Category (Revenue-wise)
-- For each pizza, show what % of its category’s total revenue 
-- it contributed.
SELECT pt.category AS Pizza_Category, pt.name AS Pizza_Name,
ROUND(SUM(od.quantity * p.price), 2) AS Pizza_Revenue,
ROUND(SUM(od.quantity * p.price) * 100.0 / 
SUM(SUM(od.quantity * p.price)) OVER (PARTITION BY pt.category),2)
AS Revenue_Percentage FROM pizza_types pt JOIN pizzas p 
ON pt.pizza_type_id = p.pizza_type_id JOIN order_details od 
ON p.pizza_id = od.pizza_id GROUP BY pt.category, pt.name
ORDER BY pt.category, Revenue_Percentage DESC;

-- 28. Time Slot Analysis
-- Categorize orders into time slots: Morning (6 AM–12 PM),
-- Afternoon (12 PM–6 PM), Evening (6 PM–12 AM), 
-- Night (12 AM–6 AM). Then count how many orders 
-- were placed in each slot.
DELIMITER $$
create function time_slots(slots time)
returns varchar(40) 
DETERMINISTIC
BEGIN
	DECLARE hr INT;
    Set hr  = HOUR(slots);
	IF hr >= 6 and hr < 12 then 
    return "Morning (6 AM–12 PM)"; 
    ELSEIF hr >= 12 and hr < 18 then
    return "Afternoon (12 PM–6 PM)";
    ELSEIF hr >= 18 and hr < 24 then
    return "Evening (6 PM–12 AM)";
	ELSE
    return "Night (12 AM–6 AM)";
END IF;
END $$
DELIMITER ;
select time_slots(o.time) as Time_Slot, count(order_id) as Total_Orders
from orders as o group by Time_Slot order by Time_Slot;

--                               OR

select case 
when HOUR(time) >= 6 and HOUR(time) < 12 then 'Morning (6 AM–12 PM)'
when HOUR(time) >= 12 and HOUR(time) < 18 then 'Afternoon (12 PM–6 PM)'
when HOUR(time) >= 18 and HOUR(time) < 24 then 'Evening (6 PM–12 AM)'
else 'Night (12 AM–6 AM)'
END AS Time_Slot,
COUNT(*) AS Total_Orders FROM orders GROUP BY Time_Slot
ORDER BY FIELD(Time_Slot, 
  'Morning (6 AM–12 PM)', 
  'Afternoon (12 PM–6 PM)', 
  'Evening (6 PM–12 AM)', 
  'Night (12 AM–6 AM)'
);

-- 29. Multi-Size Pizza Comparison
-- For each pizza type, show how its revenue is split 
-- across different sizes.
select pt.pizza_type_id, p.size, 
round(sum(od.quantity * p.price), 2) as Revenue,
rank() over (partition by pt.pizza_type_id 
order by sum(od.quantity * p.price) desc) as Ranking
from pizza_types as pt join pizzas as p on 
pt.pizza_type_id = p.pizza_type_id join order_details as od 
on p.pizza_id = od.pizza_id group by pt.pizza_type_id, 
p.size order by pt.pizza_type_id, Ranking;

-- 30. Cumulative Revenue by Day
-- For each day, compute the cumulative revenue up to that date.
select o.date, round(sum(od.quantity *  p.price), 2) as Daily_Rev,
round(sum(sum(od.quantity *  p.price)) over 
(order by o.date), 2) as Cumm_Rev
from orders as o join order_details as od on o.order_id = od.order_id
join pizzas as p on od.pizza_id = p.pizza_id
group by o.date order by o.date;

-- 31. Repeat Pizza Orders (Same Pizza in Same Order Multiple Times
-- Find all orders where the same pizza was ordered more 
-- than once.
select order_id, pizza_id, sum(quantity) as Total_Qty from
order_details group by order_id, pizza_id having Total_Qty > 1
order by order_id;

-- 32. Create a View for Daily Pizza Sales
-- A view that returns date, pizza name, and quantity sold.
create view daily_pizza_sales as
select o.date, pt.name, sum(od.quantity) as Total_Qty 
from orders as o join order_details as od on 
o.order_id = od.order_id join pizzas as p on 
od.pizza_id = p.pizza_id join pizza_types as pt on 
p.pizza_type_id = pt.pizza_type_id group by o.date, pt.name
order by o.date, Total_Qty desc;
select * from daily_pizza_sales;

-- 33. Find Orders That Include Both Veg and Non-Veg Pizzas
-- For each order, check if it includes both veg and 
-- non-veg pizzas.
select od.order_id from order_details as od join pizzas as p 
on od.pizza_id = p.pizza_id join pizza_types as pt on 
p.pizza_type_id = pt.pizza_type_id group by od.order_id 
having sum(pt.category = 'Veggie') > 0 and 
sum(pt.category in ('Chicken', 'Classic', 'Supreme')) > 0
order by order_id;

select od.order_id, pt.name, pt.category AS pizza_category, 
pt.ingredients from order_details as od join pizzas as p 
on od.pizza_id = p.pizza_id join pizza_types as pt on
p.pizza_type_id = pt.pizza_type_id where od.order_id in (
select od.order_id from order_details as od join pizzas as p 
on od.pizza_id = p.pizza_id join pizza_types as pt on 
p.pizza_type_id = pt.pizza_type_id group by od.order_id
having sum(pt.category = 'Veggie') > 0 and
sum(pt.category in ('Chicken', 'Classic', 'Supreme')) > 0)
ORDER BY od.order_id, pt.name;




