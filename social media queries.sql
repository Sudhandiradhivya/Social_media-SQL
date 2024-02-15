use social_media;
-- User Analytics:
-- 1.What is the average number of followers per user? 
SELECT 
    f.followee_id as user,ROUND(COUNT(f.follower_id) / COUNT(DISTINCT f.followee_id),
            0) AS average_followers
FROM
    follows f
    group by f.followee_id;

-- 2.Identify users who joined the platform in the last month.
SELECT DISTINCT
    user_id as last_month_joined_users
FROM
    login
WHERE
    DATE(login_time) >= CURDATE() - INTERVAL 1 MONTH;

-- 3.Find users with the most login activity top 5. 

SELECT 
    user_id as users, COUNT(login_id) AS active_user_count
FROM
    login
GROUP BY user_id
ORDER BY active_user_count DESC
limit 5;

-- Content Analytics:
-- 1.Determine the most common type of content (photo, video) posted by users.
SELECT 
    CASE
        WHEN COUNT(DISTINCT photo_id) > COUNT(DISTINCT video_id) THEN 'Photo'
        WHEN COUNT(DISTINCT photo_id) < COUNT(DISTINCT video_id) THEN 'Video'
    END AS most_common_type
FROM
    post;

-- 2.Identify posts with the highest engagement (likes + comments) top 5. 

with cte1 as(
select p.post_id,count(pl.post_id) as post_counts
from post p
left join  post_likes pl on p.post_id=pl.post_id
group by p.post_id),
cte2 as(

select p.post_id,count(c.post_id) as comment_counts
from post p
left join  comments c on p.post_id=c.post_id
group by p.post_id)

select cte1.post_id as posts,cte1.post_counts+cte2.comment_counts as highest_engagement
from cte1 join cte2 on cte1.post_id=cte2.post_id
order by highest_engagement desc
limit 5;

-- 3.Analyze the distribution of post sizes in the photos and videos tables. 
SELECT
    p.post_id,
    COALESCE(SUM(photo.size), 0) AS photo_size,
    COALESCE(SUM(video.size), 0) AS video_size
FROM
    post p
LEFT JOIN
    photos photo ON p.post_id = photo.post_id
LEFT JOIN
    videos video ON p.post_id = video.post_id
GROUP BY
    p.post_id;

-- Engagement Patterns:
-- 1.Find the top 5 posts with the most likes. 
select p.post_id as post ,count(pl.post_id) as likes_counts
from post p 
left join post_likes pl
on p.post_id=pl.post_id
group by p.post_id
order by likes_counts desc
limit 5 ;

-- 2. Determine the average number of comments per post.
select
post_id,
count(post_id),
count(*)/count(distinct post_id) as average_comments
from comments
group by post_id;

-- Followers Growth Analysis:
-- 1.Find users who have the most followers. 

SELECT 
    followee_id as user, COUNT(distinct follower_id) AS followers_count
FROM
    follows
GROUP BY followee_id
ORDER BY followers_count DESC
LIMIT 1;
 
-- 2.Identify users with the most reciprocal follows (mutual follows). 
SELECT
    A.follower_id AS user_1,
    A.followee_id AS user_2,
COUNT(*) AS reciprocal_follows_count

FROM
    follows A
JOIN
    follows B ON A.follower_id = B.followee_id AND A.followee_id = B.follower_id
WHERE
    A.follower_id < A.followee_id
GROUP BY
    A.follower_id, A.followee_id
order by reciprocal_follows_count desc;

-- 3. User Not Followed by anyone
SELECT user_id, username AS 'User Not Followed and following by anyone '
FROM users
WHERE user_id NOT IN (SELECT followee_id FROM follows)
and user_id NOT IN (SELECT follower_id FROM follows);

-- 4.Identify the top 10 users with the highest follower growth rate.
select * from follows;
WITH InitialFollowerCounts AS (
    SELECT
        followee_id,
        COUNT(follower_id) AS initial_followers
    FROM
        follows
    WHERE
        created_at = (SELECT MIN(created_at) FROM follows)
    GROUP BY
        followee_id
),
LatestFollowerCounts AS (
    SELECT
        followee_id,
        COUNT(follower_id) AS latest_followers
    FROM
        follows
    WHERE
        created_at = (SELECT MAX(created_at) FROM follows)
    GROUP BY
        followee_id
)

SELECT
    ifc.followee_id as users
    
FROM
    InitialFollowerCounts ifc
JOIN
    LatestFollowerCounts lfc ON ifc.followee_id = lfc.followee_id
ORDER BY
    ifc.initial_followers - lfc.latest_followers DESC
LIMIT 10;

-- User Engagement Over Time:
-- 1. Most Inactive User
SELECT user_id, username AS 'Most Inactive User'
FROM users
WHERE user_id NOT IN (SELECT user_id FROM post);

-- 2.Identify users who haven’t logged in for over a week.
SELECT 
    user_id as users
FROM
    login
GROUP BY user_id
HAVING MAX(login_time) < DATE_SUB(CURDATE(), INTERVAL 7 DAY);

-- Hahtag Analysis
-- 1.How many posts are associated with the top 3 hashtags?
with post_cte as(
SELECT 
    h.hashtag_name as top_3_hashtags,
    COUNT(pt.hashtag_id) AS hashtag_count,
    COUNT(pt.post_id) as post_count
FROM
    hashtags h
        JOIN
    post_tags pt ON h.hashtag_id = pt.hashtag_id
GROUP BY h.hashtag_name
ORDER BY hashtag_count DESC
LIMIT 3) 

SELECT 
    top_3_hashtags, post_count
FROM
    post_cte
    ORDER BY 
    post_count DESC;
    
    
 -- 2.What are the top 5 most popular hashtags based on usage frequency?


SELECT 
   h.hashtag_name, COUNT(*) AS hashtag_usage_frequency
FROM
    hashtags h
        JOIN
    post_tags pt ON h.hashtag_id = pt.hashtag_id
GROUP BY h.hashtag_name order by hashtag_usage_frequency desc limit 5;    

    
