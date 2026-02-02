-- Initial overview of all the data set
SELECT * 
FROM public.ecommerce
LIMIT 100;
-- From the intial overview irregularities in the cities formating, null values in store_id and customer_name.
-- store id has a series of float values. 




-- Checking initial null values
SELECT 
    COUNT(*) AS total_rows, 
	COUNT(order_id) AS non_null_orders,
	COUNT(customer_id) AS non_null_customer_id,
	COUNT(customer_name) AS non_null_customer_name,
	COUNT(city) AS non_null_city,
	COUNT(region) AS non_null_region,
	COUNT(product_id) AS non_null_product_id,
	COUNT(product_name) AS non_null_product_name,
	COUNT(product_category) AS non_null_product_category,
	COUNT(store_id) AS non_null_store_id,
	COUNT(order_date) AS non_null_order_date,
	COUNT(unit_price) AS non_null_unit_price,
	COUNT(quantity) AS non_null_quantity,
	COUNT(total_amount) AS non_null_total_amount
FROM public.ecommerce;

-- from the query above we identify the following columns with null values: customer_name, store_id

-- Now we are going to check for duplicates
-- Entire record duplicated
SELECT *
FROM (
     SELECT *,
            COUNT(*) OVER (
                  PARTITION BY order_id, customer_id, customer_name, city, region,
                               product_id, product_name, product_category,
                               store_id, order_date, unit_price, quantity, total_amount
	   ) AS duplicated_count
FROM public.ecommerce
)
WHERE  duplicated_count > 1;



-- Now that we have an overview of the dataset we will start the cleaning
CREATE VIEW ecommerce_cleaned AS
WITH 
-- Stage 1: In this stage we will standarize the text data
stage1_text_cleaned AS (
    SELECT 
	    order_id,
		customer_id,
		TRIM(customer_name) AS customer_name, -- Removing leading or trailing spaces
		INITCAP(TRIM(city)) AS city, -- Title case
		TRIM(region) AS region,
		product_id,
		TRIM(product_name) AS product_name,
		TRIM(product_category) AS product_category,
		NULLIF(store_id, 0)::INT AS store_id,
		order_date,
		unit_price,
		quantity,
		total_amount
	FROM 
	public.ecommerce	
),

-- Stage 2: Calculate correct amounts, fix store_id issues and date standarization
stage2_date_standarization AS (
    SELECT
        order_id,
        customer_id,
        customer_name,
        city,
        region,
        product_id,
        product_name,
        product_category,
        COALESCE(
            store_id,
            (SELECT store_id
             FROM stage1_text_cleaned
             WHERE store_id IS NOT NULL
             GROUP BY store_id
             ORDER BY COUNT(*) DESC
             LIMIT 1)
        ) AS store_id,
        order_date::timestamp AS order_date_parsed,
        unit_price,
        quantity,
        (unit_price * quantity) AS total_amount_calculated
    FROM stage1_text_cleaned
),


-- Stage 3: Date validation
stage3_datevalidation AS (
    SELECT * FROM stage2_date_standarization
    WHERE order_date_parsed IS NOT NULL
      AND order_date_parsed >= '2023-01-01'::TIMESTAMP
      AND order_date_parsed <= CURRENT_DATE
),

-- Stage 4: Filling missing customer names 
stage4_fill_names AS (
    SELECT
	    order_id,
		customer_id,
		COALESCE(
            NULLIF(TRIM(customer_name), ''),
			FIRST_VALUE(NULLIF(TRIM(customer_name), '')) OVER (
			PARTITION BY customer_id 
			ORDER BY order_date_parsed ASC, order_id ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			),
			'Unknown'
		) AS customer_name,
		city,
        region,
        product_id,
        product_name,
        product_category,
        store_id,
        order_date_parsed,
        unit_price,
        quantity,
        total_amount_calculated
    FROM stage3_datevalidation
),


