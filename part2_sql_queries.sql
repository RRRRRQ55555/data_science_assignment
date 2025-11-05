--查询每天新注册用户数量
SELECT date(signup_date) AS signup_day,
       COUNT(*) AS new_users
FROM users
WHERE signup_date IS NOT NULL
GROUP BY signup_day
ORDER BY signup_day;


--查询最近7天每天的活跃用户数
-- 首先把YYYY/M/D HH:MM解析成d=YYYY-MM-DD
WITH t AS (
  SELECT
    user_id,
    event_type,
    timestamp AS ts,
    substr(timestamp, 1, 4) AS y,
    instr(timestamp, '/') AS p1,
    instr(substr(timestamp, instr(timestamp,'/')+1), '/') AS p2rel
  FROM events
),
parts AS (
  SELECT
    user_id, event_type, ts, y, p1, p2rel,
    CAST(substr(ts, p1+1, p2rel-1) AS INT) AS m,
    substr(ts, p1 + 1 + p2rel) AS tail
  FROM t
),
parts2 AS (
  SELECT
    user_id, event_type, ts, y, m,
    instr(tail, ' ') AS pspace,
    tail
  FROM parts
),
ev AS (
  SELECT
    user_id, event_type, ts,
    --组装成 YYYY-MM-DD
    printf('%04d-%02d-%02d',
           CAST(y AS INT),
           m,
           CAST(substr(tail, 1, pspace-1) AS INT)
    ) AS d
  FROM parts2
),
bound AS (
  SELECT date(MAX(d), '-6 days') AS start_day,
         MAX(d) AS end_day
  FROM ev
)
SELECT
  e.d AS day,
  COUNT(DISTINCT e.user_id) AS active_users
FROM ev e, bound b
WHERE e.d BETWEEN b.start_day AND b.end_day
GROUP BY e.d
ORDER BY e.d;



--查询每个用户的事件总数和最常见的事件类型
SELECT u.user_id,
       COALESCE((SELECT COUNT(*) FROM events e WHERE e.user_id = u.user_id), 0) AS total_events,
       (SELECT event_type
        FROM events e2
        WHERE e2.user_id = u.user_id
        GROUP BY event_type
        ORDER BY COUNT(*) DESC, event_type
        LIMIT 1) AS most_common_event
FROM users u
ORDER BY total_events DESC;


--查询男性与女性用户的平均事件数是否有差异
WITH user_event_counts AS (
  SELECT u.user_id,
         u.gender,
         COALESCE((SELECT COUNT(*) FROM events e WHERE e.user_id = u.user_id), 0) AS total_events
  FROM users u
)
SELECT gender,
       COUNT(*) AS num_users,
       AVG(total_events) AS avg_events_per_user
FROM user_event_counts
WHERE gender IN ('Male', 'Female')
GROUP BY gender;

