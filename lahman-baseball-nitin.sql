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
WITH
	MAXWINS AS (
		SELECT
			YEARID,
			TEAMID,
			NAME,
			LGID,
			RANK,
			W,
			WSWIN,
			MAX(W) OVER (
				PARTITION BY
					YEARID
			) AS TEAM_MAX_WINS_FOR_YEAR
		FROM
			TEAMS
		WHERE
			YEARID >= 1970
		ORDER BY
			YEARID,
			LGID,
			RANK
	)
SELECT
	WSWIN,
	COUNT(*) AS TOTALWSWIN,
	ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (), 2) AS PERCENTAGE
FROM
	MAXWINS WHERE
	W = TEAM_MAX_WINS_FOR_YEAR
	--and wswin = 'Y'
GROUP BY
	WSWIN
ORDER BY
	WSWIN;


--6 Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.


SELECT DISTINCT
	P.NAMEFIRST,
	P.NAMELAST,
	T.NAME,
	M1.YEARID,
	M1.PLAYERID
FROM
	AWARDSMANAGERS M1
	INNER JOIN MANAGERS MG ON MG.PLAYERID = M1.PLAYERID
	AND MG.YEARID = M1.YEARID
	INNER JOIN TEAMS T ON MG.TEAMID = T.TEAMID and MG.YEARID = T.YEARID
	INNER JOIN PEOPLE P ON M1.PLAYERID = P.PLAYERID
WHERE
	M1.AWARDID = 'TSN Manager of the Year'
	AND M1.LGID in('NL','AL')
	AND EXISTS (
		SELECT
			'x'
		FROM
			AWARDSMANAGERS M2
		WHERE
			M2.AWARDID = M1.AWARDID
			AND M2.LGID in( 'AL','NL')
			and M2.LGID <> M1.LGID
			and M1.playerid = m2.playerid
	)

--7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). 
--Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

WITH
	PITCHERS AS (
		SELECT DISTINCT
			PLAYERID,
			YEARID,
			TEAMID,
			GS AS TOT_GAMES_STARTED
		FROM
			PITCHING
		WHERE
			YEARID = 2016
			AND GS >= 10
	),
	P2 AS (
		SELECT DISTINCT
			PT.PLAYERID,
			PT.YEARID,
			PT.TEAMID,
			S.SALARY,
			PT.SO,
			MIN(S.SALARY) OVER () AS MIN_SALARY,
			MIN(PT.SO) OVER () AS MIN_SO
		FROM
			PITCHERS PR
			INNER JOIN PITCHING PT ON PT.PLAYERID = PR.PLAYERID
			AND PR.YEARID = PT.YEARID
			AND PR.TEAMID = PT.TEAMID
			INNER JOIN SALARIES S ON S.PLAYERID = PR.PLAYERID
			AND S.TEAMID = PR.TEAMID
			AND S.YEARID = PR.YEARID
	)
SELECT
	*
FROM
	P2
WHERE
	SALARY = MIN_SALARY
	OR SO = MIN_SO
ORDER BY
	SALARY,
	SO;

--8.Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of
--fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted 
--column of the halloffame table.
WITH
	HITS AS (
		SELECT
			PLAYERID,
			SUM(H) AS CAREER_HITS
		FROM
			BATTING
		GROUP BY
			PLAYERID
		HAVING
			SUM(H) >= 3000
	)
SELECT DISTINCT
	H.PLAYERID,
	P.NAMEFIRST,
	P.NAMELAST,
	H.CAREER_HITS,
	HF.YEARID AS HOF_INDUCTED_YEAR
FROM
	HITS H
	INNER JOIN PEOPLE P USING (PLAYERID)
	LEFT JOIN HALLOFFAME HF ON HF.PLAYERID = H.PLAYERID
	AND HF.INDUCTED = 'Y'
	AND HF.CATEGORY = 'Player'
ORDER BY
	CAREER_HITS DESC;

--9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.
WITH
	HITS AS (
		SELECT
			PLAYERID,
			TEAMID,
			SUM(H)
		FROM
			BATTING
		GROUP BY
			PLAYERID,
			TEAMID
		HAVING
			SUM(H) >= 1000
		ORDER BY
			1,
			2
	)
SELECT
	NAMEFIRST,
	NAMELAST
FROM
	(
		SELECT
			H.PLAYERID,
			P.NAMEFIRST,
			P.NAMELAST,
			COUNT(*)
		FROM
			HITS H
			INNER JOIN PEOPLE P ON H.PLAYERID = P.PLAYERID
		GROUP BY
			H.PLAYERID,
			P.NAMEFIRST,
			P.NAMELAST
		HAVING
			COUNT(*) > 1
	) A;


--10.Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, 
--and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.




--Rough Work
select * from batting where playerid  = 'aaronha01' and teamid = 'ATL';

select * from HallofFame where inducted = 'Y' and category = 'Player';

select  * from pitching where playerid='garcija02' and yearid = 2016 order by 1;

select * from salaries where playerid = 'garcija02' ;

select * from awardsmanagers where  playerid='lanieha01';

select * from managers where playerid='lanieha01';

select * from people where playerid='garcija02';

select * from teams where yearid = 1986 and playerid='lanieha01' order by yearid,lgid,rank;

select sb,cs, sb+cs, round(cast(sb as decimal)/(sb+cs) * 100 ,2) ,16/24 from batting where playerid='doziebr01' and yearid = 2016;

select  * from pitching;

select * from appearances where yearid > 1970 order by 1;

select * from salaries where playerid = 'garcija02' ;

select *  from teams where yearid >= 1970 order by 1,2,rank;

select * from people where nameFirst = 'Brian' and nameLast = 'Dozier';

select * from collegeplaying where schoolid = 'vandy' order by 3 asc

SELECT generate_series(1920, 2016, 10) AS lower,
       generate_series(1930, 2020, 10) AS upper;