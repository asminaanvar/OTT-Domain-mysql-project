SELECT * FROM jotstar_db.subscribers;

SELECT * FROM liocinema_db.subscribers
where new_subscription_plan is null and last_active_date is not null;


select * from liocinema_db.subscribers
where new_subscription_plan IS NULL AND last_active_date < '2024-08-31';


select * from liocinema_db.subscribers
where last_active_date is null and new_subscription_plan is null;

select count(*) from liocinema_db.subscribers
where new_subscription_plan IS NULL AND last_active_date >='2024-08-31';

select count(*) from liocinema_db.subscribers
where last_active_date is not null and new_subscription_plan is null;


select * from liocinema_db.subscribers
where new_subscription_plan is null;

-- check for duplicate on liocinema

SELECT user_id, COUNT(*) AS duplicates 
FROM liocinema_db.subscribers  
GROUP BY user_id  
HAVING COUNT(*) > 1;

SELECT user_id, COUNT(*) AS duplicates2
FROM liocinema_db.content_consumption  
GROUP BY user_id  
HAVING COUNT(*) > 1;

SELECT content_id, COUNT(*) AS duplicates2
FROM liocinema_db.contents
GROUP BY content_id
HAVING COUNT(*) > 1;

-- create a new table for pricing on each platform 

use liocinema_db;
create table platform (
subscription_plan varchar (100),
price int);

insert into platform(subscription_plan,price)
values('Basic',69),('Premium',129);
select count(*) from liocinema_db.subscribers;


-- jotstar_db update


select * from jotstar_db.subscribers;

select * from jotstar_db.subscribers
where last_active_date is not null ;



select * from jotstar_db.subscribers
where last_active_date is null and new_subscription_plan is not null ;

select * from jotstar_db.subscribers
where last_active_date is null;

-- user is still active and no new plan is set, assume they are on their current plan
UPDATE jotstar_db.subscribers  
SET new_subscription_plan = subscription_plan  
WHERE new_subscription_plan IS NULL AND last_active_date IS NULL;

select * from jotstar_db.subscribers
where last_active_date is null and new_subscription_plan is null ;

select * from jotstar_db.subscribers
where new_subscription_plan IS NULL AND last_active_date < '2024-08-31';


select count(*) from jotstar_db.subscribers
where new_subscription_plan IS NULL AND last_active_date >='2024-08-31';

select count(*) from jotstar_db.subscribers
where last_active_date is not null and new_subscription_plan is null;

-- If they had a plan(after august) but now it's NULL,assumme thier subscription plan is not ended 
UPDATE jotstar_db.subscribers  
SET new_subscription_plan =  subscription_plan
where last_active_date is not null and new_subscription_plan is null;

-- check for duplicate on jotstar

SELECT user_id, COUNT(*) AS duplicates 
FROM jotstar_db.subscribers  
GROUP BY user_id  
HAVING COUNT(*) > 1;

SELECT user_id, COUNT(*) AS duplicates2
FROM jotstar_db.content_consumption  
GROUP BY user_id  
HAVING COUNT(*) > 1;

SELECT content_id, COUNT(*) AS duplicates3
FROM jotstar_db.contents
GROUP BY content_id
HAVING COUNT(*) > 1;

SELECT s.*
FROM jotstar_db.subscribers s 
LEFT JOIN liocinema_db.content_consumption c ON s.user_id = c.user_id 
WHERE c.user_id IS NULL;

SELECT count(*) 
FROM jotstar_db.subscribers s 
LEFT JOIN liocinema_db.content_consumption c ON s.user_id = c.user_id 
WHERE c.user_id IS NULL;

-- check for null values

select * from jotstar_db.content_consumption
where  total_watch_time_mins is null; 

-- To find userid which has no content consumption data

SELECT s.user_id, s.subscription_date, s.last_active_date,c.*
FROM jotstar_db.subscribers s
LEFT JOIN liocinema_db.content_consumption c ON s.user_id = c.user_id
WHERE c.user_id IS NULL;

update jotstar_db.subscribers
set new_subscription_plan = null
where  plan_change_date is null and new_subscription_plan is not null; 

select * from jotstar_db.subscribers
where subscription_date<2024-11-30;

select * from jotstar_db.subscribers
where last_active_date<2024-11-30;

