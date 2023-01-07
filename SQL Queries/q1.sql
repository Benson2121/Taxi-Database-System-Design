-- Months.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1(
    client_id INTEGER,
    email VARCHAR(30),
    months INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS RequestMonth CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW RequestMonth AS
SELECT TO_CHAR(request.datetime, 'YYYY MM') as month, Request.client_id
FROM Request JOIN Dropoff ON Request.request_id = Dropoff.request_id;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
SELECT Client.client_id, email, COUNT(DISTINCT month) as months
FROM Client NATURAL FULL JOIN RequestMonth
GROUP BY Client.client_id; 
