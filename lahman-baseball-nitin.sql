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
	SUM(TOT_SALARY) AS TOT_EARNED_SALARY
FROM
	VANDY
GROUP BY
	NAMEFIRST,
	NAMELAST
ORDER BY
	TOT_EARNED_SALARY DESC;


--2.Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with 
--position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.


select * from fielding;

select  *from pitching;

select * from appearances;

select * from salaries where playerid = 'priceda01' ;

select *  from teams order by 1 desc;

select * from collegeplaying where schoolid = 'vandy' order by 3 asc