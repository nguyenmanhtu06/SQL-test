--PART 1
--1. Show list of transactions occurring in February 2018 with SHIPPED status
SELECT order_id
FROM (
    SELECT order_id, transaction_date
    FROM transactions
    WHERE status = 'SHIPPED'
) AS x
WHERE (transaction_date >= '2018-02-01' AND transaction_date <= '2018-02-28');

--2. Show list of transactions occurring from midnight to 9 AM
SELECT order_id
FROM transactions
WHERE CAST(transaction_date AS TIME) BETWEEN '00:00:00.000' AND '09:00:00.000';

--3. Show a list of only the last transactions from each vendor
SELECT order_id, vendor
FROM (
    SELECT order_id, vendor, transaction_date,
    ROW_NUMBER() OVER (PARTITION BY vendor ORDER BY transaction_date DESC) AS rankdate
    FROM transactions
) AS x
WHERE rankdate = 1;

--4. Show a list of only the second last transactions from each vendor
SELECT order_id, vendor
FROM (
    SELECT order_id, vendor, transaction_date,
    ROW_NUMBER() OVER (PARTITION BY vendor ORDER BY transaction_date DESC) AS rankdate
    FROM transactions
) AS x
WHERE rankdate = 2;

--5. Count the transactions from each vendor with the status CANCELLED per day
SELECT order_id, transaction_date, COUNT(*) AS no_count
FROM transactions
WHERE status = 'CANCELLED'
GROUP BY order_id, transaction_date;

--6. Show a list of customers who made more than 1 SHIPPED purchases
SELECT customer_id
FROM (
    SELECT customer_id, status, COUNT(*) AS no_count
    FROM transactions
    WHERE status = 'SHIPPED'
    GROUP BY customer_id, status
) AS CTE
WHERE no_count > 1;

--7. Show the total transactions (volume) and category of each vendor
WITH CTE AS (
    SELECT vendor,
    SUM(CASE WHEN status = 'SHIPPED' THEN 1 ELSE 0 END) AS status_shipped,
    SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) AS status_cancelled
    FROM transactions
    GROUP BY vendor
),
CTE2 AS (
    SELECT vendor, 'Superb' AS Category, status_shipped AS Total_Transaction
    FROM CTE
    WHERE status_shipped > 2 AND status_cancelled = 0
    UNION
    SELECT vendor, 'Good' AS Category, status_shipped AS Total_Transaction
    FROM CTE
    WHERE status_shipped > 2 AND status_cancelled > 0
)
SELECT * FROM CTE2
UNION
SELECT vendor, 'Normal' AS Category, status_shipped AS Total_Transaction
FROM CTE
WHERE vendor NOT IN (SELECT vendor FROM CTE2);

--8. Group the transactions by hour of transaction_date
SELECT HOUR(transaction_date) AS Hour_of_the_Day, SUM(CASE WHEN status = 'SHIPPED' THEN 1 ELSE 0 END) AS Total_Transaction
FROM transactions
GROUP BY Hour_of_the_Day;

--9. Group the transactions by day and statuses
SELECT DATE(transaction_date) AS Date,
SUM(CASE WHEN status = 'SHIPPED' THEN 1 ELSE 0 END) AS SHIPPED,
SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED,
SUM(CASE WHEN status = 'PROCESSING' THEN 1 ELSE 0 END) AS PROCESSING
FROM transactions
GROUP BY Date;

--10. Calculate the average, minimum and maximum of days interval of each transaction
WITH CTE AS (
    SELECT DATE(transaction_date) AS Date
    FROM transactions
    GROUP BY DATE(transaction_date)
),
CTE2 AS (
    SELECT Date, DATEDIFF(Date, LAG(Date) OVER (ORDER BY Date), Date) AS Interval
    FROM CTE
)
SELECT AVG(Interval) AS `Average Interval`, MIN(Interval) AS `Minimum Interval`, MAX(Interval) AS `Maximum Interval`
FROM CTE2;


-- PART 2
-- 1. Show the sum of the total value of the products shipped along with the Distributor Commissions
-- (2% of the total product value if total quantity is 100 or less, 4% of the total product value if total quantity sold is more than 100)
WITH CTE AS (
    SELECT product_name, quantity, quantity * price AS Value
    FROM transaction_details
    WHERE trx_id IN (
        SELECT Id
        FROM transactions
        WHERE status = 'SHIPPED'
    )
)
SELECT product_name, SUM(Value) AS Value_quantity_x_price,
    SUM(Value) * CASE WHEN SUM(quantity) <= 100 THEN 0.02 ELSE 0.04 END AS Distributor_Commission
FROM CTE
GROUP BY product_name;

-- 2. Show total quantity of “Indomie (all variant)” shipped within February 2018
SELECT SUM(quantity) AS total_quantity
FROM transaction_details
WHERE trx_id IN (
    SELECT Id
    FROM transactions
    WHERE status = 'SHIPPED' AND (transaction_date >= '2018-02-01' AND transaction_date <= '2018-02-28')
)
AND product_name LIKE 'Indomie%';

-- 3. For each product, show the ID of the last transaction which contained that particular product
SELECT product_name AS Product_Name, trx_id AS Last_Transaction_ID
FROM (
    SELECT td.product_name, td.trx_id, t.transaction_date,
    ROW_NUMBER() OVER (PARTITION BY td.product_name ORDER BY t.transaction_date DESC) AS row_no
    FROM transaction_details td
    LEFT JOIN transactions t ON td.trx_id = t.ID
) AS x
WHERE row_no = 1;
