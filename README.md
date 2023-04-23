# Taxi-Database-System-Design
University of Toronto 

CSC343: Introduction to Database - Fall 2022

Professor: Diane Horton

## Learning Goals

The purpose of this assignment is to give you practise writing complex stand-alone SQL queries, experience using psycopg2 to embed SQL queries in a Python program, and a sense of why a blend of SQL and a general-purpose language can be the best solution for some problems.

By the end of this project you will be able to:

• read and interpret a novel schema written in SQL

• write complex queries in SQL

• design datasets to test a SQL query thoroughly

• quickly find and understand needed information in the postgreSQL documentation 

• embed SQL in a high-level language using psycopg2 and Python

• recognize limits to the expressive power of standard SQL Please read this assignment thoroughly before you proceed.

## Introduction

In this project, we will work with a database to support a ride-sharing / taxi company like Uber or Lyft. Keep in mind that your code for this assignment must work on any database instance (including ones with empty tables) that satisfies the schema.

## Schema
1. **Client** 

    -- A person who is registered as a client of the company's driving
services.
 - client_id integer PRIMARY KEY,
 - surname varchar(25) NOT NULL,
 - firstname varchar(15) NOT NULL,
 - email varchar(30) DEFAULT NULL

2. **Driver**

    -- A driver for the company. dob is their date of birth.
    
    -- Trained indicates whether or not they attended the optional 
 new-driver training. 

    -- Vehicle is the vehicle that this driver 
 gives rides in. A driver can have only one vehicle associated with them.

 - driver_id integer PRIMARY KEY,
 - surname varchar(25) NOT NULL,
 - firstname varchar(15) NOT NULL,
 - dob date NOT NULL,
 - address varchar NOT NULL,
 - vehicle varchar(8) NOT NULL,
 - trained boolean NOT NULL DEFAULT false



## Part 1: SQL Queries General requirements

To ensure that your query results match the form expected by the autotester (attribute types and order, for instance), We are providing a schema for the result of each query. These can be found in files q1.sql, q2.sql, . . . , q10.sql. You must add your solution code for each query to the corresponding file. Make sure that each file is entirely self-contained, and does not depend on any other files; each will be run separately on a fresh database instance, and so (for example) any views you create in q1.sql will not be accessible in q5.sql.

### The queries

These queries are quite complex, and we have tried to specify them precisely. If behaviour is not specified in a particular case, we will not test that case.

Design your queries with the following in mind:

 1. When we say that a client had a ride, or a driver gave a ride we mean that the ride was completed, that is, it has gone from request through to drop-off.
 
 2. The date of a ride is the date on which it was requested. (The drop-off might have a later date if the ride began just before midnight, for example.) Similarly, the month of a ride and the year of a ride are determined by the date on which it was requested.
 
 3. When we refer to a month we mean a specific month and year combination, such as January 2022, rather than just January.

 4. We will assume the following constraints hold:

 - The end time of a shift is after its start time. 
  
 - A shift will have at least one row in table Location, recorded at the start of the shift, and it may have more. Each additional row for a shift indicates an updated location for the driver, and will have a datetime that occurs between the shift start time and the shift end time (inclusive).

 - The request, dispatch, pickup and dropoff for any given ride occur in that order in time, and each step is after (not at the same time) as the one before.

 - No dispatch can be recorded for a driver while they have another ride that has not been completed.

 - No ride request can be recorded for a client if they have another ride request that has not lead to a completed ride. If it weren’t costly to enforce these restrictions, we would express them as constraints.

Write SQL queries for each of the following:

1. **Months** 
  - For each client, report their client ID, email address, and the number of different months in which they have had a ride. 
  - January 2021 and January 2022, for example, would count as two different months.

2. **Lure them back** 
  - The company wants to lure back clients who formerly spent a lot on rides, but whose ridership has been diminishing.
  - Find clients who had rides before 2020 costing at least $500 in total, have had between 1 and 10 rides (inclusive) in 2020, and have had fewer rides in 2021 than in 2020.

3. **Rest bylaw**
  - A break is the time elapsed between one drop-off by a driver and their next pick-up on that same day (even if the pickup of the first ride was on a different day). 
  - The duration of a ride is the time elapsed between pick-up and drop-off (If a ride has a pick-up time recorded but no drop-off time, it is incomplete and does not have a duration). 
  - The total ride duration of a driver for a day is the sum of all ride durations of that driver for rides whose pickup and drop-off are both recorded and were both on that day.
  - A city bylaw says that no driver may have three consecutive days where on each of these days they had a total ride duration of 12 hours or more yet never had a break lasting more than 15 minutes. Keep in mind that a driver could have a day with a single ride and nothing that counts as a break. They would by definition violate the bylaw on that day if the ride was long enough.
  - Find every driver who broke the bylaw. Report their driver ID, the date on the first of the three days when they broke the bylaw, their total ride duration summed over the three days, and their total break time summed over the three days.
  - If a driver has broken the bylaw on more than one occasion, report one row for each. Don’t eliminate overlapping three-day stretches. For example, if a driver had four long workdays in a row, they may have broken the bylaw on the sequence of days d1, d2 and d3, and also on the sequence of days d2, d3, and d4. There would be two rows in your table to describe this.
  - Your query should return an empty table if no driver ever broke the bylaw.

