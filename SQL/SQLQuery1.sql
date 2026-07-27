
-- QUERY 1: OUTLIER DETECTION & DATA QUALITY FLAGS
-- Purpose: Identify suspicious records before pricing models
-- Business Value: Prevent bad data from entering ML pipelines
WITH avg_price_per_sqm AS (
    SELECT AVG(price_doc / NULLIF(full_sq, 0)) * 5 AS threshold
    FROM clean_train
    WHERE full_sq > 0 AND price_doc > 0
)
SELECT 
    t.id,
    t.sub_area,
    t.full_sq,
    t.life_sq,
    t.kitch_sq,
    t.price_doc,
    t.num_room,
    t.build_year,
    t.kremlin_km,
    CASE 
        WHEN t.life_sq > t.full_sq THEN 'Life > Full Area'
        WHEN t.kitch_sq > t.full_sq * 0.5 THEN 'Kitchen Too Large'
        WHEN t.num_room > 5 AND t.full_sq < 50 THEN 'Too Many Rooms'
        WHEN t.price_doc / NULLIF(t.full_sq, 0) > a.threshold THEN 'Extreme Price/Sqm'
        WHEN t.build_year > YEAR(GETDATE()) THEN 'Future Build Year'
        WHEN t.build_year < 1800 THEN 'Suspicious Old Year'
        ELSE 'Valid'
    END AS data_quality_flag,
    CASE 
        WHEN t.life_sq > t.full_sq THEN 1
        WHEN t.kitch_sq > t.full_sq * 0.5 THEN 2
        WHEN t.num_room > 5 AND t.full_sq < 50 THEN 3
        WHEN t.price_doc / NULLIF(t.full_sq, 0) > a.threshold THEN 4
        WHEN t.build_year > YEAR(GETDATE()) THEN 5
        WHEN t.build_year < 1800 THEN 6
        ELSE 0
    END AS severity_score
FROM clean_Train t
CROSS JOIN avg_price_per_sqm a
WHERE 
    t.life_sq > t.full_sq
    OR t.kitch_sq > t.full_sq * 0.5
    OR (t.num_room > 5 AND t.full_sq < 50)
    OR (t.price_doc / NULLIF(t.full_sq, 0) > a.threshold)
    OR t.build_year > YEAR(GETDATE())
    OR t.build_year < 1800
ORDER BY severity_score DESC, price_doc DESC;


-- QUERY 2: REGIONAL PERFORMANCE WITH DENSE_RANK TIERS
-- Purpose: Classify districts into Premium/Standard/Affordable
-- Business Value: Pricing strategy & territory allocation
-- ============================================================
WITH area_metrics AS (
    SELECT 
        sub_area,
        COUNT(*) AS total_properties,
        ROUND(AVG(price_doc), 0) AS avg_price,
        ROUND(AVG(price_doc / NULLIF(full_sq, 0)), 0) AS price_per_sqm,
        ROUND(AVG(full_sq), 1) AS avg_area_sqm,
        ROUND(AVG(kremlin_km), 2) AS avg_dist_to_center
    FROM clean_train
    GROUP BY sub_area
    HAVING COUNT(*) > 50
)
SELECT 
    sub_area,
    total_properties,
    avg_price,
    price_per_sqm,
    avg_area_sqm,
    avg_dist_to_center,
    DENSE_RANK() OVER (ORDER BY price_per_sqm DESC) AS price_tier_rank,
    CASE 
        WHEN DENSE_RANK() OVER (ORDER BY price_per_sqm DESC) <= 5 THEN 'Tier 1 - Ultra Premium'
        WHEN DENSE_RANK() OVER (ORDER BY price_per_sqm DESC) <= 15 THEN 'Tier 2 - Premium'
        WHEN DENSE_RANK() OVER (ORDER BY price_per_sqm DESC) <= 30 THEN 'Tier 3 - Standard'
        ELSE 'Tier 4 - Affordable'
    END AS market_segment
FROM area_metrics
ORDER BY price_tier_rank;


-- QUERY 3: INVESTMENT VS OWNER-OCCUPIER COMPARISON
-- Purpose: Compare investment properties vs residential
-- Business Value: Portfolio targeting & product design

