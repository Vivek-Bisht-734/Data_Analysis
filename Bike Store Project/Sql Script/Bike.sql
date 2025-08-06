-- Dataset from Kaggle = https://www.kaggle.com/datasets/dillonmyrick/bike-store-sample-database?select=stores.csv

create database bike_store_project;
use bike_store_project;



select * from brands;
describe brands;
select * from brands where brand_id is null or brand_name is null;
select distinct brand_name from brands;


select * from categories;
describe categories;
select * from categories where category_id is null or category_name;
select distinct category_name from categories;


select * from customers;
describe customers;
select * from customers where customer_id is null or first_name is null or last_name is null or phone is null or email is null or street is null or city is null or state is null or zip_code;
alter table customers add column full_name varchar(50);
set sql_safe_updates = 0;
update customers set full_name = concat_ws(' ', first_name, last_name);
alter table customers drop column phone, drop column email, drop column street, 
drop column first_name, drop column last_name;
select distinct state from customers;


select * from order_items;
describe order_items;
select * from order_items where order_id is null or item_id is null or product_id is null or quantity is null or list_price is null or discount;


select * from orders;
describe orders;                          -- In col order_status =   1: Pending, 2: Processing, 3: Rejected, 4: Completed
select * from orders where order_id is null or customer_id is null or order_status is null or order_date is null or required_date is null or shipped_date is null or store_id is null or staff_id;
select distinct order_status from orders;


select * from products;
describe products;
select * from products where product_id is null or product_name is null or brand_id is null or category_id is null or model_year is null or list_price;
select distinct product_name from products;
select distinct model_year from products;


select * from staffs;
describe staffs;
select * from staffs where staff_id is null or first_name is null or last_name is null or email is null or phone is null or `active` is null or store_id is null or manager_id;
alter table staffs modify column manger_id int;
alter table staffs add column full_name varchar(50);
set sql_safe_updates = 0;
update staffs set full_name = concat_ws(' ', first_name, last_name);
alter table staffs drop column first_name, drop column last_name, 
drop column phone, drop column email;
select distinct manager_id from staffs;


select * from stocks;
describe stocks;
select * from stocks where store_id is null or product_id is null or quantity;
select distinct store_id from stocks;


select * from stores;
describe stores;
select * from stores where store_id is null or store_name is null or phone is null or email is null or street is null or city is null or state is null or zip_code;
alter table stores drop column phone, drop column email, drop column street;
select distinct store_name from stores;



-- I. Change Over Time Trends = Analyzing how a measure evolves over time. It helps track trends and identify seasonality in our data.
-- 1. Calculate total sales revenue by year from orders and order_items.
with revenue as (select o.order_date, oi.quantity, oi.list_price, 
oi.discount from orders o join order_items oi on 
o.order_id = oi.order_id)
select year(order_date) as `Order Year`, 
round(sum(quantity * (list_price - (list_price * discount))), 2) 
as Revenue from revenue group by `Order Year` order by `Order Year`;


-- 2. Find the average discount offered per month and observe how it changes over time.
with req_cols as (
select o.order_date, oi.discount from orders o join order_items oi on o.order_id = oi.order_id)
select year(order_date) as `Order Year`, month(order_date) as `Order Month`, round(avg(discount * 100), 2)
as Avg_Discount_Percentage from req_cols
group by `Order Year`, `Order Month` order by `Order Year`, `Order Month`;


-- 3. Track order volume per quarter for each store.
with req_tables as (
select o.order_date, s.store_name, oi.quantity from order_items oi join 
orders o on oi.order_id = o.order_id join stores s on s.store_id = o.store_id)
select year(order_date) as `Order Year`, quarter(order_date) as `Quarter`, 
store_name as `Store Name`, sum(quantity) as Volume from req_tables 
group by `Order Year`, `Quarter`, `Store Name` order by `Order Year`, `Quarter`;


