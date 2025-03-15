SELECT * FROM liocinema_db.subscribers;

-- Free to Basic Upgradedplanchange Count
select count(*) from liocinema_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan ="Basic"and plan_change_date <= '2024-11-30';-- 1399

-- Free to Premium Upgradedplanchange Count on Liocinema
select count(*) from liocinema_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan ="Premium" and plan_change_date <= '2024-11-30';-- 480

-- free to Paid Conversion count on Liocinema
select count(*) from liocinema_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan is not null and plan_change_date <= '2024-11-30';-- 1879

-- basic to premium upgraded count on Liocinema
select count(*) from liocinema_db.subscribers
where subscription_plan = 'Basic' and new_subscription_plan ="Premium" and plan_change_date <= '2024-11-30';-- 924

-- Free to Premium Upgradedplanchange Count on Jotstar
select count(*) from jotstar_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan ="Premium";-- 683

-- Free to VIP Upgradedplanchange Count on Jotstar
select count(*) from jotstar_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan ="VIP";-- 844

-- free to Paid Conversion count on jotstar
select count(*) from jotstar_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan is not null;-- 1527

select * from jotstar_db.subscribers
where subscription_plan = 'Free' and new_subscription_plan is not null;

update jotstar_db.subscribers
set new_subscription_plan = null
where  plan_change_date is null and new_subscription_plan is not null; 

-- counting paid count and percentage on each platform

select
((select count(*) from liocinema_db.subscribers
where new_subscription_plan ='Premium')
+
(select count(*) from liocinema_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "Premium"))/
(select count(*) from liocinema_db.subscribers );-- 16619--9.06%

select
((select count(*) from jotstar_db.subscribers
where new_subscription_plan ='Premium')
+
(select count(*) from jotstar_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "Premium"))/
(select count(*) from jotstar_db.subscribers );-- 16278--36.48%

select
((select count(*) from liocinema_db.subscribers
where new_subscription_plan ='Basic')
+
(select count(*) from liocinema_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "Basic"))/
(select count(*) from liocinema_db.subscribers );-- 46880--25.56%

select
((select count(*) from jotstar_db.subscribers
where new_subscription_plan ='VIP')
+
(select count(*) from jotstar_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "VIP"))/
(select count(*) from jotstar_db.subscribers );-- 15399--34.51%

------------------------------
-- Monthly Downgrad trend
SELECT 
    DATE_FORMAT(plan_change_date, '%m') AS month,  -- Use plan change date
    COUNT(*) AS downgrade_count
FROM jotstar_db.subscribers
WHERE 
    -- Downgrade conditions
    (
        (subscription_plan = 'Premium' AND new_subscription_plan IN ('VIP', 'Free'))
        OR
        (subscription_plan = 'VIP' AND new_subscription_plan = 'Free')
    ) 
GROUP BY month
ORDER BY month;

-- User status,Average watch time,count
SELECT 
    CASE 
        WHEN s.last_active_date <= '2024-11-30' THEN 'Inactive'
        ELSE 'Active' 
    END AS User_Status, 
    COUNT(s.user_id) AS User_Count, 
    AVG(COALESCE(w.total_watch_time_mins, 0)) AS Avg_Watch_Time, 
    SUM(COALESCE(w.total_watch_time_mins, 0)) / 60 AS Total_Watch_TimeHrs
FROM liocinema_db.subscribers s
LEFT JOIN liocinema_db.content_consumption w ON s.user_id = w.user_id
GROUP BY User_Status;

-- Revenue analysis 

select
((select count(*) from jotstar_db.subscribers
where new_subscription_plan ='Premium'and plan_change_date <= '2024-11-30' )
+
(select count(*) from jotstar_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "Premium"))*359;-- 5754770

select
((select count(*) from jotstar_db.subscribers
where new_subscription_plan ='VIP' and plan_change_date <= '2024-11-30')
+
(select count(*) from jotstar_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "VIP"))*159; -- 2426181

select
((select count(*) from liocinema_db.subscribers
where new_subscription_plan ='Basic' and plan_change_date <= '2024-11-30')
+
(select count(*) from liocinema_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "Basic"))*69;-- 3157923