SELECT 
    product_type,
    COUNT(*) AS property_count,
    ROUND(AVG(price_doc), 0) AS avg_price,
    ROUND(AVG(full_sq), 1) AS avg_total_area,
    ROUND(AVG(life_sq), 1) AS avg_living_area,
    ROUND(AVG(price_doc / NULLIF(full_sq, 0)), 0) AS price_per_sqm,
    ROUND(AVG(num_room), 1) AS avg_rooms,
    ROUND(AVG(kremlin_km), 2) AS avg_dist_center,
    ROUND(AVG(metro_km_avto), 2) AS avg_dist_metro,
    ROUND(AVG(build_year), 0) AS avg_build_year
FROM clean_train
GROUP BY product_type
ORDER BY avg_price DESC;


-- QUERY 4: BUILDING ERA VALUE RANKING (DENSE_RANK)
-- Purpose: Understand which construction periods hold value
-- Business Value: Development strategy & renovation decisions
-- ============================================================
WITH build_eras AS (
    SELECT 
        CASE 
            WHEN build_year < 1950 THEN 'Pre-Soviet (<1950)'
            WHEN build_year < 1970 THEN 'Soviet Early (1950-1970)'
            WHEN build_year < 1990 THEN 'Soviet Late (1970-1990)'
            WHEN build_year < 2000 THEN 'Post-Soviet (1990-2000)'
            WHEN build_year < 2010 THEN 'Modern (2000-2010)'
            ELSE 'Contemporary (2010+)'
        END AS build_era,
        COUNT(*) AS units,
        AVG(price_doc) AS avg_price,
        AVG(price_doc / NULLIF(full_sq, 0)) AS avg_price_per_sqm,
        AVG(CASE WHEN build_year > 0 THEN (2024 - build_year) END) AS avg_age
    FROM clean_train
    WHERE build_year > 1800 AND build_year <= 2024
    GROUP BY 
        CASE 
            WHEN build_year < 1950 THEN 'Pre-Soviet (<1950)'
            WHEN build_year < 1970 THEN 'Soviet Early (1950-1970)'
            WHEN build_year < 1990 THEN 'Soviet Late (1970-1990)'
            WHEN build_year < 2000 THEN 'Post-Soviet (1990-2000)'
            WHEN build_year < 2010 THEN 'Modern (2000-2010)'
            ELSE 'Contemporary (2010+)'
        END
)
SELECT 
    build_era,
    units,
    ROUND(avg_price, 0) AS avg_price,
    ROUND(avg_price_per_sqm, 0) AS price_per_sqm,
    ROUND(avg_age, 0) AS avg_age_years,
    DENSE_RANK() OVER (ORDER BY avg_price_per_sqm DESC) AS era_value_rank,
    DENSE_RANK() OVER (ORDER BY units DESC) AS era_supply_rank,
    CASE 
        WHEN DENSE_RANK() OVER (ORDER BY avg_price_per_sqm DESC) <= 2 
             AND DENSE_RANK() OVER (ORDER BY avg_age ASC) <= 2
        THEN 'Star Era'
        WHEN DENSE_RANK() OVER (ORDER BY avg_price_per_sqm DESC) <= 3
        THEN 'Premium Era'
        ELSE 'Standard Era'
    END AS investment_grade
FROM build_eras
ORDER BY era_value_rank;


-- QUERY 5: DISTANCE DECAY ANALYSIS (Center Rings)
-- Purpose: Measure price drop by distance from Kremlin
-- Business Value: Land acquisition & location scoring
-- ============================================================
WITH distance_bands AS (
    SELECT 
        price_doc,
        full_sq,
        kremlin_km,
        mkad_km,
        ttk_km,
        CASE 
            WHEN kremlin_km < 3 THEN 'Core (0-3km)'
            WHEN kremlin_km < 7 THEN 'Inner (3-7km)'
            WHEN kremlin_km < 15 THEN 'Middle (7-15km)'
            ELSE 'Outer (>15km)'
        END AS distance_band
    FROM clean_train
)
SELECT 
    distance_band,
    COUNT(*) AS properties_count,
    ROUND(AVG(price_doc), 0) AS avg_price,
    ROUND(AVG(price_doc / NULLIF(full_sq, 0)), 0) AS price_per_sqm,
    ROUND(AVG(mkad_km), 1) AS avg_mkad_dist,
    ROUND(AVG(ttk_km), 1) AS avg_ttk_dist,
    ROUND(AVG(full_sq), 1) AS avg_area