-- Stage 5:Remove duplicates
stage5_deduplicates AS (
    SELECT 
	    order_id,
        customer_id,
        customer_name,
        city,
        region,
        product_id,
        product_name,
        product_category,
        store_id,
        order_date_parsed,
        unit_price,
        quantity,
        total_amount_calculated,
		-- Assigning a row number within each duplicate group
		ROW_NUMBER() OVER(
            PARTITION BY order_id, customer_id, product_id, order_date_parsed, store_id
			ORDER BY order_id
		) AS row_num
	FROM stage4_fill_names
), 

-- Stage 6: Filtering to only keep the first occurrence of duplicates
stage6_no_duplicates AS (
    SELECT order_id,
	       customer_id,
        customer_name,
        city,
        region,
        product_id,
        product_name,
        product_category,
        store_id,
        order_date_parsed,
        unit_price,
        quantity,
        total_amount_calculated 
		FROM stage5_deduplicates
		WHERE row_num = 1
),

-- Stage 7: Data quality score

stage7_quality_score AS (
    SELECT
        order_id,
        customer_id,
        customer_name,
        city,
        region,
        product_id,
        product_name,
        product_category,
        store_id,
        order_date_parsed,
        unit_price,
        quantity,
        total_amount_calculated,
        -- Calculate quality score (4 checks, each worth 0.25)
        ROUND(
            CAST(
                (CASE WHEN order_date_parsed IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN customer_name != 'Unknown' THEN 1 ELSE 0 END +
                 CASE WHEN city IS NOT NULL AND city != '' THEN 1 ELSE 0 END +
                 CASE WHEN total_amount_calculated = (unit_price * quantity) THEN 1 ELSE 0 END)
                AS NUMERIC
            ) / 4.0, 2
        ) AS data_quality_score
    FROM stage6_no_duplicates
)

-- Final output
SELECT
    order_id,
    customer_id,
    customer_name,
    city,
    region,
    product_id,
    product_name,
    product_category,
    store_id,
    order_date_parsed AS order_date,
    unit_price,
    quantity,
    total_amount_calculated,
	data_quality_score
FROM stage7_quality_score
ORDER BY order_id;



-- 1. Check NULL values
SELECT 
    'Column' AS check_type,
    'order_id' AS column_name, 
    COUNT(*) as null_count 
FROM ecommerce_cleaned WHERE order_id IS NULL
UNION ALL
SELECT 'Column', 'customer_id', COUNT(*) FROM ecommerce_cleaned WHERE customer_id IS NULL
UNION ALL
SELECT 'Column', 'customer_name', COUNT(*) FROM ecommerce_cleaned WHERE customer_name IS NULL
UNION ALL
SELECT 'Column', 'order_date', COUNT(*) FROM ecommerce_cleaned WHERE order_date IS NULL
UNION ALL
SELECT 'Column', 'total_amount', COUNT(*) FROM ecommerce_cleaned WHERE total_amount_calculated IS NULL;

-- 2. Check calculations 
SELECT 
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE total_amount_calculated = (unit_price * quantity)) as correct_calculations,
    COUNT(*) FILTER (WHERE total_amount_calculated != (unit_price * quantity)) as incorrect_calculations
FROM ecommerce_cleaned;

-- 3. Before and after comparison
SELECT 
    'Raw Data' as dataset,
	.
	.0
    COUNT(*) as total_rows,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT product_id) as unique_products,
    SUM(total_amount) as total_revenue,
    ROUND(AVG(total_amount), 2) as avg_order_value
FROM public.ecommerce
UNION ALL
SELECT 
    'Cleaned Data',
    COUNT(*),
    COUNT(DISTINCT customer_id),
    COUNT(DISTINCT product_id),
    SUM(total_amount_calculated),
    ROUND(AVG(total_amount_calculated), 2)
FROM ecommerce_cleaned;




---- Now that we have the dataset clean we'll start with our analysis


-- Dataset overview
WITH dataset_summary AS (
    SELECT 
        COUNT(*) AS total_records,
	    MIN(order_date) AS first_order,
	    MAX(order_date) AS latest_order,
	    COUNT(DISTINCT product_id) AS unique_products,
	    COUNT(DISTINCT customer_id) AS unique_customers,
	    SUM(total_amount_calculated) AS total_revenue
    FROM ecommerce_cleaned
)
SELECT * FROM dataset_summary 