use jotstar_db;
create table platform (
subscription_plan varchar (100),
price int);

insert into platform(subscription_plan,price)
values('VIP',159),('Premium',359);

-- Paid users count on liocinema 

SELECT 
    (SELECT COUNT(*) 
     FROM liocinema_db.subscribers
     WHERE new_subscription_plan IS NOT NULL 
     AND new_subscription_plan NOT IN ('Free')) 
    +
    (SELECT COUNT(*) 
     FROM liocinema_db.subscribers 
     WHERE new_subscription_plan IS NULL 
     AND subscription_plan NOT IN ('Free')) 
    AS PaidUserCount;
    
select count(*) from liocinema_db.contents;

-- Active Users

SELECT 
    (SELECT COUNT(*) 
     FROM liocinema_db.subscribers
     WHERE last_active_date IS NULL) 
    +
    (SELECT COUNT(*) 
     FROM liocinema_db.subscribers
     WHERE last_active_date > '2024-11-30') 
    AS active;
        
-- Upgraded Users Count in liocinema 

SELECT new_subscription_plan, COUNT(*) 
FROM liocinema_db.subscribers
WHERE (subscription_plan = "Free" AND new_subscription_plan IN ("Basic", "Premium"))
   OR (subscription_plan = "Basic" AND new_subscription_plan = "Premium")
GROUP BY new_subscription_plan;

-- Downgraded users in liocinema

select count(*)
    from liocinema_db.subscribers
    where (subscription_plan ="Premium" and new_subscription_plan in("Basic",'Free')) 
    or(subscription_plan = "Basic" and new_subscription_plan = "Free");
    
select count(*) from jotstar_db.subscribers;

ALTER TABLE jotstar_db.platform 
ADD COLUMN platform_name varchar(50);

update jotstar_db.platform
set platform_name = "jotstar"
where platform_name is null;

insert into jotstar_db.platform (subscription_plan,price,platform_name)
values("Basic",69,"liocinema"),
("Premium",129,"liocinema");

select * from jotstar_db.platform;

SELECT DISTINCT subscription_plan,price, platform_name  
FROM jotstar_db.platform  
WHERE platform_name = 'liocinema'  

UNION ALL  

SELECT subscription_plan, price,platform_name  
FROM jotstar_db.platform
WHERE platform_name = 'jotstar';


DELETE FROM jotstar_db.platform 
WHERE id NOT IN (  
    SELECT MIN(id)  
    FROM jotstar_db.subscribers  
    GROUP BY subscription_plan, price, platform_name  
);

-- Month to month growth
SELECT 
    CURRENT_MONTH.Month AS Month,
    CURRENT_MONTH.UserCount AS CurrentMonthUsers,
    PREVIOUS_MONTH.UserCount AS PreviousMonthUsers,
    CASE 
        WHEN PREVIOUS_MONTH.UserCount > 0 
        THEN (CURRENT_MONTH.UserCount - PREVIOUS_MONTH.UserCount) / PREVIOUS_MONTH.UserCount * 100
        ELSE 0 
    END AS MoM_Growth_Percentage
FROM 
    (SELECT 
        EXTRACT(MONTH FROM subscription_date) AS Month,
        COUNT(user_id) AS UserCount
    FROM liocinema_db.subscribers
    WHERE subscription_date >= '2024-01-01' AND subscription_date <= '2024-11-30'
    GROUP BY EXTRACT(MONTH FROM subscription_date)) AS CURRENT_MONTH
LEFT JOIN
    (SELECT 
        EXTRACT(MONTH FROM subscription_date) AS Month,
        COUNT(user_id) AS UserCount
    FROM liocinema_db.subscribers
    WHERE subscription_date >= '2024-01-01' AND subscription_date <= '2024-11-30'
    GROUP BY EXTRACT(MONTH FROM subscription_date)) AS PREVIOUS_MONTH
    ON CURRENT_MONTH.Month = PREVIOUS_MONTH.Month + 1
ORDER BY CURRENT_MONTH.Month;

-- Count of Active Users
 
(SELECT 
    (SELECT COUNT(*) 
     FROM liocinema_db.subscribers
     WHERE last_active_date IS NULL) 
    +
    (SELECT COUNT(*) 
     FROM liocinema_db.subscribers
     WHERE last_active_date > '2024-11-30') );
     