FROM distance_bands
GROUP BY distance_band
ORDER BY avg_price DESC;


-- QUERY 6: INFRASTRUCTURE PREMIUM WITH DENSE_RANK
-- Purpose: Quantify impact of nearby amenities on pricing
-- Business Value: Amenities planning & valuation adjustment
-- ============================================================
WITH amenity_scored AS (
    SELECT 
        id,
        sub_area,
        price_doc,
        full_sq,
        kremlin_km,
        (COALESCE(cafe_count_500, 0) * 1 +
         COALESCE(sport_count_500, 0) * 2 +
         COALESCE(trc_count_500, 0) * 3 +
         COALESCE(office_count_500, 0) * 1 +
         CASE WHEN metro_km_walk < 1 THEN 10 
              WHEN metro_km_walk < 2 THEN 5 
              ELSE 0 
         END
        ) AS amenity_score
    FROM clean_train
)
SELECT 
    CASE 
        WHEN amenity_score >= 50 THEN 'Luxury Amenities'
        WHEN amenity_score >= 20 THEN 'High Amenities'
        WHEN amenity_score >= 10 THEN 'Standard Amenities'
        ELSE 'Basic Amenities'
    END AS amenity_class,
    COUNT(*) AS property_count,
    ROUND(AVG(price_doc), 0) AS avg_price,
    ROUND(AVG(price_doc / NULLIF(full_sq, 0)), 0) AS price_per_sqm,
    ROUND(AVG(kremlin_km), 2) AS avg_dist_center,
    ROUND(AVG(amenity_score), 1) AS avg_score,
    DENSE_RANK() OVER (ORDER BY AVG(price_doc / NULLIF(full_sq, 0)) DESC) AS value_rank
FROM amenity_scored
GROUP BY CASE 
        WHEN amenity_score >= 50 THEN 'Luxury Amenities'
        WHEN amenity_score >= 20 THEN 'High Amenities'
        WHEN amenity_score >= 10 THEN 'Standard Amenities'
        ELSE 'Basic Amenities'
    END
ORDER BY value_rank;


-- QUERY 7: METRO PROXIMITY RANKING BY PRICE SEGMENT (DENSE_RANK)
-- Purpose: Find best-connected properties within each price bracket
-- Business Value: Commuter-friendly investment targeting
-- ============================================================
WITH price_segments AS (
    SELECT 
        id,
        sub_area,
        metro_km_walk,
        price_doc,
        full_sq,
        NTILE(4) OVER (ORDER BY price_doc) AS price_quartile
    FROM clean_train
    WHERE metro_km_walk IS NOT NULL
)
SELECT top 50
    id,
    sub_area,
    price_doc,
    ROUND(metro_km_walk, 2) AS km_to_metro,
    price_quartile,
    DENSE_RANK() OVER (
        PARTITION BY price_quartile 
        ORDER BY metro_km_walk ASC
    ) AS metro_proximity_rank,
    CASE 
        WHEN metro_km_walk < 0.5 THEN 'Walking Distance'
        WHEN metro_km_walk < 1.5 THEN 'Short Commute'
        ELSE 'Requires Transport'
    END AS accessibility_tier
FROM price_segments
ORDER BY price_quartile, metro_proximity_rank

-- QUERY 8: MARKET GAP - HIGH POPULATION / LOW SUPPLY
-- Purpose: Identify underserved districts (Hidden Gems)
-- Business Value: New development & acquisition targets
-- ============================================================
WITH area_supply AS (
    SELECT 
        sub_area,
        COUNT(*) AS listed_properties,
        AVG(price_doc / NULLIF(full_sq, 0)) AS avg_price_per_sqm
    FROM clean_train
    GROUP BY sub_area
),
area_demand AS (
    SELECT 
        sub_area,
        MAX(raion_popul) AS population,
        MAX(office_raion) AS business_centers,
        MAX(shopping_centers_raion) AS retail_infrastructure
    FROM clean_train
    GROUP BY sub_area
)
SELECT TOP 20
    d.sub_area,
    d.population,
    s.listed_properties,
    ROUND(CAST(d.population AS NUMERIC) / NULLIF(s.listed_properties, 0), 0) AS people_per_listing,
    ROUND(s.avg_price_per_sqm, 0) AS avg_price_per_sqm,
    DENSE_RANK() OVER (ORDER BY CAST(d.population AS NUMERIC) / NULLIF(s.listed_properties, 0) DESC) AS demand_pressure_rank,
    DENSE_RANK() OVER (ORDER BY s.avg_price_per_sqm ASC) AS affordability_rank,
    CASE 
        WHEN d.population > 100000 AND s.listed_properties < 500 THEN 'Hidden Gem'
        WHEN d.population > 100000 AND s.listed_properties >= 500 THEN 'Balanced Market'
        ELSE 'Niche Market'
    END AS market_opportunity