-- Sales by category
SELECT 
    COUNT(*) AS total_orders,
	product_category,
	SUM(total_amount_calculated) AS total_revenue,
	ROUND(AVG(total_amount_calculated), 2) AS average_order_amount,
	ROUND(SUM(total_amount_calculated) * 100.0 / SUM(SUM(total_amount_calculated)) OVER(), 2) AS revenue_percentage
FROM ecommerce_cleaned
GROUP BY product_category
ORDER BY total_revenue DESC;



-- Analysis temporal patterns
SELECT 
    EXTRACT(MONTH FROM order_date) AS order_month,
	SUM(total_amount_calculated) AS total_revenue,
	COUNT(*) AS total_orders,
	ROUND(AVG(total_amount_calculated), 2) AS average_order_value,
	COUNT(DISTINCT customer_id) AS active_customers
FROM ecommerce_cleaned
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY order_month;

-- Customer segmentation
WITH customer_metrics AS (
        SELECT
		    customer_id,
			CURRENT_DATE - MAX(order_date)::date AS recency_days,
			COUNT(*) AS frequency,
			SUM(total_amount_calculated) AS monetary_value,
			ROUND(AVG(total_amount_calculated), 2) AS avg_purchase
		FROM ecommerce_cleaned
		GROUP BY customer_id
)
SELECT 
    CASE 
	    WHEN recency_days <= 30 AND frequency >= 5 THEN 'VIP'
		WHEN recency_days <= 60 AND frequency >= 3 THEN 'Loyal'
		WHEN recency_days <= 90 THEN 'Active'
		ELSE 'At risk'
	END AS customer_segment,
	COUNT(*) AS customer_count,
	ROUND(AVG(monetary_value), 2) as avg_lifetime_value
FROM customer_metrics
GROUP BY customer_segment;
			

-- Top products analysis
SELECT 
    product_id,
	product_name,
	COUNT(*) AS units_sold,
	SUM(total_amount_calculated) AS total_revenue,
	ROUND(AVG(total_amount_calculated), 2),
	RANK() OVER (ORDER BY SUM(total_amount_calculated) DESC) AS revenue_rank
FROM ecommerce_cleaned
GROUP BY product_id, product_name
ORDER BY total_revenue DESC
LIMIT 10;


-- Geographic distribution
SELECT 
    region,
	COUNT(DISTINCT customer_id) AS customers,
	COUNT(*) AS ORDERS,
	SUM(total_amount_calculated) AS total_revenue,
	ROUND(AVG(total_amount_calculated), 2),
	ROUND(SUM(total_amount_calculated) * 100.0 / SUM(SUM(total_amount_calculated)) OVER(), 2) AS market_share
FROM ecommerce_cleaned
GROUP BY region
ORDER BY total_revenue DESC;


-- Summary dashboard
WITH current_period AS (
    SELECT 
	    COUNT(*) AS orders,
		SUM(total_amount_calculated) AS revenue,
		COUNT(DISTINCT customer_id) AS customers
    FROM ecommerce_cleaned
	WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE)
),
previous_period AS (
    SELECT 
	    COUNT(*) AS orders,
		SUM(total_amount_calculated) AS revenue,
		COUNT(DISTINCT customer_id) AS customers
	FROM ecommerce_cleaned
	WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
	AND order_date < DATE_TRUNC('month', CURRENT_DATE)
)
SELECT 
    c.orders AS current_orders, 
	p.orders AS previous_orders,
	ROUND((c.orders - p.orders) * 100.0, 2) AS orders_growth_pct,
	c.revenue AS current_revenue,
	p.revenue AS previous_revenue,
	ROUND((c.revenue - p.revenue) * 100.0, 2) AS revenue_growth_pct,
	ROUND(c.revenue / c.customers, 2) AS revenue_per_customer
FROM current_period c, previous_period p;
	