select
((select count(*) from liocinema_db.subscribers
where new_subscription_plan ='Premium' and plan_change_date <= '2024-11-30')
+
(select count(*) from liocinema_db.subscribers
where new_subscription_plan is null and 
subscription_plan = "Premium"))*129;-- 2057034

--------------------------------------------------

-- Liocinema TotalRevenue 

WITH InitialPlan AS (
    SELECT
        user_id,
        subscription_plan,
        -- Active months for the initial plan
         floor(DATEDIFF(
            COALESCE(plan_change_date, last_active_date, '2024-11-30'), 
            subscription_date
        ) / 30 )+ 
        CASE 
            WHEN plan_change_date IS NULL THEN 1 -- Add 1 only if there is no plan change
            ELSE 0 
        END AS active_months_initial_plan
    FROM
        liocinema_db.subscribers
),
NewPlan AS (
    SELECT
        user_id,
        new_subscription_plan,
        -- Active months for the new plan (if plan changed)
        CASE
            WHEN plan_change_date IS NOT NULL AND plan_change_date<='2024-11-30' THEN  floor(DATEDIFF(
            COALESCE( last_active_date, '2024-11-30'), plan_change_date) / 30 )+ 1
            ELSE 0
        END AS active_months_new_plan
    FROM
        liocinema_db.subscribers
),
RevenueInitial AS (
    SELECT
        user_id,
        -- Revenue for the initial plan
        active_months_initial_plan *
        CASE
            WHEN subscription_plan = 'Basic' THEN 69
            WHEN subscription_plan = 'Premium' THEN 129
            ELSE 0
        END AS revenue_initial
    FROM
        InitialPlan
),
RevenueNew AS (
    SELECT
        user_id,
        -- Revenue for the new plan (if plan changed)
        active_months_new_plan *
        CASE
            WHEN new_subscription_plan = 'Basic' THEN 69
            WHEN new_subscription_plan = 'Premium' THEN 129
            ELSE 0
        END AS revenue_new
    FROM
        NewPlan
)
-- Total revenue across all users
SELECT
    SUM(COALESCE(RI.revenue_initial, 0)) + SUM(COALESCE(RN.revenue_new, 0)) AS Total_Revenue
FROM
    RevenueInitial RI
LEFT JOIN
    RevenueNew RN ON RI.user_id = RN.user_id;
----------------------------------------------------------

-- total revenue on jotstar

WITH InitialPlan AS (
    SELECT
        user_id,
        subscription_plan,
        -- Active months for the initial plan
         floor(DATEDIFF(
            COALESCE(plan_change_date, last_active_date, '2024-11-30'), 
            subscription_date
        ) / 30 )+ 
        CASE 
            WHEN plan_change_date IS NULL THEN 1 -- Add 1 only if there is no plan change
            ELSE 0 
        END AS active_months_initial_plan
    FROM
        jotstar_db.subscribers
),
NewPlan AS (
    SELECT
        user_id,
        new_subscription_plan,
        -- Active months for the new plan (if plan changed)
        CASE
            WHEN plan_change_date IS NOT NULL THEN  floor(DATEDIFF(
            COALESCE( last_active_date, '2024-11-30'), plan_change_date) / 30 )+ 1
            ELSE 0
        END AS active_months_new_plan
    FROM
        jotstar_db.subscribers
        where plan_change_date<='2024-11-30'
),
RevenueInitial AS (
    SELECT
        user_id,
        -- Revenue for the initial plan
        active_months_initial_plan *
        CASE
            WHEN subscription_plan = 'VIP' THEN 159
            WHEN subscription_plan = 'Premium' THEN 359
            ELSE 0
        END AS revenue_initial
    FROM
        InitialPlan
),
RevenueNew AS (
    SELECT
        user_id,
        -- Revenue for the new plan (if plan changed)
        active_months_new_plan *
        CASE
            WHEN new_subscription_plan = 'VIP' THEN 159
            WHEN new_subscription_plan = 'Premium' THEN 359
            ELSE 0
        END AS revenue_new
    FROM
        NewPlan
)
-- Total revenue across all users
SELECT
    SUM(COALESCE(RI.revenue_initial, 0)) + SUM(COALESCE(RN.revenue_new, 0)) AS Total_Revenue
