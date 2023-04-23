-- Demonstration on how to use the <@> operator to compute the distance in miles
-- between two points on the globe.  Cool!

-- Use \i to import this file into psql.

-- Here we define a "schema" where we can put our little example and keep it
-- separate from other things in your database.
-- Notice that the search path includes "public".  That is necessary
-- in order to make the <@> operator work.

DROP SCHEMA IF EXISTS distance cascade;
CREATE SCHEMA distance;
SET SEARCH_PATH TO distance, public;

-- Here we define a table and store locations in it.  
-- Locations are specified as longitude and latitude (in that order) 
-- in degrees, using the geo_loc type, like in A2.

-- The psql documentation explains that "Points are taken as 
-- (longitude, latitude) and not vice versa because longitude is closer 
-- to the intuitive idea of x-axis and latitude to y-axis."

DROP DOMAIN IF EXISTS geo_loc;
CREATE DOMAIN geo_loc AS point 
   DEFAULT NULL
   CHECK (
      VALUE[0] BETWEEN -180.0 AND 180.0 
         AND
      VALUE[1] BETWEEN -90.0 AND 90.0 
   );

CREATE TABLE Place (
   name varchar(30) PRIMARY KEY,
   location geo_loc NOT NULL
) ;

INSERT INTO Place VALUES
   ('highclere castle', '(-1.361, 51.3267)'),
   ('dower house', '(-0.4632, 51.3552)'),
   ('eaton centre', '(-79.3803, 43.654)'),
   ('cn tower', '(-79.3871, 43.6426)'),
   ('north york civic centre', '(-79.4146, 43.7673)'),
   ('pearson international airport', '(-79.6306, 43.6767)'),
   ('utsc', '(-79.1856, 43.7836)');

-- Let's just observe what is in the table.
SELECT * FROM Place;

-- And here's the big punchline:
-- We can use the <@> operator to compare pairs of locations and compute the 
-- distance between them in miles. This distance is "as the crow flies", 
-- that is, it is computed without regard to where the streets are.  We will
-- use that notion of distance in Assignment 2.
-- Here, we compute the distance between every pair of locations.
SELECT p1.name AS start, 
       p2.name AS finish, 
       p1.location <@> p2.location AS distance
FROM Place p1, Place p2
WHERE p1.name < p2.name;
