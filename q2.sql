-- Lure them back.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2(
    client_id INTEGER,
    name VARCHAR(41),
  	email VARCHAR(30),
  	billed FLOAT,
  	decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.

DROP VIEW IF EXISTS CountsYear CASCADE;
DROP VIEW IF EXISTS Bills CASCADE;
DROP VIEW IF EXISTS Before2020 CASCADE;
DROP VIEW IF EXISTS NorideClient CASCADE;
DROP VIEW IF EXISTS ClientYear CASCADE;
DROP VIEW IF EXISTS CountsYear2021 CASCADE;
DROP VIEW IF EXISTS Least500Client CASCADE;
DROP VIEW IF EXISTS HaveRidein2020 CASCADE;
DROP VIEW IF EXISTS FewerRideClient CASCADE;


-- Define views for your intermediate steps here:
-- Counts the number of times of complete ride in a year for those who rides(exluding zero)
CREATE VIEW CountsYear as
SELECT client_id, EXTRACT(YEAR FROM Request.datetime) as year, COUNT(*) as counts
FROM Dropoff, Request
WHERE Request.request_id = Dropoff.request_id
GROUP BY client_id, year;

-- Set year as 2021 in client
CREATE VIEW ClientYear as
SELECT *, EXTRACT(YEAR FROM TIMESTAMP '2021-12-31 13:30:15') AS year 
FROM Client;


-- Counts the number of times of complete ride in 2021 for those who rides(including zero)
CREATE VIEW CountsYear2021 as
SELECT ClientYear.client_id, year, COALESCE(counts, 0) as counts,
CONCAT(firstname, ' ', surname) as name, email
FROM CountsYear NATURAL RIGHT JOIN ClientYear;

-- Sum of Bills for a client in a year before 2020
CREATE VIEW Bills as
SELECT client_id, EXTRACT(YEAR FROM datetime) as year,SUM(amount) as totalamount
FROM Request NATURAL JOIN Billed
GROUP BY client_id, Year;

-- Clients who had rides before 2020 costing at least 500 in total
CREATE VIEW Least500Client as
SELECT client_id, SUM(totalamount) as costbefore2020
FROM Bills
WHERE year < 2020
GROUP BY client_id
HAVING SUM(totalamount) >= 500;


-- Clients who had rides in 2020 had between 1 and 10 rides
-- output client_id only
CREATE VIEW  HaveRideIn2020 as
SELECT client_id, counts
FROM CountsYear
WHERE year = 2020 and 1 <= counts and counts <= 10;

-- Clients who had fewer rides in 2021 than 2020
CREATE VIEW FewerRideClient as
SELECT c1.client_id, c2.counts - c1.counts as decline, email, name
FROM HaveRideIn2020 c1, CountsYear2021 c2
WHERE c1.client_id = c2.client_id and c1.counts > c2.counts;

-- left to do
-- get total amount the client was billed for rides that occured prior to 2020
-- difference between the number of rides they had in 2020 and 2021

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT client_id, name, email, costbefore2020 as billed, decline
FROM FewerRideClient NATURAL JOIN Least500Client;