FROM
    RevenueInitial RI
LEFT JOIN
    RevenueNew RN ON RI.user_id = RN.user_id;
------------------------------------------------------

SELECT COUNT(*) FROM liocinema_db.subscribers;

-- Downgrad rate per month(Jan- Nov) on liocinema
WITH MonthlyDowngrades AS (
    SELECT 
        DATE_FORMAT(plan_change_date, '%Y-%m') AS month,
        COUNT(user_id) AS downgraded_users
    FROM liocinema_db.subscribers
    WHERE plan_change_date IS NOT NULL
        AND plan_change_date < '2024-12-01'
        AND ((subscription_plan = 'Premium'or subscription_plan = 'Basic')
        AND (new_subscription_plan = 'Free') )or
        (subscription_plan = 'Premium' 
        AND new_subscription_plan = 'Basic')
    GROUP BY month
),
MonthlyPlanChanges AS (
    SELECT 
        DATE_FORMAT(plan_change_date, '%Y-%m') AS month,
        COUNT(user_id) AS total_plan_changes
    FROM liocinema_db.subscribers
    WHERE plan_change_date IS NOT NULL
        AND plan_change_date < '2024-12-01'
    GROUP BY month
)
SELECT 
    MD.month,
    MD.downgraded_users,
    MPC.total_plan_changes,
    ROUND((MD.downgraded_users * 100.0) / MPC.total_plan_changes, 2) AS downgrade_rate
FROM MonthlyDowngrades MD
JOIN MonthlyPlanChanges MPC ON MD.month = MPC.month
ORDER BY MD.month;
------------------------------------------------

SELECT COUNT(*) FROM jotstar_db.subscribers;

-- Downgrad rate per month(Jan- Nov) on Jotstar
WITH MonthlyDowngrades AS (
    SELECT 
        DATE_FORMAT(plan_change_date, '%Y-%m') AS month,
        COUNT(user_id) AS downgraded_users
    FROM jotstar_db.subscribers
    WHERE plan_change_date IS NOT NULL
        AND plan_change_date < '2024-12-01'
        AND ((subscription_plan = 'Premium'or subscription_plan = 'VIP')
        AND (new_subscription_plan = 'Free') )or
        (subscription_plan = 'Premium' 
        AND new_subscription_plan = 'VIP')
    GROUP BY month
),
MonthlyPlanChanges AS (
    SELECT 
        DATE_FORMAT(plan_change_date, '%Y-%m') AS month,
        COUNT(user_id) AS total_plan_changes
    FROM jotstar_db.subscribers
    WHERE plan_change_date IS NOT NULL
        AND plan_change_date < '2024-12-01'
    GROUP BY month
)
SELECT 
    MD.month,
    MD.downgraded_users,
    MPC.total_plan_changes,
    ROUND((MD.downgraded_users * 100.0) / MPC.total_plan_changes, 2) AS downgrade_rate
FROM MonthlyDowngrades MD
JOIN MonthlyPlanChanges MPC ON MD.month = MPC.month
ORDER BY MD.month;
----------------------------------

-- retention rate
WITH ActiveUsers AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS new_users
    FROM liocinema_db.subscribers
    WHERE subscription_date < '2024-12-01'
    GROUP BY month
),
ReturningUsers AS (
    SELECT 
        DATE_FORMAT(last_active_date, '%Y-%m') AS month,
        COUNT(user_id) AS returning_users
    FROM liocinema_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date >= DATE_SUB(last_active_date, INTERVAL 1 MONTH)
        AND last_active_date < '2024-12-01'
    GROUP BY month
)
SELECT 
    AU.month,
    AU.new_users,
    RU.returning_users,
    ROUND((RU.returning_users * 100.0) / NULLIF(AU.new_users, 0), 2) AS retention_rate
FROM ActiveUsers AU
LEFT JOIN ReturningUsers RU ON AU.month = RU.month
ORDER BY AU.month;
-------------------------------------------

