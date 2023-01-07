-- Rest bylaw.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3(
    driver_id INTEGER,
    start DATE,
    driving INTERVAL,
    breaks INTERVAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS Duration CASCADE;
DROP VIEW IF EXISTS DateHours CASCADE;
DROP VIEW IF EXISTS DriverRequest CASCADE;
DROP VIEW IF EXISTS DriverPick CASCADE;
DROP VIEW IF EXISTS DriverDrop CASCADE;
DROP VIEW IF EXISTS Break CASCADE;
DROP VIEW IF EXISTS Exceed CASCADE;
DROP VIEW IF EXISTS ExceedBreak CASCADE;
DROP VIEW IF EXISTS ExceedNoBreakxx CASCADE;
DROP VIEW IF EXISTS ExceedNoBreak CASCADE;
DROP VIEW IF EXISTS ExceedThree CASCADE;

-- Define views for your intermediate steps here:

-- request_id with the duration time
CREATE VIEW Duration as
SELECT P.request_id, D.datetime - P.datetime as hours, DATE(P.datetime) as day
FROM Pickup P, Dropoff D
WHERE P.request_id = D.request_id and DATE(P.datetime) = DATE(D.Datetime);

-- Sum of duration of the driver on each day
CREATE VIEW DateHours as
SELECT driver_id, day, SUM(hours) as hours
FROM ClockedIn c, Dispatch d, Duration
WHERE (c.shift_id = d.shift_id and
	d.request_id = Duration.request_id)
GROUP BY driver_id, day;

-- Drive with request_id.
CREATE VIEW DriverRequest as
SELECT driver_id, request_id
FROM ClockedIn, Dispatch
WHERE ClockedIn.shift_id = Dispatch.shift_id;

-- Driver with Pickup and Dropoff
CREATE VIEW DriverPick as
SELECT driver_id, request_id, datetime
FROM DriverRequest NATURAL JOIN Pickup;

CREATE VIEW DriverDrop as
SELECT driver_id, request_id, datetime
FROM DriverRequest NATURAL JOIN Dropoff;


-- Break time between two rides
CREATE VIEW Break as
SELECT D.driver_id, DATE(P.datetime) as day, MIN(P.datetime - D.datetime) as break
FROM DriverPick P, DriverDrop D
WHERE (P.driver_id = D.driver_id and
	DATE(P.datetime) = DATE(D.Datetime) and
	P.datetime >= D.datetime)
GROUP BY D.driver_id, D.request_id, DATE(P.datetime);

-- Driver who drived more than 12 hours a day
CREATE VIEW Exceed as
SELECT *
FROM DateHours
WHERE hours >= '12:00:00';

-- Driver who drived more than 12 hours a day and have a 15-min break
CREATE VIEW ExceedBreak as
SELECT driver_id, day, hours
FROM Exceed NATURAL JOIN Break
WHERE break > '00:15:00';

-- Driver who drived more than 12 hours a day and didn't have a 15-min break
CREATE VIEW ExceedNoBreakxx as
(SELECT *
FROM Exceed)
EXCEPT
(SELECT *
FROM ExceedBreak);

-- Driver who drived more than 12 hours a day and didn't have a 15-min break(Including break time)
CREATE VIEW ExceedNoBreak as
SELECT driver_id, day, hours, COALESCE(break, '00:00:00') as break
FROM ExceedNoBreakxx NATURAL LEFT JOIN Break;


-- They exceed and no break for three days
CREATE VIEW ExceedThree as
SELECT e1.driver_id, e1.day as start,
JUSTIFY_INTERVAL(e1.hours+e2.hours+e3.hours) as driving,
JUSTIFY_INTERVAL(e1.break+e2.break+e3.break) as breaks
FROM ExceedNoBreak e1, ExceedNoBreak e2, ExceedNoBreak e3
WHERE (e2.day=e1.day+INTERVAL '1 day' and e3.day = e1.day+INTERVAL '2 day' and
	e1.driver_id = e2.driver_id and e2.driver_id = e3.driver_id);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
select * from ExceedThree;