-- 4. Show sales trends by brand over the years.
with req_cols as (
select o.order_date, b.brand_name, oi.quantity, oi.list_price, oi.discount
from orders o join order_items oi on o.order_id = oi.order_id join products p 
on oi.product_id = p.product_id join brands b on p.brand_id = b.brand_id)
select year(order_date) as `Order Year`, brand_name as `Brand Name`, 
round(sum(quantity * (list_price - (list_price * discount))), 2) as Sales from
req_cols group by `Order Year`, `Brand Name` order by `Order Year`, `Brand Name`;


-- 5. Identify seasonal peaks in sales by comparing monthly totals year-over-year.
with req_cols as (
select o.order_date, oi.quantity, oi.list_price, oi.discount 
from orders o join order_items oi on o.order_id = oi.order_id),
seasonal_rev as (
select year(order_date) as `Order Year`, 
case when month(order_date) in (3,4,5) then 'Spring'
when month(order_date) in (6,7,8) then 'Summer'
when month(order_date) in (9,10,11) then 'Autumn'
else 'Winter' end as Seasonality, 
round(sum(quantity * (list_price - (list_price * discount))), 2) as Revenue
from req_cols group by `Order Year`, Seasonality),
with_lags as(
select `Order Year`, Seasonality, Revenue, lag(Revenue) over(partition by
Seasonality order by `Order Year`) as `Previous Year Recenue`
from seasonal_rev)
select `Order Year`, Seasonality, Revenue, `Previous Year Recenue`,
round(Revenue - `Previous Year Recenue`) as Comparison,
case when `Previous Year Recenue` is null then null
else round((Revenue - `Previous Year Recenue`) / `Previous Year Recenue` * 100, 2)
end as `%age_change` from with_lags order by Seasonality, `Order Year`;




-- II. Cumulative Analysis = Aggregating data progressively over time. Help to understand how our business is performing over the time i.e. whether it is growing or declining
-- 1. Compute running total sales per month across all stores.
with req_cols as (
select o.order_date, oi.quantity, oi.list_price, oi.discount, s.store_name 
from orders o join order_items oi on o.order_id = oi.order_id join stores s
on o.store_id = s.store_id),
revenue as (select store_name as `Store Name`, year(order_date) as `Order Year`, 
month(order_date) `Order Month`, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as `Monthly Revenue` from req_cols group by `Store Name`, `Order Year`, `Order Month`)
select `Store Name`, concat(`Order Year`, '-', RIGHT(CONCAT('0', `Order Month`), 2))
as `Year-Month`, `Monthly Revenue`, 
round(sum(`Monthly Revenue`) over (partition by `Store Name`
order by `Order Year`, `Order Month` 
rows between unbounded preceding and current row), 2) as `Running Sales`
from revenue order by `Store Name`, `Order Year`, `Order Month`;


-- 2. Track cumulative number of products sold by category.
with req_cols as (
select c.category_name, oi.quantity, oi.list_price, oi.discount, 
o.order_date from categories c join products p on c.category_id = p.category_id 
join order_items oi on p.product_id = oi.product_id
join orders o on oi.order_id = o.order_id),
revenue as (
select year(order_date) as `Order Year`, month(order_date) as `Order Month`, 
category_name, sum(quantity) as `Total Products Sold`, 
round(sum(quantity * (list_price - (list_price * discount))), 2) as Sales 
from req_cols group by `Order Year`, `Order Month`, category_name),
cumulative_qty as (
select concat(`Order Year`, ' - ', right(concat('0', `Order Month`), 2)) as `Year-Month`
, category_name, `Total Products Sold`, sum(`Total Products Sold`) over(partition by 
category_name order by `Order Year`, `Order Month` rows between unbounded preceding 
and current row) as `Running Product Count`, Sales, round(sum(Sales) 
over(partition by category_name order by `Order Year`, `Order Month` 
rows between unbounded preceding and current row), 2) as `Running Total Sales` 
from revenue)
select * from cumulative_qty order by category_name, `Year-Month`;