4. **Do drivers improve?** 
  - The company offers optional training to new drivers during their first 5 days on the job, and wants to know whether it helps, or whether drivers get better on their own with experience.
  - A driver’s first day on the job is the first day on which they gave a ride. Consider those drivers who have had the training and have given a ride (one or more) on at least 10 different days. Let’s define their early average to be their average rating in their first 5 days on the job, and their late average to be their average rating after their first 5 days on the job. Report the number of such drivers, the average of their early averages, and the average of their late averages. Do the same for those drivers who have not had the training but have given a ride (one or more) on at least 10 different days.
  - A driver’s first 5 days on the job are the first 5 days on which they gave a ride. These need not be consecutive days.
  - NULL values should not contribute to an average. The average function in SQL takes care of this for you. 
  - A driver’s early average is NULL if none of the rides in their first 5 days were rated. Their late average is NULL if none of the rides they have given after their first 5 work days were rated.

5. **Bigger and Smaller spenders**
  - For each client, and for each month in which someone had a ride (whether or not this client had any rides in that month), report the total amount the client was billed for rides they had that month and whether their total was at or above the average for that month or was below average. 
  - The average for a month is defined to be the average total for all clients who completed at least one ride in that month.

6. **Frequent riders**
  - Find the 3 clients with the greatest number of rides in a single year and the 3 clients with the smallest number of rides in a single year. Consider only years in which some client had a ride.
  - There may be ties in number of rides. You should include all clients with the highest number of rides, all clients with the second highest number of rides, and all client with the third highest number of rides. Do the same for clients with the lowest 3 values for number of rides.
  - As a result, your answer may actually have more than 6 rows. A single client could appear more than once with the same number of rides, if they had that number of rides in two different years and that number was among the top or bottom 3, or both, but don’t repeat the same client-year-rides combination.

7. **Ratings histogram**
  - We need to know how well-rated each driver is. Create a table that is, essentially, a histogram of driver ratings.
  - The table should have one row for each driver, and one column for each possible rating (1 through 5). The value in each cell should be the number of times that driver has been rated with that rating.

8. **Scratching backs?**
  - We want to know how the ratings that a client gives compare to the ratings that the same client gets. Let’s say there is a reciprocal rating for a ride if both the driver rated the client for that ride and the client rated the driver for that ride.
  - For each client who has at least one reciprocal rating, report the number of reciprocal ratings they have, and average difference between their rating of the driver and the driver’s rating of them for a ride.

9. **Consistent raters**
  - Report the client ID and email address of every client who has rated every driver they have ever had a ride with. (They needn’t have rated every ride with that driver.) 
  - Don’t include clients who have never had a ride.

10. **Rainmakers**
  - The company wants to know which drivers are earning a lot for the company, and how this has changed over time.
  - The crow-flies distance of a ride is the number of miles between the source and the destination given in the ride request, “as the crow flies”, that is, without concern given to where the streets are. You can compute the distance between two points using the operator <@>, as described in distance-example.txt. 
  - A driver’s total crow-flies mileage for a month is the total crow-flies distance of rides that they gave in that month. A driver’s total billings for a month is the total amount billed for rides they gave in that month.
  - For every driver, report (a) their total crow-flies mileage and total billings per month for completed billed rides for each month in 2020, (b) the same information for 2021, and (c) the differences between the corresponding months in the two years.

# Part 2: Embedded SQL

Imagine an Uber app that drivers, passengers and dispatchers log in to. The different kinds of users have different features available. The app has a graphical user-interface and is written in Python, but ultimately it has to connect to the database where the core data is stored. Some of the features will be implemented by Python methods that are merely a wrapper around a SQL query, allowing input to come from gestures the user makes on the app, like button clicks, and output to go to the screen via the graphical user-interface. Other app features will include computation that can’t be done, or can’t be done conveniently, in SQL.

For Part 2 of this assignment, you will write several methods that the app would need. It would need many more, but we’ll restrict ourselves to just enough to give you practise with psycopg2 and to demonstrate the need to get Python involved, not only because it can provide a nicer user-interface than postgreSQL, but because of the expressive power of Python.