-- Inactive Rate On both platform

SELECT (COUNT(*) *100)/
(SELECT COUNT(*) FROM jotstar_db.subscribers) AS inactiveactive
     FROM jotstar_db.subscribers
     WHERE last_active_date <= '2024-11-30';
SELECT 
    (COUNT(*) * 100.0) / 
    (SELECT COUNT(*) FROM liocinema_db.subscribers) AS Inactive_Percentage
FROM liocinema_db.subscribers
WHERE last_active_date <= '2024-11-30';


-- Total watch,Average for active nd inactive users in Jotstar


SELECT 
    CASE 
        WHEN s.last_active_date <= '2024-11-30' THEN 'Inactive'
        ELSE 'Active' 
    END AS User_Status, 
    COUNT(s.user_id) AS User_Count, 
    AVG(w.total_watch_time_mins) AS Avg_Watch_Time, 
    SUM((w.total_watch_time_mins)/60) AS Total_Watch_TimeHrs
FROM liocinema_db.subscribers s
LEFT JOIN liocinema_db.content_consumption w ON s.user_id = w.user_id
GROUP BY User_Status;

-- Total watch,Average for active nd inactive users in Jotstar
SELECT 
    CASE 
        WHEN s.last_active_date <= '2024-11-30' THEN 'Inactive'
        ELSE 'Active' 
    END AS User_Status, 
    COUNT(s.user_id) AS User_Count, 
    AVG(w.total_watch_time_mins) AS Avg_Watch_Time, 
    SUM((w.total_watch_time_mins)/60) AS Total_Watch_TimeHrs
FROM jotstar_db.subscribers s
LEFT JOIN jotstar_db.content_consumption w ON s.user_id = w.user_id
GROUP BY User_Status;


-- correlation checking for liocinema between inactivity and watch_time

WITH Stats AS (
    SELECT 
        s.user_id,
        COALESCE(SUM(w.total_watch_time_mins/60), 0) AS Total_Watch_Time,
        CASE 
            WHEN s.last_active_date <= '2024-11-30' THEN 1 
            ELSE 0 
        END AS Inactive
    FROM liocinema_db.subscribers s
    LEFT JOIN liocinema_db.content_consumption w 
        ON s.user_id= w.user_id
    GROUP BY s.user_id, s.last_active_date
), 
Averages AS (
    SELECT 
        AVG(Total_Watch_Time) AS Mean_Watch_Time, 
        AVG(Inactive) AS Mean_Inactivity 
    FROM Stats
)
SELECT 
    SUM((Total_Watch_Time - (SELECT Mean_Watch_Time FROM Averages)) * 
        (Inactive - (SELECT Mean_Inactivity FROM Averages))) 
    / 
    (SQRT(SUM(POWER(Total_Watch_Time - (SELECT Mean_Watch_Time FROM Averages), 2))) * 
     SQRT(SUM(POWER(Inactive - (SELECT Mean_Inactivity FROM Averages), 2)))) 
    AS Correlation_Coefficient
FROM Stats;




-- correlation checking for jotstar between inactivity and watch_time
WITH Stats AS (
    SELECT 
        s.user_id,
        COALESCE(SUM(w.total_watch_time_mins/60), 0) AS Total_Watch_Time,
        CASE 
            WHEN s.last_active_date <= '2024-11-30' THEN 1 
            ELSE 0 
        END AS Inactive
    FROM jotstar_db.subscribers s
    LEFT JOIN jotstar_db.content_consumption w 
        ON s.user_id= w.user_id
    GROUP BY s.user_id, s.last_active_date
), 
Averages AS (
    SELECT 
        AVG(Total_Watch_Time) AS Mean_Watch_Time, 
        AVG(Inactive) AS Mean_Inactivity 
    FROM Stats
)
SELECT 
    SUM((Total_Watch_Time - (SELECT Mean_Watch_Time FROM Averages)) * 
        (Inactive - (SELECT Mean_Inactivity FROM Averages))) 
    / 
    (SQRT(SUM(POWER(Total_Watch_Time - (SELECT Mean_Watch_Time FROM Averages), 2))) * 
     SQRT(SUM(POWER(Inactive - (SELECT Mean_Inactivity FROM Averages), 2)))) 
    AS Correlation_Coefficient
FROM Stats;








