create database DataWarehouseAnalytics;
use DataWarehouseAnalytics;


select * from customers;
select * from products;
select * from fact_sales;
describe customers;
describe products;
describe fact_sales;

alter table customers modify column customer_number varchar(50);
alter table customers modify column first_name varchar(50);
alter table customers modify column last_name varchar(50);
alter table customers modify column country varchar(50);
alter table customers modify column marital_status varchar(50);
alter table customers modify column gender varchar(50);
-- alter table customers modify column birthdate date;
alter table customers modify column create_date date;

alter table customers add column birthdate_xx date;
SET SQL_SAFE_UPDATES = 0;
update customers set birthdate_xx = str_to_date(birthdate, '%Y-%m-%d') where birthdate is not null and birthdate != '';
alter table customers drop column birthdate;
alter table customers change birthdate_xx birthdate date;




alter table products modify column product_name varchar(50);
alter table products modify column category_id varchar(50);
alter table products modify column category varchar(50);
alter table products modify column subcategory varchar(50);
alter table products modify column maintenance varchar(50);
alter table products modify column product_line varchar(50);
alter table products modify column start_date date;




alter table fact_sales modify column order_number varchar(50);
-- alter table fact_sales modify column order_date date;
alter table fact_sales modify column shipping_date date;
alter table fact_sales modify column due_date date;


alter table fact_sales add column order_no date;
update fact_sales set order_no = str_to_date(order_date, '%Y-%m-%d') where order_date is not null and order_date != '';
alter table fact_sales drop column order_date;
alter table fact_sales change order_no order_date date;





-- Advanced Data Analytics

-- 1. Change Over Time Trends = Analyze how a measure evolves over time. Help track trends and identify seasonality in your data.
-- sigma[measure] by [date dimension]  eg total sales by year, average cost by month
-- Analyze Sales Performance Over Time

-- Day Wise
select order_date, sum(sales_amount) as total_sales, count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantities from fact_sales where order_date is not null group by order_date order by order_date;

-- Month Wise
select Month(order_date) as month, sum(sales_amount) as total_sales, count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantities from fact_sales where order_date is not null group by Month(order_date) order by Month(order_date);

-- Year Wise
select Year(order_date) as year, sum(sales_amount) as total_sales, count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantities from fact_sales where order_date is not null group by Year(order_date) order by Year(order_date);


select Year(order_date) as year, Month(order_date) as month, sum(sales_amount) as total_sales, count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantities from fact_sales where order_date is not null group by Year(order_date), Month(order_date) order by Year(order_date), Month(order_date);


select DATE_FORMAT(order_date, '%Y-%m-01') as order_date, sum(sales_amount) as total_sales, count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantities from fact_sales where order_date is not null group by DATE_FORMAT(order_date, '%Y-%m-01') order by DATE_FORMAT(order_date, '%Y-%m-01');




-- 2. Cumulative Analysis = Aggregating data progressively over time. Help to understand how our business is performing over the time i.e. whether it is growing or declining
-- sigma[cumulative measure] by [date dimension]   eg:  running total sales by year, moving avg of sales by month
-- Calculate Total Sales per month and the running total of sales over time

select order_date, total_sales, sum(total_sales) over(partition by year(order_date) order by order_date) as running_sales,
avg_sales, round(avg(avg_sales) over(partition by year(order_date) order by order_date), 2) as moving_avg_sales from
(select date_format(order_date, '%Y-%m-01') as order_date, sum(sales_amount) as total_sales, round(avg(sales_amount), 2) as avg_sales 
from fact_sales where order_date is not null group by date_format(order_date, '%Y-%m-01')) as t;





-- 3. Performance Analysis = Comparing the current value with the targeted value. Helps to measure the success and to compare the performance.
-- current[measure] - target[measure]    eg comparing current sales with avg sales or current year sales with prev year sales or current sales with lowest/highest sales
-- Analyze the yearly performance of products by comparing each product's sales to both  its avg sales performance and previous year's sales.

with yearly_product_sales as(
select year(s.order_date) as order_date, p.product_name, sum(s.sales_amount) as current_total_sales from products p right join fact_sales s on p.product_key = s.product_key
where order_date is not null group by year(s.order_date), product_name)

select order_date, product_name, current_total_sales, round(avg(current_total_sales) over(partition by product_name), 2) as avg_sales,
round(current_total_sales - avg(current_total_sales) over(partition by product_name), 2) as diff_avg_sales, 
case when current_total_sales - avg(current_total_sales) over(partition by product_name) > 0 then 'Above Average'
when current_total_sales - avg(current_total_sales) over(partition by product_name) < 0 then 'Below Average'
else 'Average' end avg_change, 
lag(current_total_sales) over(partition by product_name order by order_date asc) as prev_year_sales,
current_total_sales - lag(current_total_sales) over(partition by product_name order by order_date asc) as diff_prev_year_sales,
case when current_total_sales - lag(current_total_sales) over(partition by product_name order by order_date asc) > 0 then 'More Sales'
when current_total_sales - lag(current_total_sales) over(partition by product_name order by order_date asc) < 0 then 'Less Sales'
else 'No Change' end prev_yr_change
from yearly_product_sales order by product_name, order_date;






-- 4. Part-To-Whole Analysis / Propotional Analysis = Analyze how an individual part is performing compared to the overall, 
-- allowsing us to understand which category has the greatest	impact on the business.
-- ([Measure] / total[Measure]) * 100 by [Dimension]      eg sales/total sales *100 by category or quantity/total quantity *100 by country
-- Which categories contribute the most to the overall sales?

