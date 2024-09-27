select * from dim_customer;
select * from dim_product;

select * from fact_sales_monthly;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market 
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';

-- 2.What is the percentage of unique product increase in 2021 vs. 2020?
-- The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

with dist_prod as 
(
	select 
		fiscal_year,
        count(DISTINCT product_code) as product_cnt
    from fact_sales_monthly 
	where fiscal_year in (2020,2021)
    group by fiscal_year
)
 select 
		dp_2020.product_cnt as 2020_unique_product,
		dp_2021.product_cnt as 2021_unique_product,
        round(100 * (dp_2021.product_cnt-dp_2020.product_cnt)/dp_2020.product_cnt,2) as Chg_unique_product
 from dist_prod dp_2020
 join dist_prod dp_2021
 where dp_2020.fiscal_year = 2020 and dp_2021.fiscal_year = 2021;
 
-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
-- The final output contains 2 fields, segment product_count

	select segment,
    count(DISTINCT product_code) as product_cnt
    from dim_product
    GROUP BY segment
    ORDER BY product_cnt desc;

 
 -- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
 -- The final output contains these fields, segment product_count_2020 product_count_2021 difference
 
 with unique_products as 
 (
	select 
		p.segment,
		s.fiscal_year,
		COUNT(DISTINCT p.Product_code) as product_count
	from dim_product p 
	join fact_sales_monthly s on p.product_code=s.product_code
	where s.fiscal_year in (2020,2021)
	GROUP BY segment,fiscal_year
 )
 select 
	up_2020.segment,
	up_2020.product_count as product_count_2020,
	up_2021.product_count as product_count_2021,
	(up_2021.product_count-up_2020.product_count)  as difference
 from unique_products up_2020
 join unique_products up_2021
 where up_2020.fiscal_year =2020 and  up_2021.fiscal_year =2021 and up_2020.segment = up_2021.segment
 ORDER BY difference DESC;
 
 -- 5. Get the products that have the highest and lowest manufacturing costs.
 -- The final output should contain these fields, product_code product manufacturing_cost
 
 with temp as 
(
	 select 
		p.product_code
		,m.manufacturing_cost
		,DENSE_RANK () over (order by manufacturing_cost desc) as top_rnk 
		,DENSE_RANK () over (order by manufacturing_cost asc) as bot_rnk 
	 from dim_product p
	 join fact_manufacturing_cost m
	 on p.product_code = m.product_code
)
select product_code,manufacturing_cost
from temp where top_rnk =1 or bot_rnk = 1
order by top_rnk;

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 
-- and in the Indian market.The final output contains these fields, customer_code customer average_discount_percentage

	select c.customer_code,c.customer,avg(pd.pre_invoice_discount_pct) as average_discount_percentage
	from dim_customer c 
	join fact_pre_invoice_deductions pd 
	on c.customer_code = pd.customer_code
	where fiscal_year = 2021 and market = 'India'
    GROUP BY 1,2
    Order By 3 Desc
    Limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: Month Year Gross sales Amount

select month(s.date) as mth, year(s.date) as year , concat(round(sum(sold_quantity*gross_price)/1000000,2),'M') as `Gross sales Amount`
from fact_sales_monthly	s
join dim_customer c on s.customer_code =c.customer_code
join fact_gross_price p on p.product_code =s.product_code and p.fiscal_year = s.fiscal_year
where customer = 'Atliq Exclusive'
group by 1,2
order by 2,1;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

select  Concat('Q',quarter(date_add(date,interval 4 Month))) as qtr,round(sum(sold_quantity)/1000000,2) as `total_sold_quantity(in_mlm)`
from fact_sales_monthly 
where fiscal_year  = 2020
group by 1
order by `total_sold_quantity(in_mlm)` desc;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields, channel gross_sales_mln percentage
with cte as 
(
	select c.channel, round(sum(sold_quantity * gross_price)/1000000,2) as gross_sales_mln,
		   sum(round(sum(sold_quantity * gross_price)/1000000,2)) over(order by c.channel ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING ) as total_sales
	from dim_customer c
	join fact_sales_monthly s 
	on c.customer_code = s.customer_code 
	join fact_gross_price p 
	on s.product_code = p.product_code and s.fiscal_year = p.fiscal_year
	where s.fiscal_year = 2021
	GROUP BY c.channel
)
select channel,gross_sales_mln, round(100 * (gross_sales_mln/total_sales),2) as percentage
from cte
order by percentage desc;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- The final output contains these fields, division product_code product total_sold_quantity rank_order

with cte as 
(
    select 
		 division,
		 p.product_code,
		 p.product,
		 sum(sold_quantity) as total_sold_quantity,
		 DENSE_RANK() over (PARTITION BY division order by sum(sold_quantity) desc) as rank_order
	from dim_customer c
	join fact_sales_monthly s 
	on c.customer_code = s.customer_code
	join dim_product p 
	on p.product_code = s.product_code
	where fiscal_year = 2021
    Group by 1,2,3
) 
select * from cte where rank_order <=3;
