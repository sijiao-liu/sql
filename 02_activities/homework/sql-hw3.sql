-- AGGREGATE
/* 1. Write a query that determines how many times each vendor has rented a booth 
at the farmer’s market by counting the vendor booth assignments per vendor_id. */


SELECT vendor_id, count(booth_number) as num_of_booth
FROM vendor_booth_assignments
GROUP BY vendor_id
;



/* 2. The Farmer’s Market Customer Appreciation Committee wants to give a bumper 
sticker to everyone who has ever spent more than $2000 at the market. Write a query that generates a list 
of customers for them to give stickers to, sorted by last name, then first name. 

HINT: This query requires you to join two tables, use an aggregate function, and use the HAVING keyword. */
   
   
--- method 1:
/*
-- returns a table consists consumer_id whose total expenditure is greater than $2000 at the market
SELECT 
	customer_id, 
	sum(quantity*cost_to_customer_per_qty) as total_expenditure
FROM customer_purchases
GROUP BY customer_id
HAVING total_expenditure > 2000
;
*/
-- join the above table with customer table to get customer's first and last name
SELECT 
	customer.customer_first_name as first_name,
	customer.customer_last_name as last_name
FROM (
	SELECT 
		customer_id, 
		sum(quantity*cost_to_customer_per_qty) as total_expenditure
	FROM customer_purchases
	GROUP BY customer_id
	HAVING total_expenditure > 2000
	) as expenditure
LEFT JOIN customer
	on expenditure.customer_id = customer.customer_id
ORDER BY last_name, first_name
;



--Temp Table
/* 1. Insert the original vendor table into a temp.new_vendor and then add a 10th vendor: 
Thomass Superfood Store, a Fresh Focused store, owned by Thomas Rosenthal

HINT: This is two total queries -- first create the table from the original, then insert the new 10th vendor. 
When inserting the new vendor, you need to appropriately align the columns to be inserted 
(there are five columns to be inserted, I've given you the details, but not the syntax) 

-> To insert the new row use VALUES, specifying the value you want for each column:
VALUES(col1,col2,col3,col4,col5) 
*/


-- Drop the temp.new_vendor table if it already exists
DROP TABLE IF EXISTS temp.new_vendor
;

-- Create a temporary table based on the original vendor table
CREATE TEMP TABLE IF NOT EXISTS temp.new_vendor AS
SELECT * FROM vendor
;

-- Insert the new 10th vendor into temp.new_vendor
INSERT INTO temp.new_vendor 
				(vendor_id, 
				 vendor_name, 
				 vendor_type, 
				 vendor_owner_first_name, 
				 vendor_owner_last_name)
VALUES (10, 
		'Thomass Superfood Store', 
		'Fresh Focused', 
		'Thomas', 
		'Rosenthal')
;

-- Call the table and check if the 10th vendor info added to the new_vendor table
SELECT * FROM new_vendor;



-- Date
/*1. Get the customer_id, month, and year (in separate columns) of every purchase in the customer_purchases table.

HINT: you might need to search for strfrtime modifers sqlite on the web to know what the modifers for month 
and year are! */


SELECT 
	customer_id,
	strftime('%m', market_date) as month,
	strftime('%Y', market_date) as year
FROM customer_purchases
;



/* 2. Using the previous query as a base, determine how much money each customer spent in April 2022. 
Remember that money spent is quantity*cost_to_customer_per_qty. 

HINTS: you will need to AGGREGATE, GROUP BY, and filter...
but remember, STRFTIME returns a STRING for your WHERE statement!! */


SELECT
	customer_id,
	strftime('%m', market_date) as month,
	strftime('%Y', market_date) as year,
	sum(quantity*cost_to_customer_per_qty) as total_expenditure
FROM customer_purchases
WHERE month = '04' and year = '2022'
GROUP BY customer_id, month, year
;

