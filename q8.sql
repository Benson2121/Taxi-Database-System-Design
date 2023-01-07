-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8(
    client_id INTEGER,
    reciprocals INTEGER,
    difference FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS ClientRequestRating CASCADE;
DROP VIEW IF EXISTS ReciprocalRating CASCADE;
DROP VIEW IF EXISTS Answer CASCADE;

-- Define views for your intermediate steps here:

-- Client Rating and Request_id
CREATE VIEW ClientRequestRating AS
SELECT R.client_id, R.request_id, C.rating
FROM Request R, ClientRating C
WHERE R.request_id = C.request_id;

-- Reciprocal rating
CREATE VIEW ReciprocalRating AS
SELECT client_id, C.request_id, D.rating - C.rating as difference
FROM ClientRequestRating C, DriverRating D
WHERE C.request_id = D.request_id;

-- Answer
CREATE VIEW Answer AS
SELECT client_id, COUNT(request_id) as reciprocals, AVG(difference) as difference
FROM ReciprocalRating
GROUP BY client_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q8
SELECT * FROM Answer;
