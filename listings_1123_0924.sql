USE real_estate_data;

-- Creating table for listing data

CREATE TABLE listings (
	pic_count int,
    mls_number int,
    type VARCHAR(255),
    status BOOL,
    address VARCHAR(255),
    unit VARCHAR(255),
    zip int,
    living_sqft int,
    br int,
    fb int,
    hb int,
    price int,
    year_built int,
    dom int,
    cdom int,
    office VARCHAR(255)
);

-- Uploading listing data using data import Wizard. This data includes total residential listings 
-- in Escambia & Santa Rosa counties between 11/12/23 to 9/1/24, excludes boat slips and lots, $100k+.
-- Specified list data, so homes could have closed or gone under contract after 9/1 and still be included.
-- Boolean status variable, 1 for sold & 0 for not sold.

-- Viewing all to ensure import was successful

SELECT *
FROM listings;

-- Data Exploration

-- Checking for null values

SELECT *
FROM listings
WHERE pic_count IS NULL
OR mls_number IS NULL
OR type IS NULL
OR status IS NULL
OR address IS NULL
OR unit IS NULL
OR zip IS NULL
OR living_sqft IS NULL
OR br IS NULL
OR fb IS NULL
OR hb IS NULL
OR price IS NULL
OR year_built IS NULL
OR dom IS NULL
OR cdom IS NULL
OR office IS NULL;
-- No null values present


-- Viewing minimum and maximum values

select 
MAX(dom),
MIN(dom),
MAX(cdom),
MIN(cdom),
MAX(living_sqft),
MIN(living_sqft),
MAX(price)
FROM listings;
-- minimums are all realistic, price is realistic, but clearly there are some extreme outliers for days on market and living sqft. 

-- Creating quartiles for living_sqft

WITH quartile_data AS (
	SELECT living_sqft,
		NTILE(4) OVER (ORDER BY living_sqft) as quartile
	FROM listings
)
SELECT
	MAX(CASE WHEN quartile = 1 THEN living_sqft END) AS Q1,
    MAX(CASE WHEN quartile = 2 THEN living_sqft END) AS Q2,
    MAX(CASE WHEN quartile = 3 THEN living_sqft END) AS Q3,
    MAX(CASE WHEN quartile = 4 THEN living_sqft END) AS Q4
FROM quartile_data;

-- manually analyzing living_sqft

SELECT 
COUNT(living_sqft)
FROM listings
WHERE living_sqft > 7000;

SELECT 
living_sqft,
address
FROM listings
WHERE living_sqft > 7000;

-- deleting records with living_sqft > 7000. There are 6 listings that fit this criteria and they include abandoned schools, churches, and large mansions. 
-- while they are legitamate they are an outlier that could affect analysis. 

-- Disabling safe update mode
SELECT @@sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM 
listings
WHERE living_sqft > 7000;

-- Creating quartiles for dom

WITH quartile_data AS (
	SELECT dom,
		NTILE(4) OVER (ORDER BY dom) as quartile
	FROM listings
)
SELECT
	MAX(CASE WHEN quartile = 1 THEN dom END) AS Q1,
    MAX(CASE WHEN quartile = 2 THEN dom END) AS Q2,
    MAX(CASE WHEN quartile = 3 THEN dom END) AS Q3,
    MAX(CASE WHEN quartile = 4 THEN dom END) AS Q4
FROM quartile_data;
-- Q1: 13 Q2: 54 Q3: 128 Q4: 7361

SELECT 
COUNT(dom)
FROM listings
WHERE dom > 500;

SELECT 
dom,
address
FROM listings
WHERE dom > 500;
-- there are 3 outliers for dom with the listing going from 523 to 3694, 7361, 7306. Will delete 3000+ dom

DELETE FROM 
listings
WHERE dom > 3000;

-- turning safe update mode back on

SELECT @@sql_safe_updates;
SET SQL_SAFE_UPDATES = 1;

-- Calculating sold rate

SELECT 
sld_count / total_count AS sld_ratio,
notsld_count /total_count AS notsld_ratio
from (
	SELECT
		COUNT(status) AS total_count,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS sld_count,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS notsld_count
	FROM listings
) AS counts;
-- For all listings, 0.7062 or 70.62% sold, 0.2938 or 29.38% did not sell

-- sold rate for $100k - $250k

SELECT 
sld_count / total_count AS sld_ratio,
notsld_count /total_count AS notsld_ratio,
total_count
from (
	SELECT
		COUNT(status) AS total_count,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS sld_count,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS notsld_count
	FROM listings
    WHERE price >= 100000 AND price < 250000
) AS counts;
-- $100k - $250k: sold ratio - 0.7171, number of listings - 2467

-- sold rate for $250k - $500k

SELECT 
sld_count / total_count AS sld_ratio,
notsld_count /total_count AS notsld_ratio,
total_count
from (
	SELECT
		COUNT(status) AS total_count,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS sld_count,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS notsld_count
	FROM listings
    WHERE price >= 250000 AND price < 500000
) AS counts;
-- $250k - $500k: sold ratio - 0.7379, number of listings - 5608

-- sold rate for $500k - $750k

SELECT 
sld_count / total_count AS sld_ratio,
notsld_count /total_count AS notsld_ratio,
total_count
from (
	SELECT
		COUNT(status) AS total_count,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS sld_count,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS notsld_count
	FROM listings
    WHERE price >= 500000 AND price < 750000
) AS counts;
-- $500k - $750k: sold ratio - 0.6471, number of listings - 1159

-- sold rate for $750k+

SELECT 
sld_count / total_count AS sld_ratio,
notsld_count /total_count AS notsld_ratio,
total_count
from (
	SELECT
		COUNT(status) AS total_count,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS sld_count,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS notsld_count
	FROM listings
    WHERE price >= 750000
) AS counts;
-- $750k+: sold ratio - 0.5293, number of listings - 752

-- All price ranges:
-- $100k - $250k: sold ratio - 0.7171, number of listings - 2467
-- $250k - $500k: sold ratio - 0.7379, number of listings - 5608
-- $500k - $750k: sold ratio - 0.6471, number of listings - 1159
-- $750k+: sold ratio - 0.5293, number of listings - 752

-- Create price category column

ALTER TABLE listings
ADD COLUMN price_category VARCHAR(50);

UPDATE listings
SET price_category =
	CASE
		WHEN price >= 100000 AND price < 250000 THEN "100k-250k"
        WHEN price >= 250000 AND price < 500000 THEN '250k-500k'
        WHEN price >= 500000 AND price < 750000 THEN '500k-750k'
        WHEN price >= 750000 THEN '750k+'
	END;
  
-- Checking that column was created correctly

SELECT price_category
FROM listings
WHERE price_category = "500k-750k";

SELECT 
COUNT(price_category),
price_category
FROM listings
GROUP BY price_category;

-- Extracting data to upload to Tableau

SELECT *
FROM listings
LIMIT 10000;

commit;









