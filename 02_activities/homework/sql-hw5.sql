-- Cross Join
/*
1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  
*/

SELECT -- only select the relevant columns and rows
	v.vendor_name
	,p.product_name
	,y.total_sales_per_product
FROM (
	-- return for the unique (pair of vendor_id, product_id) along with summing sales_per_product for all customers 
	SELECT 
		x.vendor_id
		,x.product_id
		,sum(sales_per_product) as total_sales_per_product -- each vendor's sales per product for all customers
	FROM (
			-- return records with unique pair of (vendor_id, product_id, customer_id) 
			--- with the sales_per_product per customer
			SELECT DISTINCT -- select records with unique pair of (vendor_id, product_id)
				vi.vendor_id
				,vi.product_id
				,vi.original_price * 5 as sales_per_product -- each vendor sells 5 of each their product to each customer
				,c.customer_id
			FROM vendor_inventory as vi
			-- cross join the unique pair of (vendor_id, product_id) and sales_per_product with the customer table
			CROSS JOIN  customer as c 
	) x
	GROUP BY vendor_id, product_id
) y

-- left join the above table with the product table in order to use product_name instead product_id
LEFT JOIN product p
	on y.product_id = p.product_id

-- left join the above table with the vendor table in order to use vendor_name instead vendor_id
LEFT JOIN vendor v
	on y.vendor_id = v.vendor_id
	
ORDER BY vendor_name, product_name, total_sales_per_product -- for the final table's readability 
;



-- INSERT
/*
1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. 
*/

-- create a new table product_units from product
DROP TABLE IF EXISTS product_units;
CREATE TABLE IF NOT EXISTS product_units AS
SELECT 
    -- select all columns from product table
	*, 
	-- includes the new CURRENT_TIMESTAMP column
    CURRENT_TIMESTAMP AS snapshot_timestamp  
FROM product
WHERE product_qty_type = 'unit' -- only returns the products which product_qty_type is 'unit'
;

-- call the new table created to see if above query returns the desired table
SELECT * FROM product_units;


/*
2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). 
*/

-- insert a new record to the temp table product_units
INSERT INTO product_units 
				-- this is not necessary to have, but good to have, 
				--- with this, I can make sure that the values inserted correctly
				(
					product_id, 
					product_name, 
					product_size,
					product_category_id,
					product_qty_type,
					snapshot_timestamp					
				) 
VALUES (101, 'Apple Pie', '8"', 3, 'unit', CURRENT_TIMESTAMP);

-- call the table see if the new row inserted exists 
SELECT * FROM product_units;



-- DELETE
/* 
1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.
*/

-- delete a record from the temp table product_units
DELETE FROM product_units
-- only delete the product just added, in this case, Apple Pie; 
--- and select the oldest record for the product just added to delete
WHERE product_name = 'Apple Pie' 
	AND snapshot_timestamp = (
								-- make sure when delete the record, 
								--- neither the newer records nor all records of the product is deleted
								SELECT MIN(snapshot_timestamp) -- only returns the oldest snapshot_time
								FROM product_units 
								WHERE product_name = 'Apple Pie'
							 ) 
;

-- call the table see if the row deleted still exists 
SELECT * FROM product_units;



-- UPDATE
/* 
1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.
	ALTER TABLE product_units
	ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
	First, determine how to get the "last" quantity per product. 
	Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
	Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
	Finally, make sure you have a WHERE statement to update the right row, 
		you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
	When you have all of these components, you can run the update statement. 
*/

-- add a new column - current_quantity to the table product_units
ALTER TABLE product_units
ADD current_quantity INT;

-- call the table product_units see if the new empty column inserted exists 
SELECT * FROM product_units;

--- method 1): using max() to return "last" quantity per product
UPDATE product_units
SET current_quantity = (-- set current_quantity equals to last_quantity
						SELECT last_quantity
						FROM (
								-- returns a table include the list of product and their last_quantity,
								--- and if the last_quantity is NULL, replace it with 0
								SELECT pu.product_id, coalesce(lq.last_quantity, 0) as last_quantity
								FROM product_units pu 
								LEFT JOIN (
											-- returns the last_quantity per product_id
											SELECT product_id, quantity as last_quantity, MAX(market_date)
											FROM vendor_inventory
											GROUP BY product_id
										  ) lq 
								on pu.product_id = lq.product_id
							) x
						-- make sure the product_id's match for the tables involved
						where product_units.product_id = x.product_id 
						)
;


--- method 2): using dense_rank() to return "last" quantity per product
UPDATE product_units
SET current_quantity = (-- set current_quantity equals to last_quantity
						SELECT current_quantity 
						FROM (
								-- returns a table include the list of product and their last_quantity,
								--- and if the last_quantity is NULL, replace it with 0
								SELECT  pu.product_id, coalesce(quantity,0) as current_quantity
								FROM product_units pu
								LEFT JOIN (
											-- returns the last_quantity per product_id
											SELECT *
											,dense_rank() OVER( PARTITION BY vi.product_id ORDER BY market_date DESC) AS rn
											FROM vendor_inventory vi 
										  ) vi 
								on pu.product_id  = vi.product_id
								WHERE rn = 1 OR rn IS NULL
								) x
						-- make sure the product_id's match for the tables involved
						WHERE product_units.product_id = x.product_id
						)
;

-- call the temp table product_units see if the new column inserted exists 
SELECT * FROM product_units;


