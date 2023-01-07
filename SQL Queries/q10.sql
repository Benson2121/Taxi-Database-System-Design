-- Rainmakers.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q10 CASCADE;

CREATE TABLE q10(
    driver_id INTEGER,
    month CHAR(2),
    mileage_2020 FLOAT,
    billings_2020 FLOAT,
    mileage_2021 FLOAT,
    billings_2021 FLOAT,
    mileage_increase FLOAT,
    billings_increase FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS Months CASCADE;
DROP VIEW IF EXISTS DriverRide CASCADE;
DROP VIEW IF EXISTS Billing CASCADE;
DROP VIEW IF EXISTS Billing2020 CASCADE;
DROP VIEW IF EXISTS MonthBilling2020 CASCADE;
DROP VIEW IF EXISTS Billing2021 CASCADE;
DROP VIEW IF EXISTS MonthBilling2021 CASCADE;
DROP VIEW IF EXISTS Distances CASCADE;
DROP VIEW IF EXISTS Mile2020 CASCADE;
DROP VIEW IF EXISTS MonthMile2020 CASCADE;
DROP VIEW IF EXISTS Mile2021 CASCADE;
DROP VIEW IF EXISTS MonthMile2021 CASCADE;
DROP VIEW IF EXISTS AllMonth CASCADE;
DROP VIEW IF EXISTS EverythingWorker CASCADE;
DROP VIEW IF EXISTS Answer CASCADE;


-- Define views for your intermediate steps here:

-- 1-12 months
CREATE VIEW Monthes AS
SELECT to_char(generate_series(1, 12), 'FM09') AS month;

-- Driver PairMonth
CREATE VIEW Months AS
SELECT driver_id, month
FROM Monthes, Driver;

-- DriverRide
CREATE VIEW DriverRide AS
SELECT driver_id, Request.request_id, source, destination,
TO_CHAR(Request.datetime, 'YYYY') as year,
TO_CHAR(Request.datetime, 'MM') as month
FROM ClockedIn, Dispatch, Request
WHERE ClockedIn.shift_id = Dispatch.shift_id and
Request.request_id = Dispatch.request_id;

-- Billing
CREATE VIEW Billing AS
SELECT *
FROM DriverRide NATURAL JOIN Billed;

-- 2020 billing
CREATE VIEW Billing2020 AS
SELECT driver_id, month, SUM(amount) as billings_2020
FROM Billing
WHERE year = '2020'
GROUP BY driver_id, month;

-- 2020 billing all months
CREATE VIEW MonthBilling2020 AS
SELECT driver_id, month, COALESCE(billings_2020, 0) as billings_2020
FROM Billing2020 NATURAL RIGHT JOIN Months;

-- 2021 billing
CREATE VIEW Billing2021 AS
SELECT driver_id, month, SUM(amount) as billings_2021
FROM Billing
WHERE year = '2021'
GROUP BY driver_id, month;

-- 2020,2021 billing all months
CREATE VIEW MonthBilling2021 AS
SELECT driver_id, month, billings_2020, COALESCE(billings_2021, 0) as billings_2021
FROM Billing2021 NATURAL RIGHT JOIN MonthBilling2020;

-- Distance
CREATE VIEW Distances AS
SELECT driver_id, request_id, source <@> destination as distance, year, month
FROM Billing;

-- 2020 mileage
CREATE VIEW Mile2020 AS
SELECT driver_id, month, SUM(distance) as mileage_2020
FROM Distances
WHERE year = '2020'
GROUP BY driver_id, month;

-- 2020 + 2021 billing + 2020 mile all months
CREATE VIEW MonthMile2020 AS
SELECT driver_id, month, billings_2020, COALESCE(mileage_2020, 0) as mileage_2020, billings_2021
FROM Mile2020 NATURAL RIGHT JOIN MonthBilling2021;

-- 2021 mileage
CREATE VIEW Mile2021 AS
SELECT driver_id, month, SUM(distance) as mileage_2021
FROM Distances
WHERE year = '2021'
GROUP BY driver_id, month;

-- 2020 and 2021 everything all months
CREATE VIEW AllMonth AS
SELECT driver_id, month, billings_2020, mileage_2020, billings_2021, COALESCE(mileage_2021, 0) as mileage_2021
FROM Mile2021 NATURAL RIGHT JOIN MonthMile2020;

-- 2020 and 2021 everything, excluding some drivers
CREATE VIEW EverythingWorker AS
SELECT driver_id, month, mileage_2020,billings_2020,mileage_2021,billings_2021,
mileage_2021 - mileage_2020 as mileage_increase, billings_2021 - billings_2020 as billings_increase
FROM AllMonth;

-- Answer
CREATE VIEW Answer AS
SELECT driver_id, month, COALESCE(mileage_2020, 0) as mileage_2020,  COALESCE(billings_2020, 0) as billings_2020,
 COALESCE(mileage_2021, 0) as mileage_2021, COALESCE(billings_2021, 0) as billings_2021,
 COALESCE(mileage_increase, 0) as mileage_increase, COALESCE(billings_increase, 0) as billings_increase
FROM Driver NATURAL LEFT JOIN EverythingWorker;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q10
SELECT * FROM Answer;