-- 3. Show cumulative revenue per brand over the years.
with req_cols as (
select b.brand_name, oi.quantity, oi.list_price, oi.discount, 
o.order_date from order_items oi join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id join brands b on 
p.brand_id = b.brand_id),
revenue as (
select year(order_date) as `Order Year`, brand_name, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Revenue from req_cols group by `Order Year`, brand_name)
select `Order Year`, brand_name as `Brand Name`, Revenue, round(sum(Revenue) 
over(partition by brand_name rows between unbounded preceding and current row), 2) 
as `Cumulative Revenue` from revenue order by `Brand Name`, `Order Year`;


-- 4. Calculate cumulative number of customers who have placed orders.
with req_cols as (
select c.customer_id, o.order_id, o.order_date from customers c
join orders o on c.customer_id = o.customer_id),
group_cx as (
select year(order_date) as `Order Year`, month(order_date) as `Order Month`,
customer_id from req_cols group by `Order Year`, `Order month`, customer_id),
new_cx as (
select `Order Year`, `Order Month`, count(distinct customer_id) as `New Cx`
from group_cx group by `Order Year`, `Order Month`)
select concat(`Order Year`, ' - ', right(concat('0', `Order month`), 2)) 
as `Year-Month`, `New Cx`, sum(`New Cx`) over(order by `Order Year`, `Order Month`
rows between unbounded preceding and current row) as `Cumulative Cx`
from new_cx order by `Year-Month`;


-- 5. Find the cumulative average order value over time.
with req_cols as (
select oi.quantity, oi.list_price, oi.discount,
o.order_id, o.order_date from orders o join order_items oi
on o.order_id = oi.order_id),
order_details as (
select year(order_date) as `Order Year`, month(order_date) as `Order Month`,
count(distinct order_id) as `Total Orders`, 
round(sum(quantity * (list_price - (list_price * discount))), 2) 
as `Total Order Value` from req_cols group by `Order Year`, `Order Month`),
avg_order_cte as (
select concat(`Order Year`, ' - ', right(concat('0', `Order Month`), 2)) as 
`Year-Month`, `Total Orders`, `Total Order Value`, 
round(`Total Order Value` / `Total Orders`, 2) as `Avg Order Value` from
order_details)
select `Year-Month`, `Avg Order Value`, round(avg(`Avg Order Value`)
over(order by `Year-Month` rows between unbounded preceding and current row), 2) 
as `Cumulative Average of 'Avg Order Value'`, round(sum(`Avg Order Value`)
over(order by `Year-Month` rows between unbounded preceding and current row), 2) 
as `Cumulative Order Value` from avg_order_cte order by `Year-Month`;



-- III. Performance Analysis = Comparing the current value with the targeted value. Helps to measure the success and to compare the performance.
-- 1. Compare current year’s sales to previous year’s sales for each store.
with req_cols as (
select o.order_date, oi.quantity, oi.list_price, oi.discount,
s.store_name 
from orders o join order_items oi on o.order_id = oi.order_id
join stores s on o.store_id = s.store_id),
revenue_cte as (
select year(order_date) as `Order Year`, store_name,
round(sum(quantity * (list_price - (list_price * discount))), 2) as Revenue
from req_cols group by `Order Year`, store_name),
with_lags as(
select `Order Year`, store_name, Revenue, lag(Revenue) over(
partition by store_name order by `Order Year`) 
as `Previous Year Revenue` from revenue_cte)
select `Order Year`, store_name as `Store Name`, Revenue, `Previous Year Revenue`,
round(Revenue - `Previous Year Revenue`) as Comparison,
case when `Previous Year Revenue` is null then null
else round((Revenue - `Previous Year Revenue`) / `Previous Year Revenue` * 100, 2)
end as `%age_change` from with_lags order by `Store Name`, `Order Year`;

-- 2. Compare each brand’s sales with the average brand sales.
with req_cols as (
select b.brand_name, oi.quantity, oi.list_price, oi.discount, 
o.order_date from order_items oi join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id join brands b on 
p.brand_id = b.brand_id),
order_details as (
select year(order_date) as `Order Year`, brand_name, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Sales from req_cols group by `Order Year`, brand_name),
avg_sales_cte as (
select `Order Year`, brand_name, Sales, 
round(avg(Sales) over(partition by `Order Year`) , 2) as `Avg Brand Sales` 
from order_details)
select `Order Year`, brand_name as `Brand Name`, Sales, `Avg Brand Sales`,
round(Sales - `Avg Brand Sales`, 2) as `Comparison` from avg_sales_cte 
order by `Brand Name`, `Order Year`;


