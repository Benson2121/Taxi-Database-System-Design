-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
    client_id INTEGER,
    month VARCHAR(7),
    total FLOAT,
    comparison VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS RequestX CASCADE;
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS Months CASCADE;
DROP VIEW IF EXISTS BilledClient CASCADE;
DROP VIEW IF EXISTS MonthMoney CASCADE;
DROP VIEW IF EXISTS AllPayment CASCADE;
DROP VIEW IF EXISTS MonthAverage CASCADE;
DROP VIEW IF EXISTS Answer CASCADE; 
DROP VIEW IF EXISTS Pairs CASCADE;

-- Define views for your intermediate steps here:

-- Ride completed
CREATE VIEW RequestX AS
SELECT *
FROM Request R
WHERE EXISTS ( 
SELECT * 
FROM Dropoff 
WHERE Dropoff.request_id = R.request_id);

-- All months
CREATE VIEW Months AS
SELECT DISTINCT TO_CHAR(RequestX.datetime, 'YYYY MM') as months
FROM RequestX;

-- All Pairs of month and client
CREATE VIEW Pairs AS
SELECT client_id, months
FROM Client, Months;

-- All billed client
CREATE VIEW BilledClient AS
SELECT amount, client_id, TO_CHAR(RequestX.datetime, 'YYYY MM') as months
FROM RequestX NATURAL JOIN Billed;

-- Billed Client group by month and id
CREATE VIEW MonthMoney AS
SELECT client_id, months, SUM(amount) as total
FROM BilledClient
GROUP BY client_id, months;

-- All payments by clients on all months
CREATE VIEW AllPayment AS
SELECT client_id, months,COALESCE(total, 0) as total
FROM MonthMoney NATURAL RIGHT JOIN Pairs;

-- Month Average
CREATE VIEW MonthAverage AS
SELECT AVG(total) as monavg, months
FROM MonthMoney
GROUP By months;

-- Answer
CREATE VIEW Answer AS
SELECT client_id, A.months as month, total,
CASE WHEN A.total >= monavg THEN 'at or above' ELSE 'below' END as comparision
FROM AllPayment A, MonthAverage M
WHERE A.months = M.months;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
SELECT * FROM Answer;
