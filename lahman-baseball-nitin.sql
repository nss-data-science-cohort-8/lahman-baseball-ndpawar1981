--1.Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the 
--major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH
	VANDY AS (
		SELECT DISTINCT
			P.NAMEFIRST,
			P.NAMELAST,
			S.SALARY AS TOT_SALARY
		FROM
			PEOPLE P
			INNER JOIN COLLEGEPLAYING CP USING (PLAYERID)
			INNER JOIN SALARIES S ON S.PLAYERID = P.PLAYERID
		WHERE
			CP.SCHOOLID = 'vandy'
			--and p.playerid = 'priceda01' 
		ORDER BY
			TOT_SALARY DESC
	)
SELECT
	NAMEFIRST,
	NAMELAST,
	cast(cast(SUM(TOT_SALARY) as integer) as money)  AS TOT_EARNED_SALARY
FROM
	VANDY
GROUP BY
	NAMEFIRST,
	NAMELAST
ORDER BY
	TOT_EARNED_SALARY DESC;


--2.Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with 
--position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of
--putouts made by each of these three groups in 2016.

WITH
	PUTOUTS AS (
		SELECT
			PLAYERID,
			CASE
				WHEN POS = 'OF' THEN 'Outfield'
				WHEN POS IN ('2B', '1B', '3B', 'SS') THEN 'Infield'
				WHEN POS IN ('P', 'C') THEN 'Battery'
			END AS FIELD_POSITION,
			POS AS POSITIONCODE,
			PO AS PUTOUTS
		FROM
			FIELDING
		WHERE yearid =2016
	)
SELECT
	FIELD_POSITION,
	SUM(PUTOUTS) AS TOTAL_PUTPUTS
FROM
	PUTOUTS
GROUP BY
	FIELD_POSITION
ORDER BY
	2 DESC;


3.--Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
--Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the 
--generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, 
--check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)

WITH
	DECADE AS (
		SELECT
			GENERATE_SERIES(1920, 2016, 10) AS LOWER_YEAR,
			GENERATE_SERIES(1930, 2020, 10) AS UPPER_YEAR
	),
	STRIKEOUT AS (
		SELECT
			T.YEARID, --round(avg(so)/avg(g),2) as strikeOuts_per_game
			SO AS STRIKE_OUT,
			G AS TOT_GAMES,
			hr as home_runs,
			D.LOWER_YEAR,
			D.UPPER_YEAR
		FROM
			TEAMS T
			LEFT JOIN DECADE D ON T.YEARID >= D.LOWER_YEAR
			AND T.YEARID <= D.UPPER_YEAR
		WHERE
			D.UPPER_YEAR IS NOT NULL
			AND D.LOWER_YEAR IS NOT NULL
	)
SELECT
	LOWER_YEAR,
	UPPER_YEAR,
	ROUND(AVG(S.STRIKE_OUT) / AVG(S.TOT_GAMES), 2) AS STRIKEOUTS_PER_GAME,
	ROUND(AVG(S.home_runs) / AVG(S.TOT_GAMES), 2) AS HOMERUNS_PER_GAME
FROM
	STRIKEOUT S GROUP BY
	LOWER_YEAR,
	UPPER_YEAR
ORDER BY
	LOWER_YEAR;


--4.Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts
--which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who 
--attempted at least 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.


SELECT
	P.NAMEFIRST,
	P.NAMELAST,
	B.PLAYERID,
	SUM(SB) STOLE_BASES,
	SUM(SB + CS) AS STOELN_BASE_ATTEMPTS,
	ROUND(CAST(SUM(SB) AS DECIMAL) / SUM(SB + CS) * 100, 2) AS STOLEN_BASE_PERCENTAGE
FROM
	BATTING B
	INNER JOIN PEOPLE P USING (PLAYERID)
WHERE
	B.YEARID = 2016
GROUP BY
	P.NAMEFIRST,
	P.NAMELAST,
	B.PLAYERID
HAVING
	SUM(SB + CS) > 0
	AND SUM(SB + CS) >= 20
ORDER BY
	STOLEN_BASE_PERCENTAGE DESC;

--5.From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of
--wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series
--champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case
--that a team with the most wins also won the world series? What percentage of the time?

with Maxwins as (
select yearid,teamid,name,lgid,rank,w,wswin, max(w) over(Partition by yearid) as team_max_wins_for_Year
from teams where yearid >= 1970 order by yearid,lgid,rank
)
select * from (select yearid,name,w as wins, wswin as worldSeries,'MAX_WON_BUT_LOST_WORLDSERIES' as TEXT from Maxwins
where w = team_max_wins_for_Year
and wswin = 'N'
order by w desc 
limit 1)
union
select * from (select yearid,name,w as wins, wswin as worldSeries,'MIN_WON_BUT_WON_WORLDSERIES' as TEXT from Maxwins
where w <> team_max_wins_for_Year
and wswin = 'Y'
order by w asc
limit 1);

--skip year 1981

with Maxwins as (
select yearid,teamid,name,lgid,rank,w,wswin, max(w) over(Partition by yearid) as team_max_wins_for_Year
from teams where yearid >= 1970 and yearid <> 1981 order by yearid,lgid,rank
)
select * from (select yearid,name,w as wins, wswin as worldSeries,'MAX_WON_BUT_LOST_WORLDSERIES' as TEXT from Maxwins
where w = team_max_wins_for_Year
and wswin = 'N'
order by w desc 
limit 1)
union
select * from (select yearid,name,w as wins, wswin as worldSeries,'MIN_WON_BUT_WON_WORLDSERIES' as TEXT from Maxwins
where w <> team_max_wins_for_Year
and wswin = 'Y'
order by w asc
limit 1);

-- Last part - 
--How often from 1970 to 2016 was it the case
--that a team with the most wins also won the world series? What percentage of the time?
with Maxwins as (
select yearid,teamid,name,lgid,rank,w,wswin, max(w) over(Partition by yearid) as team_max_wins_for_Year
from teams where yearid >= 1970 order by yearid,lgid,rank
)
select wswin,count(*) as totalwswin,
round((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () ,2)AS percentage
from Maxwins
where w = team_max_wins_for_Year
--and wswin = 'Y'
group by wswin
order by wswin;

select * from teams where yearid >= 1970  order by yearid,lgid,rank;

select sb,cs, sb+cs, round(cast(sb as decimal)/(sb+cs) * 100 ,2) ,16/24 from batting where playerid='doziebr01' and yearid = 2016;

select  *from pitching;

select * from appearances where yearid > 1970 order by 1;

select * from salaries where playerid = 'priceda01' ;

select *  from teams where yearid >= 1970 order by 1,2,rank;

select * from people where nameFirst = 'Brian' and nameLast = 'Dozier';

select * from collegeplaying where schoolid = 'vandy' order by 3 asc

SELECT generate_series(1920, 2016, 10) AS lower,
       generate_series(1930, 2020, 10) AS upper;