FROM area_demand d
LEFT JOIN area_supply s ON d.sub_area = s.sub_area
ORDER BY demand_pressure_rank;

-- QUERY 9: BEST VALUE DEALS WITHIN SAME SPECIFICATIONS (DENSE_RANK)
-- Purpose: Find underpriced properties vs comparable units
-- Business Value: Deal sourcing & undervaluation alerts
-- ============================================================
WITH comparable_props AS (
    SELECT 
        id,
        sub_area,
        num_room,
        full_sq,
        price_doc,
        price_doc / NULLIF(full_sq, 0) AS price_per_sqm,
        kremlin_km
    FROM clean_train
    WHERE num_room BETWEEN 1 AND 4 
      AND full_sq BETWEEN 20 AND 150
      AND sub_area IN (
          SELECT sub_area 
          FROM clean_train 
          GROUP BY sub_area 
          HAVING COUNT(*) >= 20
      )
)
SELECT TOP 50
    id,
    sub_area,
    CAST(num_room AS VARCHAR(10)) + ' rooms' AS room_config,
    full_sq,
    price_doc,
    ROUND(price_per_sqm, 0) AS price_per_sqm,
    DENSE_RANK() OVER (
        PARTITION BY sub_area, num_room 
        ORDER BY price_per_sqm ASC
    ) AS value_rank_same_specs,
    DENSE_RANK() OVER (
        PARTITION BY sub_area 
        ORDER BY price_doc ASC
    ) AS overall_value_rank,
    CASE 
        WHEN DENSE_RANK() OVER (PARTITION BY sub_area, num_room ORDER BY price_per_sqm ASC) = 1
        THEN 'Best Deal'
        WHEN DENSE_RANK() OVER (PARTITION BY sub_area, num_room ORDER BY price_per_sqm ASC) <= 3
        THEN 'Good Value'
        ELSE 'Market Price'
    END AS deal_quality
FROM comparable_props
ORDER BY sub_area, room_config, value_rank_same_specs;


-- QUERY 10: INVESTMENT OPPORTUNITY - LOW PRICE + HIGH INFRASTRUCTURE
-- Purpose: Districts with good amenities but still affordable
-- Business Value: Value investing & early entry markets
-- ============================================================
WITH infra_score AS (
    SELECT 
        sub_area,
        AVG(price_doc / NULLIF(full_sq, 0)) AS avg_price_per_sqm,
        AVG(sport_count_500 + cafe_count_500 + trc_count_500) AS amenity_density,
        AVG(kremlin_km) AS avg_dist_center
    FROM clean_train
    GROUP BY sub_area
    HAVING COUNT(*) > 30
)
SELECT top 15
    sub_area,
    ROUND(avg_price_per_sqm, 0) AS price_per_sqm,
    ROUND(amenity_density, 1) AS amenity_score,
    DENSE_RANK() OVER (ORDER BY amenity_density DESC) AS infra_rank,
    DENSE_RANK() OVER (ORDER BY avg_price_per_sqm ASC) AS price_rank,
    (DENSE_RANK() OVER (ORDER BY amenity_density DESC) + 
     DENSE_RANK() OVER (ORDER BY avg_price_per_sqm ASC)) AS opportunity_score
FROM infra_score
WHERE avg_dist_center > 5
ORDER BY opportunity_score ASC


