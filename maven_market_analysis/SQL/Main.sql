create database maven_market_project;
use maven_market_project;

alter table transaction_1998 rename to transaction_98;


-- Cleaning and Transforming the date
-- 1. Customer Table  
desc customers;
select * from customers;

alter table customers add(full_name varchar(45));
SET SQL_SAFE_UPDATES = 0;
update customers set full_name = concat(first_name, ' ', last_name);
alter table customers drop column first_name, drop column last_name;

UPDATE customers SET birthdate = STR_TO_DATE(birthdate, '%m/%d/%Y');
UPDATE customers SET acct_open_date = STR_TO_DATE(acct_open_date, '%m/%d/%Y');
alter table customers modify column birthdate date, modify column acct_open_date date;

ALTER TABLE customers ADD COLUMN income INT;
UPDATE customers SET income = CASE WHEN TRIM(yearly_income) = '$150K +' THEN 150000
  ELSE (
    (
      CAST(REPLACE(REPLACE(SUBSTRING_INDEX(yearly_income, '-', 1), '$', ''), 'K', '') AS UNSIGNED) +
      CAST(REPLACE(REPLACE(SUBSTRING_INDEX(yearly_income, '-', -1), '$', ''), 'K', '') AS UNSIGNED)
    ) * 500
  ) END WHERE yearly_income IS NOT NULL;
alter table customers drop column yearly_income;


-- 2. Products Table
desc products;
select * from products limit 3;

update products set recyclable = CASE WHEN recyclable = '1' THEN 'Yes' ELSE 'No' END;
update products set low_fat = CASE WHEN recyclable = '1' THEN 'Yes' ELSE 'No' END;


-- 3. Regions Table
desc regions;
select * from regions limit 3;


-- 4. Returns Table
desc returns;
select * from returns limit 3;

UPDATE returns SET return_date= STR_TO_DATE(return_date, '%m/%d/%Y');
alter table returns modify column return_date date;


-- 5. Stores Table
desc stores;
select * from stores limit 3;

UPDATE stores SET first_opened_date = STR_TO_DATE(first_opened_date, '%m/%d/%Y');
UPDATE stores SET last_remodel_date = STR_TO_DATE(last_remodel_date, '%m/%d/%Y');
alter table stores modify column first_opened_date date;
alter table stores modify column last_remodel_date date;


-- 6. Transaction_97 Table
desc transaction_97;
select * from transaction_97 limit 3;

UPDATE transaction_97 SET transaction_date = STR_TO_DATE(transaction_date, '%m/%d/%Y');
UPDATE transaction_97 SET stock_date = STR_TO_DATE(stock_date, '%m/%d/%Y');
alter table transaction_97 modify column transaction_date date;
alter table transaction_97 modify column stock_date date;


-- 7. Transaction_98 Table
desc transaction_98;
select * from transaction_98 limit 3;

UPDATE transaction_98 SET transaction_date = STR_TO_DATE(transaction_date, '%m/%d/%Y');
UPDATE transaction_98 SET stock_date = STR_TO_DATE(stock_date, '%m/%d/%Y');
alter table transaction_98 modify column transaction_date date;
alter table transaction_98 modify column stock_date date;


-- Checking for null values
select * from customers where customer_id is null or customer_id is null or customer_acct_num is null or full_name is null or customer_address is null or 
customer_city is null or customer_state_province is null or customer_postal_code is null or customer_country is null or birthdate is null or 
marital_status is null or income is null or gender is null or total_children is null or num_children_at_home is null or education is null or
acct_open_date is null or member_card is null or occupation is null or homeowner is null;

select * from regions where region_id is null or sales_district is null or sales_region is null;

select * from products where product_id is null or product_name is null or product_brand is null or product_sku is null or 
product_retail_price is null or product_cost is null or product_weight is null or recyclable is null or low_fat is null;

select * from returns where return_date is null or product_id is null or store_id is null or quantity is null;

select * from stores where store_id is null or region_id is null or store_type is null or store_name is null or store_street_address is null or store_city is null or 
store_state is null or store_country is null or store_phone is null or first_opened_date is null or last_remodel_date is null or total_sqft is null or grocery_sqft is null;

select * from transaction_97 where  transaction_date is null or stock_date is null or product_id is null or store_id is null or customer_id is null or quantity is null;

select * from transaction_98 where  transaction_date is null or stock_date is null or product_id is null or store_id is null or customer_id is null or quantity is null;


