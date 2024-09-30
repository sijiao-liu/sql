-- COALESCE
/* 
1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

	SELECT 
	product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
	FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL 
-with a blank for the first problem, 
-with 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) 
*/

SELECT --*,
	product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product
;



--Windowed Functions
/* 
1. Write a query that selects from the customer_purchases table 
and numbers each customer’s visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

1) You can either display all rows in the customer_purchases table, 
with the counter changing on each new market date for each customer, 
	or 
2) select only the unique market dates per customer (without purchase details) and number those visits. 

HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
*/

--- method 1): using dense_rank()
SELECT *,
	-- returns the same rank when the market_date is the same for each customer_id
	dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date) as customer_visit_number
FROM customer_purchases
;

--- method 2): using dense_rank() without purchase details
SELECT
	customer_id,
	market_date, 
	-- returns the same rank when the market_date is the same for each customer_id
	row_number() OVER (PARTITION BY customer_id ORDER BY market_date)  as customer_visit_number
FROM (
	SELECT DISTINCT
		customer_id,
		market_date
	FROM customer_purchases
)
;


/* 
2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. 
*/

--- method 1): using dense_rank() within a subquery
SELECT *
FROM (
	SELECT *,
		-- returns the same rank when the market_date is the same for each customer_id
		dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date DESC) as customer_visit_number
	FROM customer_purchases
)
WHERE customer_visit_number = 1
;

--- method 2): using dense_rank() without purchase details within a subquery
SELECT *
FROM (
	SELECT
		customer_id,
		market_date, 
		-- returns the same rank when the market_date is the same for each customer_id
		row_number() OVER (PARTITION BY customer_id ORDER BY market_date DESC)  as customer_visit_number
	FROM (
		SELECT DISTINCT
			customer_id,
			market_date
		FROM customer_purchases
	)
)
WHERE customer_visit_number = 1
;


/* 
3. Using a COUNT() window function, include a value along with each row of the customer_purchases table 
that indicates how many different times that customer has purchased that product_id. 
*/

SELECT DISTINCT -- since the customer_purchases is quite large and would exist some duplicated data after applying the count(), so decided using DISTINCT
	customer_id,
	product_id,
	count(*) OVER (PARTITION BY customer_id, product_id) as purchase_frequency
FROM customer_purchases
;



-- String manipulations
/* 
1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. 
*/

SELECT 
	*,	
	/*returns only the description part from the product_name column, 
		and if '-' DNE replace it with NULL value.*/
	CASE
		WHEN instr(product_name, '-') = 0 then NULL 
		ELSE trim(substr(product_name, instr(product_name, '-')+1))
	 END as description
FROM product
;


/* 
2. Filter the query to show any product_size value that contain a number with REGEXP. 
*/

-- only returns the records where the product_size column contain a number
SELECT * 
FROM product
WHERE product_size REGEXP '[0-9]'
;



-- UNION
/* 
1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. 
*/

--- method 1): using max() and min(), and combined with UNION
SELECT 
	market_date
	-- returns the lowest total sales
	,min(total_sales) as total_sales
FROM (
	-- returns a table which lists market_date and the associated total_sales
	SELECT  
		market_date
		,sum(quantity * cost_to_customer_per_qty) as total_sales
	FROM customer_purchases
	GROUP BY market_date
)

UNION -- append the lowest and highest total_sales together along with their market_date

SELECT 
	market_date
	-- returns the highest total sales
	,max(total_sales) as total_sales
FROM (
	-- returns a table which lists market_date and the associated total_sales
	SELECT 
		market_date
		,sum(quantity * cost_to_customer_per_qty) as total_sales
	FROM customer_purchases
	GROUP BY market_date
);


--- method 2): using row_number() / rank() / dense_rank() combined with UNION
-- returns the market_date with the highest total_sales
SELECT
	market_date
	,total_sales
FROM (
	-- returns a table which lists market_date and the associated total_sales, 
	--- in addition ordered by the descending rank of total_sales and a new ranking column
	SELECT 
		market_date
		,total_sales
		,row_number() OVER (ORDER BY total_sales DESC) as [best_day]
	FROM (
		-- returns a table which lists market_date and the associated total_sales
		SELECT  
			market_date
			,sum(quantity * cost_to_customer_per_qty) as total_sales
		FROM customer_purchases
		GROUP BY market_date
	) 
)y
WHERE y.best_day = 1 -- filter the highest total_sales

UNION -- append the highest and lowest total_sales together along with their market_date

-- returns the market_date with the lowest total_sales
SELECT
	market_date
	,total_sales
FROM (
	-- returns a table which lists market_date and the associated total_sales, 
	--- in addition ordered by the ascending rank of total_sales and a new ranking column
	SELECT 
		market_date
		,total_sales
		,row_number() OVER (ORDER BY total_sales ASC) as [worst_day]
	FROM (
		-- returns a table which lists market_date and the associated total_sales
		SELECT 
			market_date
			,sum(quantity * cost_to_customer_per_qty) as total_sales
		FROM customer_purchases
		GROUP BY market_date
	) 
)y
WHERE y.worst_day = 1 -- filter the lowest total_sales
;