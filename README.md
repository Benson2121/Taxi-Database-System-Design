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

## Part 1: SQL Queries General requirements

To ensure that your query results match the form expected by the autotester (attribute types and order, for instance), We are providing a schema for the result of each query. These can be found in files q1.sql, q2.sql, . . . , q10.sql. You must add your solution code for each query to the corresponding file. Make sure that each file is entirely self-contained, and does not depend on any other files; each will be run separately on a fresh database instance, and so (for example) any views you create in q1.sql will not be accessible in q5.sql.

### The queries

These queries are quite complex, and we have tried to specify them precisely. If behaviour is not specified in a particular case, we will not test that case.

Design your queries with the following in mind:

 1. When we say that a client had a ride, or a driver gave a ride we mean that the ride was completed, that is, it has gone from request through to drop-off.
 
 2. The date of a ride is the date on which it was requested. (The drop-off might have a later date if the ride began just before midnight, for example.) Similarly, the month of a ride and the year of a ride are determined by the date on which it was requested.
 
 3. When we refer to a month we mean a specific month and year combination, such as January 2022, rather than just January.

 4. We will assume the following constraints hold:

 5. The end time of a shift is after its start time. 
  
    – A shift will have at least one row in table Location, recorded at the start of the shift, and it may have more. Each additional row for a shift indicates an updated location for the driver, and will have a datetime that occurs between the shift start time and the shift end time (inclusive).

    – The request, dispatch, pickup and dropoff for any given ride occur in that order in time, and each step is after (not at the same time) as the one before.

    – No dispatch can be recorded for a driver while they have another ride that has not been completed.

    – No ride request can be recorded for a client if they have another ride request that has not lead to a completed ride. If it weren’t costly to enforce these restrictions, we would express them as constraints.

# Part 2: Embedded SQL

Imagine an Uber app that drivers, passengers and dispatchers log in to. The different kinds of users have different features available. The app has a graphical user-interface and is written in Python, but ultimately it has to connect to the database where the core data is stored. Some of the features will be implemented by Python methods that are merely a wrapper around a SQL query, allowing input to come from gestures the user makes on the app, like button clicks, and output to go to the screen via the graphical user-interface. Other app features will include computation that can’t be done, or can’t be done conveniently, in SQL.

For Part 2 of this assignment, you will write several methods that the app would need. It would need many more, but we’ll restrict ourselves to just enough to give you practise with psycopg2 and to demonstrate the need to get Python involved, not only because it can provide a nicer user-interface than postgreSQL, but because of the expressive power of Python.