-- QUERY 11: PROPERTY RISK MATRIX (Age + Condition + Location)
-- Purpose: Segment portfolio by risk/quality profile
-- Business Value: Risk-weighted pricing & maintenance planning
-- ============================================================
WITH property_age AS (
    SELECT 
        *,
        (YEAR(GETDATE()) - build_year) AS building_age,
        CASE 
            WHEN state = 1 THEN 'Excellent'
            WHEN state = 2 THEN 'Good'
            WHEN state = 3 THEN 'Satisfactory'
            WHEN state = 4 THEN 'Poor'
            ELSE 'Unknown'
        END AS condition_status
    FROM clean_train
    WHERE build_year > 1800 
      AND build_year <= YEAR(GETDATE())
)
SELECT 
    condition_status,
    CASE 
        WHEN building_age < 10 THEN 'New'
        WHEN building_age < 30 THEN 'Modern'
        WHEN building_age < 60 THEN 'Old'
        ELSE 'Very Old'
    END AS age_category,
    COUNT(*) AS units,
    ROUND(AVG(price_doc), 0) AS avg_price,
    ROUND(AVG(building_age), 0) AS avg_age,
    ROUND(AVG(price_doc / NULLIF(full_sq, 0)), 0) AS price_per_sqm,
    ROUND(AVG(kremlin_km), 1) AS avg_distance_center,
    DENSE_RANK() OVER (ORDER BY AVG(price_doc / NULLIF(full_sq, 0)) DESC) AS value_rank
FROM property_age
GROUP BY condition_status, 
         CASE 
            WHEN building_age < 10 THEN 'New'
            WHEN building_age < 30 THEN 'Modern'
            WHEN building_age < 60 THEN 'Old'
            ELSE 'Very Old'
         END
ORDER BY 
    CASE condition_status 
        WHEN 'Excellent' THEN 1 
        WHEN 'Good' THEN 2 
        WHEN 'Satisfactory' THEN 3 
        WHEN 'Poor' THEN 4 
        ELSE 5 
    END,
    avg_price DESC;

-- QUERY 12: MACRO-ECONOMIC CORRELATION VIEW
-- Purpose: Link housing prices to economic indicators
-- Business Value: Market timing & forecasting inputs
-- ============================================================
WITH monthly_market AS (
    SELECT 
        DATEPART(MONTH, timestamp) AS month,
        AVG(price_doc) AS avg_price,
        AVG(price_doc / NULLIF(full_sq, 0)) AS avg_price_per_sqm,
        COUNT(*) AS transactions
    FROM clean_train
    GROUP BY DATEPART(MONTH, timestamp)
),
macro_monthly AS (
    SELECT 
        DATEPART(MONTH, timestamp) AS month,
        AVG(usdrub) AS avg_usd_rate,
        AVG(mortgage_rate) AS avg_mortgage_rate,
        AVG(salary) AS avg_salary,
        AVG(cpi) AS consumer_price_index,
        AVG(oil_urals) AS oil_price
    FROM Clean_Macro
    GROUP BY DATEPART(MONTH, timestamp)
)
SELECT 
    m.month,
    t.transactions,
    ROUND(t.avg_price, 0) AS avg_property_price,
    ROUND(t.avg_price_per_sqm, 0) AS avg_price_per_sqm,
    ROUND(m.avg_usd_rate, 2) AS usd_rate,
    ROUND(m.avg_mortgage_rate, 2) AS mortgage_rate_pct,
    ROUND(m.avg_salary, 0) AS avg_monthly_salary,
    ROUND(m.oil_price, 2) AS oil_price_urals,
    DENSE_RANK() OVER (ORDER BY t.avg_price_per_sqm DESC) AS price_rank,
    DENSE_RANK() OVER (ORDER BY m.avg_mortgage_rate DESC) AS credit_cost_rank
FROM monthly_market t
JOIN macro_monthly m ON t.month = m.month
ORDER BY m.month;

-- ============================================================
-- BONUS: SEASONAL TRANSACTION PATTERN
-- Purpose: Identify best months for buying/selling
-- Business Value: Campaign timing & liquidity planning
-- ============================================================
SELECT 
    datepart(MONTH FROM timestamp) AS month_num,
    FORMAT(timestamp, 'MMMM') AS month_name,
    COUNT(*) AS transactions,
    ROUND(AVG(price_doc), 0) AS avg_price,
    ROUND(AVG(price_doc / NULLIF(full_sq, 0)), 0) AS price_per_sqm,
    ROUND(AVG(num_room), 1) AS avg_rooms,
    ROUND(AVG(full_sq), 1) AS avg_area,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS liquidity_rank,
    DENSE_RANK() OVER (ORDER BY AVG(price_doc / NULLIF(full_sq, 0)) DESC) AS value_rank
FROM clean_train
GROUP BY datepart(MONTH FROM timestamp), FORMAT(timestamp, 'MMMM')
ORDER BY month_num;