-- Renaming the quantity columns for better differentiation
alter table transaction_97 change column quantity product_quantity int;
alter table transaction_98 change column quantity product_quantity int;
alter table returns change column quantity return_quantity int;



-- QUESTIONS 
-- 1. Top Performing Products = Which products generated the highest total revenue in 1998, and how does that compare to 1997?

with sales_97 as (
select p.product_id, p.product_name, sum(t_97.product_quantity) as total_qty_97, round(sum(p.product_retail_price * t_97.product_quantity), 4) as total_rev_97 
from products p inner join transaction_97 t_97 on p.product_id = t_97.product_id group by p.product_id, p.product_name),
sales_98 as (
select p.product_id, p.product_name, sum(t_98.product_quantity) as total_qty_98, round(sum(p.product_retail_price * t_98.product_quantity), 4) as total_rev_98 
from products p inner join transaction_98 t_98 on p.product_id = t_98.product_id group by p.product_id, p.product_name),
combined_sales as (
select coalesce(s97.product_id, s98.product_id) as product_id, coalesce(s97.product_name, s98.product_name) AS product_name, s97.total_qty_97, s97.total_rev_97, s98.total_qty_98, s98.total_rev_98 
from sales_97 s97 left join sales_98 s98 on s97.product_id = s98.product_id  
union all
select coalesce(s97.product_id, s98.product_id) as product_id, coalesce(s97.product_name, s98.product_name) AS product_name, s97.total_qty_97, s97.total_rev_97, s98.total_qty_98, s98.total_rev_98 
from sales_97 s97 right join sales_98 s98 on s97.product_id = s98.product_id where s97.product_id is null)
select product_name, coalesce(total_qty_97, 0) AS total_qty_97, coalesce(total_rev_97, 0) as revenue_97, coalesce(total_qty_98, 0) as total_qty_98,
    coalesce(total_rev_98, 0) as revenue_98, round(coalesce(total_rev_98, 0) - coalesce(total_rev_97, 0), 4) as revenue_change from combined_sales order by total_rev_98 desc limit 10;



-- 2. Customer Lifetime Value (CLV) = What is the lifetime revenue generated by each customer across both years? List the top 10.

with all_transactions as (
select t.customer_id, t.product_id, t.product_quantity, p.product_retail_price, (t.product_quantity * p.product_retail_price) as revenue from (
select * from transaction_97 union all select * from transaction_98) as t
inner join products p on t.product_id = p.product_id),
cx_revenue as (
select customer_id, sum(revenue) as total_revenue from all_transactions group by t.customer_id),
ranked_cx as (
select cr.customer_id, c.full_name, cr.total_revenue, rank() over (order by cr.total_revenue desc) as revenue_ranks
from cx_revenue cr join customers c on cr.customer_id = c.customer_id)
select full_name, round(total_revenue, 2) as lifetime_revenue, revenue_ranks from ranked_cx limit 10;



-- 3. Return Rate by Product = Which products have the highest return rate (returns / sold units)?

-- total_products_returned / (total_products_sold + total_products_returned) * 100
with transactions as (select * from transaction_97 union all select * from transaction_98),
total_sales as (
select product_id, sum(product_quantity) as total_units_sold from transactions group by product_id),
total_returns as (
select product_id, SUM(return_quantity) as total_units_returned from returns group by product_id)
select p.product_name, s.total_units_sold, coalesce(r.total_units_returned, 0) as total_units_returned, 
round(coalesce(r.total_units_returned, 0) / s.total_units_sold * 100, 2) as return_rate_percent
from total_sales s left join total_returns r on s.product_id = r.product_id
left join products p on s.product_id = p.product_id order by return_rate_percent desc limit 5;

-- OR 

with total_sales as (
select product_id, sum(product_quantity) as total_units_sold from (select * from transaction_97 union all select * from transaction_98) as combined_transactions group by product_id),
total_returns as (
select product_id, SUM(return_quantity) as total_units_returned from returns group by product_id)
select p.product_name, s.total_units_sold, coalesce(r.total_units_returned, 0) as total_units_returned, 
round(coalesce(r.total_units_returned, 0) / s.total_units_sold * 100, 2) as return_rate_percent
from total_sales s left join total_returns r on s.product_id = r.product_id
left join products p on s.product_id = p.product_id order by return_rate_percent desc limit 5;



-- 4. Monthly Sales Trend = What is the total revenue per month for both years combined?
select date_format(t.transaction_date, '%Y-%m') as months, round(sum(t.product_quantity * p.product_retail_price), 2) as total_revenue from (
select * from transaction_97 union all select * from transaction_98) as t join products p on t.product_id = p.product_id group by months;