-- 3. Identify products whose current year sales exceeded their all-time average sales.
with req_cols as (
select p.product_name, oi.quantity, oi.list_price, oi.discount, 
o.order_date from order_items oi join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id),
revenue as (
select year(order_date) as `Order Year`, product_name, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Sales from req_cols group by `Order Year`, product_name),
avg_sales_cte as (
select `Order Year`, product_name, Sales, 
round(avg(Sales) over(partition by product_name) , 2) as `Avg Product Sales` from revenue),
current_yr_cte as (
select max(`Order Year`) as `Current Yr` from revenue)  -- Current Year is 2018 in the dataset
select a.`Order Year`, a.product_name as `Product Name`, a.Sales, a.`Avg Product Sales`,
round(Sales - `Avg Product Sales`, 2) as `Comparison`
from avg_sales_cte a join current_yr_cte c on a.`Order Year` = c.`Current Yr`
where a.Sales > a.`Avg Product Sales` order by `Product Name`; 


		-- products whose sales exceeded their average sales and are giving profits.
with req_cols as (
select p.product_name, oi.quantity, oi.list_price, oi.discount, 
o.order_date from order_items oi join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id),
revenue as (
select year(order_date) as `Order Year`, product_name, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Sales from req_cols group by `Order Year`, product_name),
avg_sales_cte as (
select `Order Year`, product_name, Sales, 
round(avg(Sales) over(partition by product_name) , 2) as `Avg Product Sales` from revenue),
comparison_cte as (
select `Order Year`, product_name as `Product Name`, Sales, `Avg Product Sales`,
round(Sales - `Avg Product Sales`, 2) as Comparison
from avg_sales_cte)
select * from comparison_cte where Comparison > 0 order by `Product Name`, `Order Year`; 


-- 4. Compare sales performance of each staff member to the top performer in the store.
with req_cols as (
select sta.full_name, sto.store_name, oi.quantity, oi.list_price, oi.discount, 
o.order_date from order_items oi join orders o on oi.order_id = o.order_id
join staffs sta on o.staff_id = sta.staff_id join stores sto on 
o.store_id = sto.store_id),
agg as(
select year(order_date) as `Year`, full_name, store_name, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Sales from req_cols group by `Year`, full_name, store_name),
top_sales as (
select `Year`, full_name as `Name`, store_name as `Store Name`, Sales, max(sales) 
over(partition by store_name, `Year`) as `Top Performer Sales` from agg)
select *, round(Sales - `Top Performer Sales`, 2) as Comparison 
from top_sales order by `Store Name`, `Year`, Comparison desc;

                       -- overall sales performance and their comparisons with top-performers
with req_cols as (
select sta.full_name, sto.store_name, oi.quantity, oi.list_price, oi.discount
from order_items oi join orders o on oi.order_id = o.order_id
join staffs sta on o.staff_id = sta.staff_id join stores sto on 
o.store_id = sto.store_id),
agg as(
select full_name, store_name, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Sales from req_cols group by full_name, store_name),
top_sales as (
select full_name as `Name`, store_name as `Store Name`, Sales, max(sales) over(partition by store_name)
as `Top Performer Sales` from agg)
select *, round(Sales - `Top Performer Sales`, 2) as Comparison 
from top_sales order by `Store Name`, Comparison desc;