with category_sales as
(select p.category, sum(s.sales_amount) as total_sales from products p right join fact_sales s 
on p.product_key = s.product_key group by category)
select category, total_sales, sum(total_sales) over() as overall_sales, concat(round(total_sales * 100 / sum(total_sales) over(), 2), '%') as percentage 
from category_sales order by total_sales desc;





-- 5. Data Segmentation = Grouping the data based on a specific range. Helps understand correlation between two measures.
-- [Measure] by [Measure]      eg  total no. of products by  sales range or total no. of customers by age
-- Segment Products into cost ranges and count how many products fall into each segment.

with product_segment as (select product_key, product_name, 
case when cost < 500 then 'Below 500'
when cost between 500 and 1000 then '500 - 1000'
when cost between 1000 and 1500 then '1000 - 1500'
when cost between 1500 and 2000 then '1500 - 2000'
else 'Above 2000' end as segments from products)
select segments, count(product_name) as total_products from product_segment group by segments order by total_products desc;



-- Group Customers into three segments based on their spending behavior.
-- i. VIP with atleast 12 months of history and spendings more than $5000
-- ii. Regular with atleast 12 months of history and spendings less than $5000 or less
-- iii. New with lifespan less than 12 months

with customer_spending as
(select c.customer_key, sum(s.sales_amount) as total_spendings, min(order_date) as first_order, max(order_date) as last_order, 
timestampdiff(month, min(order_date), max(order_date)) as lifespan from fact_sales s left join customers c on s.customer_key = c.customer_key group by customer_key)

select segments, count(customer_key) as total_customers from
(select customer_key,
case when total_spendings > 5000 and lifespan >= 12 then 'VIP'
when total_spendings <= 5000 and lifespan >= 12 then 'Regular'
else 'New' end as segments from customer_spending) as t
group by segments order by total_customers desc;






-- 6. Reporting = Inputting all the insights and figures that are important together in one table or view for quick analysis for decision making.
/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors
Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value (total sales / total no. of orders)
		- average monthly spend (total sales / no. of months)
===============================================================================
*/


create view customer_report as
-- Base Query = Retrieving core columns from tables.
with base_query as (
select s.order_number, s.product_key, s.sales_amount, s.quantity, s.order_date,
c.customer_key, c.customer_number, c.birthdate, concat(c.first_name, ' ', c.last_name) as customer_name, timestampdiff(year, birthdate, curdate()) as age 
from fact_sales s left join customers c on s.customer_key = c.customer_key where order_date is not null)


-- Customer Aggregation = Summarizes key metrics at the customer level.
, customer_aggregation as (
select customer_key, customer_number, customer_name, age, count(order_number) as total_orders,
sum(sales_amount) as total_sales, sum(quantity) as total_quantity, count(product_key) as total_products,
max(order_date) as last_order_date, timestampdiff(month, min(order_date), max(order_date)) as lifespan 
from base_query group by customer_key, customer_number, customer_name, age)


-- Customer Segmentation = Segmenting the customers as per their age and puchase behavior.
, customer_segmentation as (
select customer_key, customer_number, customer_name, age, 
case when lifespan >= 12 and total_sales > 5000 then 'VIP'
when lifespan >= 12 and total_sales <= 5000 then 'Regular'
else 'New' end as purchasing_behavior_segment,
case when age < 20 then 'Under 20'
when age between 20 and 45 then '20 - 45'
when age between 45 and 70 then '45 - 70'
else 'above 70' end as age_segment, 
total_orders, total_sales, total_quantity, total_products, last_order_date, lifespan from customer_aggregation)


-- Calculating KPI = Creating the above mentioned KIP's.
select customer_key, customer_number, customer_name, age, purchasing_behavior_segment, 
age_segment, last_order_date, timestampdiff(month, last_order_date, curdate()) as recency, 
total_orders, total_sales, total_quantity, total_products, lifespan, 
case when total_orders = 0 then 0
else (total_sales / total_orders) end as average_order_value,
case when lifespan = 0 then total_sales
else (total_sales / lifespan) end as average_monthly_spend from customer_segmentation;


select * from customer_report;





/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.
Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/

create view product_report as
with base_query as (
select p.product_key, p.product_name, p.category, p.subcategory, p.cost, 
s.customer_key, s.sales_amount, s.order_number, s.quantity, s.order_date
from fact_sales s left join products p on s.product_key = p.product_key
where order_date is not null)

, customer_aggregation as (
select product_key, product_name, category, subcategory, cost, count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales, sum(quantity) as total_quantity_sold, count(distinct customer_key) as total_unique_customers, 
timestampdiff(month, min(order_date), max(order_date)) as lifespan, max(order_date) as last_order_date, 
round(avg(cast(sales_amount as float) / nullif(quantity, 0)), 2) as avg_selling_price from base_query group by product_key, product_name, category, subcategory, cost)

, customer_segmentation as (
select product_key, product_name, category, subcategory, cost, total_orders, total_sales, total_quantity_sold, total_unique_customers, lifespan, last_order_date, avg_selling_price,
case when total_sales >= 800000 then 'High-Performers'
when total_sales between 400000 and 800000 then 'Mid-Range'
else 'Low-Performers' end as revenue_segment from customer_aggregation)

select product_key, product_name, category, subcategory, cost, last_order_date, 
timestampdiff(month, last_order_date, curdate()) as recency, revenue_segment,
lifespan, total_orders, total_sales, total_quantity_sold, total_unique_customers, avg_selling_price,  
case when total_orders = 0 then 0
else (total_sales / total_orders) end as average_order_revenue,
case when lifespan = 0 then total_sales
else (total_sales / lifespan) end as average_monthly_revenue
from customer_segmentation;






