--                                             OR

select monthname(t.transaction_date) as months, round(sum(t.product_quantity * p.product_retail_price), 2) as total_revenue from (
select * from transaction_97 union all select * from transaction_98) as t join products p on t.product_id = p.product_id group by months;




-- 5. New vs Returning Customers = For each year, how many customers were first-time buyers and how many were returning?
with transactions as (select customer_id, transaction_date from (select * from transaction_97 union all select * from transaction_98) as t),
check_puchase as (select customer_id, year(transaction_date) as transaction_year, 
case when not exists (select 1 from transactions t2 where t2.customer_id = t1.customer_id and year(t2.transaction_date) < year(t1.transaction_date)) then 'First-Time'else 'Returning'
end as customer_type from transactions t1)
select transaction_year, customer_type, count(distinct customer_id) as customer_count from 
check_puchase group by transaction_year, customer_type order by transaction_year, customer_type;



-- 6. Store-Level Performance = Which stores performed best in terms of revenue per square foot?

with transactions as (select t.product_id, t.store_id, t.product_quantity from (select * from transaction_97 union all select * from transaction_98) as t)
select s.store_name, s.grocery_sqft, round(sum(p.product_retail_price * tr.product_quantity), 2) as revenue, 
round(sum(p.product_retail_price * tr.product_quantity) / s.grocery_sqft, 2) as total_revenue_per_sqft from stores s join transactions tr on 
s.store_id = tr.store_id join products p on tr.product_id = p.product_id group by s.store_name, s.grocery_sqft order by total_revenue_per_sqft desc;



-- 7. Regional Profitability = Which regions were the most profitable, and what product categories drove that profit?

with transactions as (select * from transaction_97 union all select * from transaction_98),
profits as (select t.product_id, t.store_id, sum(t.product_quantity * (p.product_retail_price - p.product_cost)) as total_profit 
from transactions t join products p on t.product_id = p.product_id group by t.product_id, t.store_id),
returned as (select product_id, SUM(return_quantity) as total_returns from returns group by product_id)
select r.sales_region, p.product_name, round(sum(pr.total_profit - coalesce(rt.total_returns, 0) * (p.product_retail_price - p.product_cost)), 2) as net_profit
from profits pr join stores s on pr.store_id = s.store_id join regions r on s.region_id = r.region_id join products p on pr.product_id = p.product_id
join returned rt on pr.product_id = rt.product_id group by r.sales_region, p.product_name order by net_profit desc;



-- 8. Demographic Insights = What is the average annual income of customers buying low-fat or recyclable products?
with transactions as (select * from transaction_97 union all select * from transaction_98)
select round(avg(distinct c.income) ,2) as Average_Income from customers c join transactions t on c.customer_id = t.customer_id join
products p on t.product_id = p.product_id where p.low_fat = 'Yes' or p.low_fat = 'yes' or p.recyclable = 'Yes' or p.recyclable= 'yes';



-- 9. Sales Decay after Product Return = Do product returns lead to a drop in future sales of that product at the same store?

with transactions as (select * from transaction_97 union all select * from transaction_98),
monthly_sales as (select t.product_id, t.store_id, date_format(t.transaction_date, '%Y-%m') as months, sum(t.product_quantity) as total_sales 
from transactions t group by t.product_id, t.store_id, months),
monthly_returns as (select re.product_id, s.store_id, date_format(re.return_date, '%Y-%m') as months, sum(re.return_quantity) as total_returns 
from returns re join stores s on re.store_id = s.store_id group by re.product_id, s.store_id, months),
combined_data as(select ms.product_id, ms.store_id, ms.months, ms.total_sales, coalesce(mr.total_returns, 0) as total_returns from monthly_sales ms left join monthly_returns mr on 
ms.product_id = mr.product_id and ms.store_id = mr.store_id and ms.months = mr.months),
sales_with_lead as (select *, LEAD(total_sales) OVER (PARTITION BY product_id, store_id order by months) as next_month_sales from combined_data)
select product_id, store_id, months, total_returns, total_sales as current_month_sales, next_month_sales,
case when total_returns > 0 and next_month_sales < total_sales THEN 'Drop After Return'
when total_returns > 0 and next_month_sales >= total_sales THEN 'No Drop'
else 'No Return' end as x from sales_with_lead order by x, product_id, store_id, months;



-- 10. Product Substitution Behavior = If a returned product was followed by a purchase of a different product by the same customer, what was the most common substitution?

