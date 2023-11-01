BigQuery
Question 1: Descriptive statistics.
The boss wants to know some overview insights into the service. Please make a report showing some basic statistics for the boss.


--number of daily users, daily access count, daily average work volume
SELECT
  date,
  COUNT(DISTINCT user_id) AS daily_user_count,
  COUNT(*) AS daily_access_count,
  platform,
  AVG(volume) AS average_work_volume
FROM
  `prefab-root-291109.events.events `
GROUP BY
  date, platform
ORDER BY
  date;


--number of user based on their country
WITH u AS (
  SELECT
    mp_country_code,
    COUNT(DISTINCT user_id) AS num
  FROM
    `prefab-root-291109.events.user_info`
  GROUP BY
    mp_country_code
),
g AS ( SELECT Country,
    Code FROM (
  SELECT Country,Code,
ROW_NUMBER() OVER (PARTITION BY Code ORDER BY Country) AS finish_rank
  FROM
    `prefab-root-291109.events.geography`
) WHERE finish_rank = 1
)
SELECT
  g.Country,
  u.num AS Number_of_cus
FROM
  g
LEFT JOIN
  u
ON
  u.mp_country_code = g.Code
GROUP BY
  g.Country, u.num
ORDER BY
  Number_of_cus DESC;



Question 3:
Let day 1 be the day a user first comes to the app, becoming a new user.
How many percent users still use the app after X days (i.e. 1 day, 2 days, etc.) from day

DECLARE numday INT64;
SET numday = 10;

WITH cte AS (
  SELECT
    e.user_id,
    MAX(e.date) AS Last_login,
    MIN(e.date) AS Created
  FROM
    `prefab-root-291109.events.events ` e
  GROUP BY
    e.user_id
),
cte2 AS (
  SELECT
    user_id,
    DATE_DIFF(Last_login, Created, DAY) AS Login_day
  FROM
    cte
)

SELECT
  (
    SELECT COUNT(*) AS Result FROM cte2 WHERE Login_day > numday
  ) * 1.00 / (
    SELECT COUNT(DISTINCT user_id) FROM `prefab-root-291109.events.user_info` 
  ) * 100 AS percentage_users_still_active;













Question 4: 
There are many people suspend their account and create a new one after they used up their quota to exploit the glitch for trail usage.As a result, one user can have many different account history. Please identify the most serious cheater based on your perspective so that we can ban them from using the service. 

with t1 as (
SELECT user_id, count(*) as no_of_acc
from `prefab-root-291109.events.user_info`
group by user_id
),
t2 as (select round(avg(no_of_acc)) as avg_no_acc from t1)
select t1.user_id, t1.no_of_acc 
from t1, t2
where t1.no_of_acc > t2.avg_no_acc























Question 5:
Because there are some users that exploit the apps. They access the service too much. As a result, managers want to recalculate the access number. If they re-access within 6 hours , it is still counted as 1 access regardless of the actual access number. However, the volumes used by customers are still calculated normally.
Recalculate the access statistics. After recalculating, comment about the difference between the new calculating method and the previous one.

WITH RecalculatedEvents AS (
  SELECT
    user_id,
    date,
    platform,
    volume,
    datetime,
    LAG(datetime) OVER (PARTITION BY CAST(user_id AS int), platform ORDER BY datetime) AS previous_event_date
  FROM
    `prefab-root-291109.events.events `
)

SELECT
  date,
  COUNT(DISTINCT user_id) AS daily_user_count,
  COUNT(CASE WHEN TIMESTAMP_DIFF(datetime, previous_event_date, HOUR) >= 6 THEN 1 ELSE NULL END) AS daily_access_count,
  platform,
  AVG(volume) AS average_work_volume
FROM
  RecalculatedEvents
GROUP BY
  date, platform
ORDER BY
  date;

--result of the new method is much lower in access count








Question 6:
Customer grouping based on Volume, Frequency, Recency who are not in the serious cheater list.
with t1 as (
SELECT user_id, count(*) as no_of_acc
from `prefab-root-291109.events.user_info`
group by user_id
),
t2 as (select round(avg(no_of_acc)) as avg_no_acc from t1)
,banned_acc as (
select t1.user_id, t1.no_of_acc 
from t1, t2
where t1.no_of_acc > t2.avg_no_acc),
pre_rfv as (select user_id, max(date) as Lastdate, count(date) as Frequency, sum(volume) as Volume
from `prefab-root-291109.events.events `
group by user_id),
pre_rfv_recency as (select cast(user_id as int) as user_id, 
    date_diff(Lastdate,CURRENT_DATE(),day) as Recency,
    Frequency, Volume
    from pre_rfv),
RFV as (select *
, NTILE(4) over (order by Recency DESC) as R 
, NTILE(4) over (order by Frequency) as F 
, NTILE(4) over (order by Volume) as V
from pre_rfm_recency)
select RFV.*, CONCAT(R,F,V) as RFV, banned_acc.user_id as banned
from RFV left join banned_acc on RFV.user_id = banned_acc.user_id
where banned_acc.user_id is null;




