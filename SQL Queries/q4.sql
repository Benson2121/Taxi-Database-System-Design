-- Do drivers improve?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4(
    type VARCHAR(9),
    number INTEGER,
    early FLOAT,
    late FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS RequestX CASCADE;
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS DriverDays CASCADE;
DROP VIEW IF EXISTS DriverDayRating CASCADE;
DROP VIEW IF EXISTS DriverTen CASCADE;
DROP VIEW IF EXISTS DriverFive CASCADE;
DROP VIEW IF EXISTS AvgFive CASCADE;
DROP VIEW IF EXISTS AfterFive CASCADE;
DROP VIEW IF EXISTS AvgAfter CASCADE;
DROP VIEW IF EXISTS Trained CASCADE;
DROP VIEW IF EXISTS Untrained CASCADE;
DROP VIEW IF EXISTS Answer CASCADE;

-- Define views for your intermediate steps here:

-- Ride completed
CREATE VIEW RequestX AS
SELECT *
FROM Request R
WHERE EXISTS (
SELECT *
FROM Dropoff
WHERE Dropoff.request_id = R.request_id);

-- Driver with their request_id and days
CREATE VIEW DriverDays as
SELECT driver_id, RequestX.request_id, DATE(RequestX.datetime) as day
FROM ClockedIn, Dispatch, RequestX
WHERE ClockedIn.shift_id = Dispatch.shift_id and Dispatch.request_id = RequestX.request_id;

-- Driver with their request_id and days and rating
CREATE VIEW DriverDayRating AS
SELECT *
FROM DriverDays NATURAL LEFT JOIN DriverRating;

-- Driver with at least ten days
CREATE VIEW DriverTen AS
SELECT *
FROM DriverDayRating D1
WHERE EXISTS
(SELECT D2.driver_id
FROM DriverDayRating D2
WHERE D1.driver_id = D2.driver_id
GROUP BY D2.driver_id
HAVING COUNT(DISTINCT day) >= 10
);

-- First 5 days for each driver
CREATE VIEW DriverFive AS
SELECT *
FROM DriverTen D1
WHERE D1.day IN
(
SELECT DISTINCT day
FROM DriverTen D2
WHERE D1.driver_id = D2.driver_id
ORDER BY D2.day
LIMIT 5
);

-- Average rating of first five
CREATE VIEW AvgFive AS
SELECT driver_id, AVG(rating) as avgr
FROM DriverFive
GROUP BY driver_id;

-- Rating after first five days
CREATE VIEW AfterFive AS
(SELECT *
FROM DriverTen)
EXCEPT
(SELECT *
FROM DriverFive);

-- Average ratings of after five
CREATE VIEW AvgAfter AS
SELECT driver_id, AVG(rating) as avgr
FROM AfterFive
GROUP BY driver_id;

CREATE VIEW Trained AS
SELECT 'trained' as type, COUNT(D.driver_id) as number, AVG(AF.avgr) as early, AVG(AA.avgr) as late
FROM Driver D, AvgFive AF, AvgAfter AA
WHERE D.driver_id in ((SELECT driver_id FROM AvgFive) UNION (SELECT driver_id FROM AvgAfter)) and trained = true;

CREATE VIEW Untrained AS
SELECT 'untrained' as type, COUNT(D.driver_id) as number, AVG(AF.avgr) as early, AVG(AA.avgr) as late
FROM Driver D, AvgFive AF, AvgAfter AA
WHERE D.driver_id in ((SELECT driver_id FROM AvgFive) UNION (SELECT driver_id FROM AvgAfter)) and trained = false;

-- Final Answer
CREATE VIEW Answer AS
(SELECT * FROM Trained) UNION (SELECT * FROM Untrained);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
select * from Answer;