with transactions as (select * from transaction_97 union all select * from transaction_98),
return_products_with_next_purchase as (
select re.product_id as returned_product_id, re.return_date, re.store_id, t.product_id as next_product_id, t.transaction_date,
row_number() over (partition by re.store_id, re.product_id, re.return_date order by t.transaction_date) as ranks
from transactions t join returns re on t.store_id = re.store_id where t.transaction_date > re.return_date and t.product_id != re.product_id)
select p.product_name as most_common_substitution, count(*) as substitution_count from return_products_with_next_purchase rp join products p on rp.next_product_id = p.product_id
where rp.ranks = 1 group by p.product_name order by substitution_count desc limit 1;



-- 11. Marital Status & Buying Power = Do married customers spend more than single customers, controlling for income and children at home?

with transactions as (select * from transaction_97 union all select * from transaction_98),
cx_spendings as (select t.customer_id, round(sum(t.product_quantity * p.product_retail_price), 2) as total_spending from transactions t join products p
on t.product_id = p.product_id group by t.customer_id)
select c.marital_status, c.income, c.num_children_at_home, round(avg(cs.total_spending), 2) as average_spending from cx_spendings cs join
customers c on cs.customer_id = c.customer_id group by c.marital_status, c.income, c.num_children_at_home order by c.marital_status, c.income, c.num_children_at_home;



-- 12. Product Pricing Strategy = Which brands have the highest markup (retail - cost) and how does their sales volume compare?

with transactions as (select * from transaction_97 union all select * from transaction_98),
product_sales as ( select product_id, sum(product_quantity) as total_sales from transactions group by product_id),
comparison as (select p.product_brand, round(avg(p.product_retail_price - p.product_cost), 2) as avg_markup, sum(ps.total_sales) as sales_volume 
from products p join product_sales ps on p.product_id = ps.product_id group by p.product_brand)
select * from comparison order by avg_markup desc;



-- 13. Sales Before and After Store Remodel = What was the average change in monthly sales before vs after each store’s last remodel date?

with transactions as (select * from transaction_97 union all select * from transaction_98),
sales as (select s.store_id, s.store_name, s.last_remodel_date, date_format(t.transaction_date, '%Y-%m') as months, sum(t.product_quantity * p.product_retail_price) as total_sales
from transactions t join stores s on t.store_id = s.store_id join products p on t.product_id = p.product_id group by store_id, store_name, s.last_remodel_date, months),
monthly_avg_sales as (select store_id, store_name, round(avg(case when months < date_format(last_remodel_date, '%Y-%m') then total_sales end), 2) as avg_monthly_sales_before,
round(avg(case when months >= date_format(last_remodel_date, '%Y-%m') then total_sales end), 2) as avg_monthly_sales_after
from sales group by store_id, store_name)
select store_name, avg_monthly_sales_before, avg_monthly_sales_after, round(avg_monthly_sales_after - avg_monthly_sales_before, 2) as avg_change from monthly_avg_sales
order by avg_change desc;



-- 14. Customer Segmentation = Segment customers by income level, number of children, and education. Analyze revenue per segment.

WITH transactions AS (SELECT * FROM transaction_97 UNION ALL SELECT * FROM transaction_98),
cx_revenue as (
select t.customer_id, sum(t.product_quantity * p.product_retail_price) as total_revenue from transactions t join products p on t.product_id = p.product_id group by t.customer_id)
select case when c.income < 40000 then 'Low Income' when c.income between 40000 and 80000 then 'Mid Income' else 'High Income' end as income_segment,
c.total_children, c.education, round(avg(cx_r.total_revenue), 2) as avg_revenue, round(sum(cx_r.total_revenue), 2) as total_revenue,
count(distinct c.customer_id) as customer_count from cx_revenue cx_r join customers c on cx_r.customer_id = c.customer_id group by income_segment, c.total_children, c.education 
order by income_segment, c.total_children, c.education;



-- 15. Product Demand Forecasting Base = Calculate 3-month moving average of quantity sold for each product.

with transactions as (select * from transaction_97 union all select * from transaction_98),
monthly_sales as (select product_id, date_format(transaction_date, '%Y-%m') as months, sum(product_quantity) as total_qty_sold from transactions group by product_id, months)
select product_id, months, total_qty_sold, round(avg(total_qty_sold) over (partition by product_id order by months rows between 2 preceding and current row), 2) as moving_avg_of_3_months
from monthly_sales order by product_id, months;


