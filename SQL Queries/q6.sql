-- Frequent riders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6(
    client_id INTEGER,
    year CHAR(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS RequestX CASCADE;
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS RequestYear CASCADE;
DROP VIEW IF EXISTS CountYear CASCADE;
DROP VIEW IF EXISTS Years CASCADE;
DROP VIEW IF EXISTS Pairs CASCADE;
DROP VIEW IF EXISTS Highest CASCADE;
DROP VIEW IF EXISTS Counts CASCADE;
DROP VIEW IF EXISTS Lowest CASCADE;
DROP VIEW IF EXISTS HighestClient CASCADE;
DROP VIEW IF EXISTS LowestClient CASCADE;

-- Define views for your intermediate steps here:

-- Ride completed
CREATE VIEW RequestX AS
SELECT *
FROM Request R
WHERE EXISTS ( 
SELECT * 
FROM Dropoff 
WHERE Dropoff.request_id = R.request_id);

-- Change datatime to year in request
CREATE VIEW RequestYear AS
SELECT client_id, TO_CHAR(datetime, 'YYYY') as year
FROM RequestX;

-- Count number of rides for each year
CREATE VIEW CountYear AS
SELECT client_id, year, COUNT(*) as rides
FROM RequestYear
GROUP BY client_id, year;

-- All Years
CREATE VIEW Years AS
SELECT DISTINCT year
FROM RequestYear;

-- All Pairs
CREATE VIEW Pairs AS
SELECT Client.client_id, year
FROM Client, Years;

-- All counts year and client
CREATE VIEW Counts AS
SELECT client_id, year,COALESCE(rides, 0) as rides
FROM Pairs NATURAL LEFT JOIN CountYear;

-- Select Top3 highest rides
CREATE VIEW Highest AS
SELECT rides
FROM Counts
ORDER BY rides DESC
LIMIT 3;

-- Select Top3 lowest rides
CREATE VIEW Lowest AS
SELECT rides
FROM Counts
ORDER BY rides ASC
LIMIT 3;

-- Highest Clients
CREATE VIEW HighestCLient AS
SELECT client_id, year, rides
FROM Counts NATURAL JOIN Highest;

-- Lowest Clients
CREATE VIEW LowestCLient AS
SELECT client_id, year, rides
FROM Counts NATURAL JOIN Lowest;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
(SELECT * FROM HighestCLient) UNION (SELECT * FROM LowestCLient);
