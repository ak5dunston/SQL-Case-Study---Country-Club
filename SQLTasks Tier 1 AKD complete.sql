/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 1 of the case study, which means that there'll be more guidance for you about how to 
setup your local SQLite connection in PART 2 of the case study. 

The questions in the case study are exactly the same as with Tier 2. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
Select COUNT(name) 
from Facilities
where membercost > 0;

COUNT(name)
5

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
From Facilities
Where membercost > 0 
AND membercost < (monthlymaintenance *.2);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * 
From Facilities
Where facid IN(1,5);


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, 
(CASE WHEN monthlymaintenance > 100 then 'expensive'
 ELSE 'cheap' END) AS cheaporexpensive

from Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
From Members
Where joindate IN 
    (SELECT MAX(joindate)
     from Members);


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT
  b.firstname || ' ' || b.surname AS member,
  c.name AS facility
FROM
  Bookings AS a
INNER JOIN
  Members AS b
ON
  a.memid = b.memid
INNER JOIN
  Facilities AS c
ON
  a.facid = c.facid
WHERE
  c.name LIKE 'Tennis Court%'
ORDER BY
  member
;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT
  a.firstname || ' ' || a.surname AS member,
  c.name AS facility,
  b.slots * (
    CASE
	  WHEN a.memid = 0 THEN c.guestcost
	  ELSE c.membercost
    END
  ) AS cost
FROM
  Members AS a
INNER JOIN
  Bookings AS b
ON
  a.memid = b.memid
INNER JOIN
  Facilities AS c
ON
  b.facid = c.facid
WHERE 
  date(b.starttime) = '2012-09-14'
  AND (
    a.memid=0 AND b.slots*c.guestcost > 30
    OR
    a.memid!=0 AND b.slots*c.membercost > 30
  )
;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

select member, facility, cost from (
	select 
		mems.firstname || ' ' || mems.surname as member,
		facs.name as facility,
		case
			when mems.memid = 0 then
				bks.slots*facs.guestcost
			else
				bks.slots*facs.membercost
		end as cost
		from
			Members mems
			inner join Bookings bks
				on mems.memid = bks.memid
			inner join Facilities facs
				on bks.facid = facs.facid
		where
			bks.starttime >= '2012-09-14' and
			bks.starttime < '2012-09-15'
	) as bookings
	where cost > 30

/* PART 2: SQLite
/* We now want you to jump over to a local instance of the database on your machine. 

Copy and paste the LocalSQLConnection.py script into an empty Jupyter notebook, and run it. 

Make sure that the SQLFiles folder containing thes files is in your working directory, and
that you haven't changed the name of the .db file from 'sqlite\db\pythonsqlite'.

You should see the output from the initial query 'SELECT * FROM FACILITIES'.

Complete the remaining tasks in the Jupyter interface. If you struggle, feel free to go back
to the PHPMyAdmin interface as and when you need to. 

You'll need to paste your query into value of the 'query1' variable and run the code block again to get an output.
 
QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT name, SUM(revenue) as total_rev  
        FROM (SELECT name, case when memid = 0 then slots * guestcost 
                    ELSE slots * membercost end as revenue
             FROM Bookings as b
             LEFT JOIN Facilities as f
             ON b.facid = f.facid)as sub
         GROUP BY name
         HAVING total_rev < 1000
         ORDER BY total_rev;    

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT mems.firstname as memfname, mems.surname as memsname, recs.firstname as recfname, recs.surname as recsname
	FROM
		Members mems
		LEFT OUTER JOIN Members recs
			ON recs.memid = mems.recommendedby
ORDER BY memsname, memfname;          

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT facs.name, sum(slots * case
			WHEN memid = 0 then facs.guestcost
			ELSE facs.membercost
		end) AS revenue
	FROM Bookings bks
	INNER JOIN Facilities facs
		ON bks.facid = facs.facid
	GROUP BY facs.name
ORDER BY revenue;          

/* Q13: Find the facilities usage by month, but not guests */

SELECT facid, sum(slots) as "Total Slots"
	FROM Bookings
	WHERE
		starttime >= '2012-09-01'
		and starttime < '2012-10-01'
	GROUP BY facid
ORDER BY sum(slots);          