-- IV. Part-to-Whole / Propotional Analysis = Analyze how an individual part is performing compared to the overall, 
-- allowsing us to understand which category has the greatest impact on the business.
-- 1. Calculate % contribution of each category to total sales.
with req_cols as (
select c.category_name, oi.quantity, oi.list_price, oi.discount
from order_items oi join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id join categories c on
p.category_id = c.category_id),
agg as (
select category_name, round(sum(quantity * (list_price - (list_price * discount))), 2)
as `Total Sales` from req_cols group by category_name)
select category_name as `Category Name`, `Total Sales`, round(sum(`Total Sales`) 
over(), 2) as `Overall Sales`, concat(round(`Total Sales` * 100 / sum(`Total Sales`) 
over(), 2), '%') as Percentage from agg order by `Category Name`, `Total Sales`;


-- 2. Find store-wise share of total company revenue.
with req_cols as (
select s.store_name, oi.quantity, oi.list_price, oi.discount
from order_items oi join orders o on oi.order_id = o.order_id
join stores s on o.store_id = s.store_id),
agg as (
select store_name as `Store Name`, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Revenue from req_cols group by store_name) 
select *, round(sum(Revenue) over(), 2) as `Total Revenue`, 
concat(round(Revenue * 100 / sum(Revenue) over(), 2), '%') as `Percentage` 
from agg order by `Store Name`, `Total Revenue`;


-- 3. Identify top 10 products and their % contribution to total quantity sold.
with req_cols as (
select p.product_name, oi.quantity
from order_items oi join products p on oi.product_id = p.product_id),
agg as (
select product_name as `Product Name`, sum(quantity)
as `Total Qty` from req_cols group by product_name)
select *, sum(`Total Qty`) over() as `Overall Total Qty`, 
concat(round(`Total Qty` * 100 / sum(`Total Qty`) over(), 2), '%') as `Percentage` 
from agg order by `Percentage` desc limit 10;


-- 4. Find brand sales share compared to total sales.
with req_cols as(
select b.brand_name, oi.quantity, oi.list_price, oi.discount
from order_items oi join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id join brands b
on p.brand_id = b.brand_id),
agg as (
select brand_name as `Brand Name`, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Revenue from req_cols group by `Brand Name`) 
select *, round(sum(Revenue) over(), 2) as `Total Revenue`, 
concat(round(Revenue * 100 / sum(Revenue) over(), 2), '%') as `Percentage` 
from agg order by `Percentage` desc;



-- V. Data Segmentation = Grouping the data based on a specific range. Helps understand correlation between two measures.
-- 1. Segment customers into spending ranges (< $1000, $1000–$5000, > $5000) and count customers in each.
with req_cols as (
select c.customer_id, oi.quantity, oi.list_price, oi.discount
from order_items oi join orders o on oi.order_id = o.order_id
join customers c on o.customer_id = c.customer_id),
agg as (
select customer_id, count(customer_id) as `Total Cx`, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Expenses from req_cols group by customer_id),
seg as (
select customer_id, `Total Cx`, Expenses,
case when Expenses < 1000 then 'Below $1000'
when Expenses >= 1000 and Expenses < 5000 then '$1000 - $5000'
else 'Above $5000' end as Spendings from agg)
select Spendings, count(Spendings) as `Total Count Category Wise` 
from seg group by Spendings order by Spendings;


-- 2. Group products into price ranges and count products in each segment.
with seg as (
select product_id,
case when list_price < 1000 then 'Cheap Product'
when list_price >= 1000 and list_price < 5000 then 'Affordable Product'
when list_price >= 5000 and list_price < 8000 then 'Expensive Product'
else 'Luxury Product' end `Price Range` from products)
select `Price Range`, count(product_id) as `Product Count` from seg 
group by `Price Range` order by `Product Count` desc;


-- 3. Segment stores based on yearly revenue ranges.
with req_cols as (
select s.store_name, oi.quantity, oi.list_price, oi.discount,
o.order_date from order_items oi join orders o on oi.order_id = o.order_id
join stores s on o.store_id = s.store_id),
agg as (
select year(order_date) as `Order Year`, store_name as `Store Name`, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as Revenue from req_cols group by `Order Year`, store_name)
select `Order Year`, `Store Name`, Revenue,
case when Revenue < 1000000 then 'Low Revenue'
when Revenue >= 1000000 and Revenue < 2000000 then 'Moderate Revenue'
else 'High Revenue' end `Revenue Range` from agg order by
`Order Year`, `Store Name`, Revenue desc;


