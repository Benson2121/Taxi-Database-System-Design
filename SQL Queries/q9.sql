-- Consistent raters.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9(
    client_id INTEGER,
    email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS RequestX CASCADE;
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS ClientRide CASCADE;
DROP VIEW IF EXISTS DriverEachRating CASCADE;
DROP VIEW IF EXISTS SuchClient CASCADE;
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

-- Client and driver that have a ride
CREATE VIEW ClientRide AS
SELECT client_id, driver_id, RequestX.request_id
FROM ClockedIn, Dispatch, RequestX
WHERE ClockedIn.shift_id = Dispatch.shift_id and RequestX.request_id = Dispatch.request_id;

-- Client and driver that have a rating
CREATE VIEW DriverEachRating AS
SELECT client_id, driver_id, COUNT(rating) as crating
FROM  DriverRating NATURAL RIGHT JOIN ClientRide
GROUP BY client_id, driver_id;

-- Such Clients
CREATE VIEW SuchClient AS
SELECT DISTINCT client_id
FROM ClientRide
WHERE NOT EXISTS(
SELECT *
FROM DriverEachRating D
WHERE crating = 0 and ClientRide.client_id = D.client_id);


-- Answer
CREATE VIEW Answer AS
SELECT client_id, email
FROM Client NATURAL JOIN SuchClient;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9
SELECT * FROM Answer;
