CREATE TABLE airbnb_nyc (
    id INT,
    name VARCHAR(255),
    host_id INT,
    host_name VARCHAR(255),
    neighbourhood_group VARCHAR(50),
    neighbourhood VARCHAR(100),
    latitude DECIMAL(10,5),
    longitude DECIMAL(10,5),
    room_type VARCHAR(50),
    price INT,
    minimum_nights INT,
    number_of_reviews INT,
    last_review DATE NULL,
    reviews_per_month DECIMAL(5,2) NULL,
    calculated_host_listings_count INT,
    availability_365 INT,
    revenue_estimate INT
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/airbnb_cleaned_final.csv'
INTO TABLE airbnb_nyc
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

TRUNCATE TABLE airbnb_nyc;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/airbnb_cleaned_final.csv'
INTO TABLE airbnb_nyc
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, name, host_id, host_name, neighbourhood_group, neighbourhood, latitude, longitude,
 room_type, price, minimum_nights, number_of_reviews, @last_review, @reviews_per_month,
 calculated_host_listings_count, availability_365, revenue_estimate)
SET
  last_review = IF(@last_review = '', NULL, @last_review),
  reviews_per_month = IF(@reviews_per_month = '', NULL, @reviews_per_month);

-- Top Revenue by Borough
select neighbourhood_group, round(sum(revenue_estimate),0) as total_revenue
from airbnb_nyc
group by neighbourhood_group
order by total_revenue desc;

-- Average Price by Room Type
select room_type, round(avg(price),2) as avg_price
from airbnb_nyc
group by room_type
order by avg_price desc;

-- Top 10 Revenue Generating Neighborhoods
select neighbourhood, sum(revenue_estimate) as revenue
from airbnb_nyc
group by neighbourhood
order by revenue desc
limit 10;

-- Occupancy Analysis
select room_type, round(avg(365-availability_365),2) as occupied_days
from airbnb_nyc
group by room_type;

-- Revenue vs Reviews
select 
	case
		when number_of_reviews < 10 then "Low"
        when number_of_reviews < 50 then "Medium"
        when number_of_reviews = 0 then "No Review"
        else "High"
	end as review_group,
    round(avg(revenue_estimate),2) as avg_revenue
from airbnb_nyc
group by review_group;

-- Top Hosts within each Borough
with host_revenue as (
	select neighbourhood_group,
			host_name, 
            sum(revenue_estimate) as revenue,
            row_number() over(
				partition by neighbourhood_group
                order by sum(revenue_estimate) desc
			) as rn
	from airbnb_nyc
    group by neighbourhood_group, host_name
)

select *
from host_revenue
where rn <= 5;

-- Revenue Contribution %
select neighbourhood_group,
	sum(revenue_estimate) as revenue,
    round(
		sum(revenue_estimate) / 
        (select sum(revenue_estimate) 
        from airbnb_nyc) *100,
        2
	) as contribution_pct
from airbnb_nyc
group by neighbourhood_group;

select sum(revenue_estimate)
from airbnb_nyc;

select count(*)
from airbnb_nyc