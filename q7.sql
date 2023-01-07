-- Ratings histogram.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7(
    driver_id INTEGER,
    r5 INTEGER,
    r4 INTEGER,
    r3 INTEGER,
    r2 INTEGER,
    r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS DriverRequest CASCADE;
DROP VIEW IF EXISTS DriverEachRating CASCADE;
DROP VIEW IF EXISTS Ratingone CASCADE;
DROP VIEW IF EXISTS RatingTwo CASCADE;
DROP VIEW IF EXISTS RatingThree CASCADE;
DROP VIEW IF EXISTS RatingFour CASCADE;
DROP VIEW IF EXISTS RatingFive CASCADE;
DROP VIEW IF EXISTS Answer CASCADE;

-- Define views for your intermediate steps here:

-- Driver with request_id
CREATE VIEW DriverRequest as
SELECT driver_id, request_id
FROM ClockedIn, Dispatch
WHERE ClockedIn.shift_id = Dispatch.shift_id;

-- Driver with their request_id and days and rating
CREATE VIEW DriverEachRating AS
SELECT *
FROM DriverRequest NATURAL JOIN DriverRating;

-- Driver Rating for each score 1-5
CREATE VIEW RatingOne AS
SELECT driver_id, COUNT(rating) as r1
FROM DriverEachRating
WHERE rating = 1
GROUP BY driver_id;

CREATE VIEW RatingTwo AS
SELECT driver_id, COUNT(rating) as r2
FROM DriverEachRating
WHERE rating = 2
GROUP BY driver_id;


CREATE VIEW RatingThree AS
SELECT driver_id, COUNT(rating) as r3
FROM DriverEachRating
WHERE rating = 3
GROUP BY driver_id;

CREATE VIEW RatingFour AS
SELECT driver_id, COUNT(rating) as r4
FROM DriverEachRating
WHERE rating = 4
GROUP BY driver_id;

CREATE VIEW RatingFive AS
SELECT driver_id, COUNT(rating) as r5
FROM DriverEachRating
WHERE rating = 5
GROUP BY driver_id;

-- Five Joins
CREATE VIEW Answer AS
SELECT driver_id,COALESCE(r5, 0) as r5, COALESCE(r4, 0) as r4,
COALESCE(r3, 0) as r3, COALESCE(r2, 0) as r2, COALESCE(r1, 0) as r1
FROM Driver NATURAL LEFT JOIN RatingFive
	    NATURAL LEFT JOIN RatingFour
	    NATURAL LEFT JOIN RatingThree
	    NATURAL LEFT JOIN RatingTwo
	    NATURAL LEFT JOIN RatingOne;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q7
SELECT * FROM Answer;