-- churn_rate in Liocinema
WITH MonthlyChurn AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS churned_users
    FROM liocinema_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-9-30'
    GROUP BY month
),
ActiveSubscribers AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS active_users
    FROM liocinema_db.subscribers
    GROUP BY month
),
Free_Churned_users AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS Free_Churned
    FROM liocinema_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-09-30'
        AND subscription_plan = 'Free'  -- Correct filtering
    GROUP BY month
),
Premium_Churned_users AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS Premium_Churned
    FROM liocinema_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-09-30'
        AND subscription_plan = 'Premium'  -- Correct filtering
    GROUP BY month
),
Basic_Churned_users AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS Basic_Churned
    FROM liocinema_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-09-30'
        AND subscription_plan = 'Basic'  -- Correct filtering
    GROUP BY month
)
SELECT 
    MC.month,
    MC.churned_users,
    ASB.active_users,
    COALESCE(FCU.Free_Churned, 0) AS Free_Churned, -- Ensure NULLs are replaced with 0
	COALESCE(PCU.Premium_Churned, 0) AS Premium_Churned,
	COALESCE(BCU.Basic_Churned, 0) AS Basic_Churned,
    ROUND((MC.churned_users * 100.0) / NULLIF(ASB.active_users, 0), 2) AS churn_rate
FROM MonthlyChurn MC
JOIN ActiveSubscribers ASB ON MC.month = ASB.month
LEFT JOIN Free_Churned_users FCU ON MC.month = FCU.month
LEFT JOIN Premium_Churned_users PCU ON MC.month = PCU.month
LEFT JOIN Basic_Churned_users BCU ON MC.month = BCU.month-- Use LEFT JOIN to avoid missing data
ORDER BY MC.month;
-------------------------------------------

-- churned Users on Jotstar

WITH MonthlyChurn AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS churned_users
    FROM jotstar_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-9-30'
    GROUP BY month
),
ActiveSubscribers AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS active_users
    FROM jotstar_db.subscribers
    GROUP BY month
),
Free_Churned_users AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS Free_Churned
    FROM jotstar_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-09-30'
        AND subscription_plan = 'Free'  -- Correct filtering
    GROUP BY month
),
Premium_Churned_users AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS Premium_Churned
    FROM jotstar_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-09-30'
        AND subscription_plan = 'Premium'  -- Correct filtering
    GROUP BY month
),
Basic_Churned_users AS (
    SELECT 
        DATE_FORMAT(subscription_date, '%Y-%m') AS month,
        COUNT(user_id) AS Basic_Churned
    FROM jotstar_db.subscribers
    WHERE last_active_date IS NOT NULL
        AND last_active_date <= '2024-09-30'
        AND subscription_plan = 'Basic'  -- Correct filtering
    GROUP BY month
)
SELECT 
    MC.month,
    MC.churned_users,
    ASB.active_users,
    COALESCE(FCU.Free_Churned, 0) AS Free_Churned, -- Ensure NULLs are replaced with 0
	COALESCE(PCU.Premium_Churned, 0) AS Premium_Churned,
	COALESCE(BCU.Basic_Churned, 0) AS Basic_Churned,
    ROUND((MC.churned_users * 100.0) / NULLIF(ASB.active_users, 0), 2) AS churn_rate
FROM MonthlyChurn MC
JOIN ActiveSubscribers ASB ON MC.month = ASB.month
LEFT JOIN Free_Churned_users FCU ON MC.month = FCU.month
LEFT JOIN Premium_Churned_users PCU ON MC.month = PCU.month
LEFT JOIN Basic_Churned_users BCU ON MC.month = BCU.month-- Use LEFT JOIN to avoid missing data
ORDER BY MC.month;
--------------------------------------------------------------------------

select count(*) from liocinema_db.subscribers where subscription_plan ="Free";
select count(*) from liocinema_db.subscribers where subscription_plan ="Free" and 
(new_subscription_plan="Basic" or new_subscription_plan="Premium");
select count(*) from jotstar_db.subscribers where subscription_plan ="Free";
select count(*) from jotstar_db.subscribers where subscription_plan ="Free" and 
(new_subscription_plan="VIP" or new_subscription_plan="Premium");