-- 4. Group orders by order_status and calculate their percentage of total orders.
with agg as (
select count(distinct order_id) as `Order Count`,
case when order_status = 1 then 'Pending'
when order_status = 2 then 'Processing'
when order_status = 3 then 'Rejected'
else 'Completed' end as Segmenting from orders group by
order_status)
select Segmenting, `Order Count`, sum(`Order Count`) over() as 
`Total Orders`, concat(round(`Order Count` * 100 / sum(`Order Count`) 
over(), 2), '%') as `Percentage` from agg order by `Percentage`;



-- VI. Customer Segmentation
-- 1. Group customers into:
-- VIP – at least 12 months of history and spending > $5000.
-- Regular – at least 12 months of history and spending ≤ $5000.
-- New – less than 12 months of history.
with req_cols as (
select o.order_date, c.customer_id, oi.quantity, oi.list_price, oi.discount
from orders o join order_items oi on o.order_id = oi.order_id join
customers c on o.customer_id = c.customer_id),
customer_spending as (
select customer_id, round(sum(quantity * (list_price - (list_price * discount))), 2)
as `Total Spendings`, min(order_date) as first_order, max(order_date) as last_order,
timestampdiff(month, min(order_date), max(order_date)) as `Cx Lifespan` from
req_cols group by customer_id),
seg as (
select customer_id,
case when `Total Spendings` > 5000 and `Cx Lifespan` >= 12 then 'VIP'
when `Total Spendings` <= 5000 and `Cx Lifespan` >= 12 then 'Regular'
else 'New' end as Segments from customer_spending)
select `Segments`, count(distinct customer_id) as `Cx Count` from 
seg group by `Segments` order by `Cx Count` desc;


-- 2. Segment customers by city and calculate average order value per city.
with req_cols as (
select c.customer_id, c.city, oi.quantity, oi.list_price, oi.discount
from orders o join order_items oi on o.order_id = oi.order_id join
customers c on o.customer_id = c.customer_id),
agg as (
select customer_id, count(customer_id) as `Total Cx`, city, 
round(sum(quantity * (list_price - (list_price * discount))), 2)
as `Order Value` from req_cols group by customer_id, city)
select customer_id, `Total Cx`, city, `Order Value`,
round(avg(`Order Value`) over(partition by city), 2) as 
`Avg Order Value Per City` from agg order by city, `Order Value` desc;


-- 3. Identify loyal customers by checking their orders placed every year in the dataset.
with total_years as (
select count(distinct year(order_date)) as `Total Years` from orders),
loyalty_test AS (
select customer_id as `Cx Id`, count(distinct year(order_date)) as Loyalty
from orders group by `Cx Id`)
select lt.`Cx Id`, cu.full_name as `Name`, lt.Loyalty, ty.`Total Years` 
from loyalty_test lt join total_years ty
join customers cu on lt.`Cx Id` = cu.customer_id
where lt.Loyalty = ty.`Total Years`
order by `Cx Id`;





-- VII. Reporting
/* -----------------------------------------------------------------------------
1. Customer Report
-- Full name, city, state, ZIP code.
-- Segment (VIP, Regular, New).
-- Total orders placed.
-- Total sales value.
-- Total quantity purchased.
-- Total unique products purchased.
-- Lifespan in months (first purchase to latest purchase).
-- Recency in months.
-- Average order value.
-- Average monthly spend.
------------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
2. Store Performance Report
-- Store name, city, state.
-- Total sales, total orders, total quantity sold.
-- % contribution to total sales.
-- Average order value per store.
-- YoY growth rate.
-- Staff count and their combined sales.
------------------------------------------------------------------------------- /*

/* -----------------------------------------------------------------------------
3. Product Performance Report
-- Product name, brand, category, model_year.
-- Total sales and quantity sold.
-- % contribution to category sales.
-- Sales trend over years.
-- Return rate (if applicable).
------------------------------------------------------------------------------- /*