"""
Part2 of csc343 A2: Code that could be part of a ride-sharing application.
csc343, Fall 2022
University of Toronto

--------------------------------------------------------------------------------
This file is Copyright (c) 2022 Diane Horton and Marina Tawfik.
All forms of distribution, whether as given or with any changes, are
expressly prohibited.
--------------------------------------------------------------------------------
"""
import psycopg2 as pg
import psycopg2.extensions as pg_ext
from typing import Optional, List, Any
from datetime import datetime
import re


class GeoLoc:
    """A geographic location.

    === Instance Attributes ===
    longitude: the angular distance of this GeoLoc, east or west of the prime
        meridian.
    latitude: the angular distance of this GeoLoc, north or south of the
        Earth's equator.

    === Representation Invariants ===
    - longitude is in the closed interval [-180.0, 180.0]
    - latitude is in the closed interval [-90.0, 90.0]

    >>> where = GeoLoc(-25.0, 50.0)
    >>> where.longitude
    -25.0
    >>> where.latitude
    50.0
    """
    longitude: float
    latitude: float

    def __init__(self, longitude: float, latitude: float) -> None:
        """Initialize this geographic location with longitude <longitude> and
        latitude <latitude>.
        """
        self.longitude = longitude
        self.latitude = latitude

        assert -180.0 <= longitude <= 180.0, \
            f"Invalid value for longitude: {longitude}"
        assert -90.0 <= latitude <= 90.0, \
            f"Invalid value for latitude: {latitude}"


class Assignment2:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of ride-sharing information.

    Representation invariants:
    - The database to which connection is established conforms to the schema
      in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Assignment2 instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path to
        uber, public.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-dianeh", "dianeh", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("nonsense", "silly", "junk")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=uber,public"
            )
            # This allows psycopg2 to learn about our custom type geo_loc.
            self._register_geo_loc()
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close the database connection.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection failed.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-dianeh", "dianeh", "")
        True
        >>> a2.disconnect()
        True
        >>> a2.disconnect()
        False
        """
        try:
            if not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    # ======================= Driver-related methods ======================= #

    def clock_in(self, driver_id: int, when: datetime, geo_loc: GeoLoc) -> bool:
        """Record the fact that the driver with id <driver_id> has declared that
        they are available to start their shift at date time <when> and with
        starting location <geo_loc>. Do so by inserting a row in both the
        ClockedIn and the Location tables.

        If there are no rows are in the ClockedIn table, the id of the shift
        is 1. Otherwise, it is the maximum current shift id + 1.

        A driver can NOT start a new shift if they have an ongoing shift.

        Return True if clocking in was successful, False otherwise. I.e., do NOT
        throw an error if clocking in fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cur = self.connection.cursor()
        try:
            cur.execute(""" SELECT *
                            FROM ClockedIn 
                            WHERE driver_id = %s and NOT EXISTS ( 
                            SELECT * 
                            FROM ClockedOut 
                            WHERE ClockedIn.shift_id = ClockedOut.shift_id 
                            );""", [driver_id])  
            if cur.rowcount > 0:
                return False
            cur.execute(""" SELECT * 
                            FROM Driver 
                            WHERE driver_id = %s;""", [driver_id])
            if cur.rowcount == 0:
                return False
            cur.execute("""SELECT COALESCE(MAX(shift_id) + 1, 1) 
                            FROM ClockedIn;""")
            if cur.rowcount > 0:
                shift = cur.fetchall()[0][0]
            else:
                shift = 1
            cur.execute("INSERT INTO ClockedIN VALUES(%s, %s, %s);",
                        (shift, driver_id, when))
            cur.execute("INSERT INTO Location VALUES(%s, %s, %s);",  
                        (shift, when, geo_loc))
            return True
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return False

    def pick_up(self, driver_id: int, client_id: int, when: datetime) -> bool:
        """Record the fact that the driver with driver id <driver_id> has
        picked up the client with client id <client_id> at date time <when>.

        If (a) the driver is currently on an ongoing shift, and
           (b) they have been dispatched to pick up the client, and
           (c) the corresponding pick-up has not been recorded
        record it by adding a row to the Pickup tab le, and return True.
        Otherwise, return False.

        You may not assume that the dispatch actually occurred, but you may
        assume there is no more than one outstanding dispatch entry for this
        driver and this client.

        Return True if the operation was successful, False otherwise. I.e.,
        do NOT throw an error if this pick up fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cur = self.connection.cursor()
        try:
            # Check driver
            cur.execute(""" SELECT * 
                            FROM Driver 
                            WHERE driver_id = %s;""", [driver_id])
            if cur.rowcount == 0:
                return False
            # Check Client
            cur.execute(""" SELECT * 
                             FROM Client
                             WHERE client_id = %s;""", [client_id])
            if cur.rowcount == 0:
                return False
            # get the request_id for the client
            cur.execute(""" CREATE TEMPORARY VIEW TargetRequest AS
                            SELECT request_id
                            FROM Client NATURAL JOIN Request
                            WHERE client_id = %s
                            ORDER BY datetime DESC
                            LIMIT 1;
                        """, [client_id])
            # check request is in dispatch
            cur.execute(""" SELECT request_id
                            FROM Dispatch
                            WHERE request_id =
                            (
                            SELECT request_id
                            FROM TargetRequest
                            );
                        """)
            if cur.rowcount == 0:
                return False
            # locate driver to the request 
            cur.execute(""" SELECT *
                            FROM Dispatch, ClockedIN
                            WHERE request_id = (SELECT request_id
                                                FROM TargetRequest)
                                  and driver_id = %s
                                  and Dispatch.shift_id = ClockedIn.shift_id;
                        """, [driver_id])
            if cur.rowcount == 0:
                return False
            # Tell whether the request_id is in the pickup
            cur.execute(""" SELECT *
                            FROM Pickup
                            WHERE request_id  = (SELECT request_id
                                                 FROM TargetRequest);
                        """)
            
            if cur.rowcount > 0:
                return False

            
            cur.execute(""" INSERT INTO Pickup VALUES(
                                (SELECT request_id
                                FROM TargetRequest), %s);
                        """, [when])
            return True

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            raise ex
            return False

    # ===================== Dispatcher-related methods ===================== #

    def dispatch(self, nw: GeoLoc, se: GeoLoc, when: datetime) -> None:
        """Dispatch drivers to the clients who have requested rides in the area
        bounded by <nw> and <se>, such that:
            - <nw> is the longitude and latitude in the northwest corner of this
            area
            - <se> is the longitude and latitude in the southeast corner of this
            area
        and record the dispatch time as <when>.

        Area boundaries are inclusive. For example, the point (4.0, 10.0)
        is considered within the area defined by
                    NW = (1.0, 10.0) and SE = (25.0, 2.0)
        even though it is right at the upper boundary of the area.

        NOTE: + longitude values decrease as we move further west, and
                latitude values decrease as we move further south.
              + You may find the PostgreSQL operators @> and <@> helpful.

        For all clients who have requested rides in this area (i.e., whose
        request has a source location in this area) and a driver has not
        been dispatched to them yet, dispatch drivers to them one at a time,
        from the client with the highest total billings down to the client
        with the lowest total billings, or until there are no more drivers
        available.

        Only drivers who meet all of these conditions are dispatched:
            (a) They are currently on an ongoing shift.
            (b) They are available and are NOT currently dispatched or on
            an ongoing ride.
            (c) Their most recent recorded location is in the area bounded by
            <nw> and <se>.
        When choosing a driver for a particular client, if there are several
        drivers to choose from, choose the one closest to the client's source
        location. In the case of a tie, any one of the tied drivers may be
        dispatched.

        Dispatching a driver is accomplished by adding a row to the Dispatch
        table. The dispatch car location is the driver's most recent recorded
        location. All dispatching that results from a call to this method is
        recorded to have happened at the same time, which is passed through
        parameter <when>.

        If an exception occurs during dispatch, rollback ALL changes.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cur = self.connection.cursor()
        try:
            
            # target client
            cur.execute(""" CREATE TEMPORARY VIEW TargetClient AS
                            SELECT *
                            FROM Request R
                            WHERE source[0] >= %s
                            and source[0] <= %s
                            and source[1] <= %s
                            and source[1] >= %s
                            and NOT EXISTS(
                            SELECT *
                            FROM DISPATCH D
                            WHERE R.request_id = D.request_id);
                        """, (nw.longitude, se.longitude, nw.latitude, se.latitude))
            # Bills for all clients
            cur.execute(""" CREATE TEMPORARY VIEW AllClientBill AS
                            SELECT client_id, COALESCE(SUM(amount), 0) as total
                            FROM Request NATURAL LEFT JOIN Billed
                            GROUP BY client_id;
                        """)
            # Target Client Bills
            cur.execute(""" CREATE TEMPORARY VIEW TargetClientBill AS
                            SELECT request_id, client_id, total, datetime, source
                            FROM TargetClient NATURAL JOIN AllClientBill
                            ORDER BY total DESC;
                        """)
            # Target Driver shift that is currently clockedIn
            cur.execute(""" CREATE TEMPORARY VIEW CurrentlyClockedINDriver AS
                            SELECT shift_id
                            FROM ClockedIn CI
                            WHERE NOT EXISTS(
                            SELECT *
                            FROM ClockedOut CO
                            WHERE CI.shift_id = CO.shift_id);
                        """)
            
            # Target clockedInDriver shift that haven't had a dispatch in that shift
            cur.execute(""" CREATE TEMPORARY VIEW alloweddriver1 AS
                            SELECT shift_id
                            FROM CurrentlyClockedINDriver C
                            WHERE NOT EXISTS(
                            SELECT *
                            FROM Dispatch D
                            WHERE C.shift_id = D.shift_id
                            );
                        """)
            
            # Drivers shift who are on the request(did not finish the last request)
            # All the shifts that does not have a dropoff
            cur.execute(""" CREATE TEMPORARY VIEW OnRequestDriver AS
                            SELECT shift_id
                            FROM Dispatch Di
                            WHERE NOT EXISTS(
                            SELECT *
                            FROM Dropoff Dr
                            WHERE Di.request_id = Dr.request_id);
                        """)
            
            # Target clockedIn driver that is clockedIn and that have some
            # dispatches but they finished all the request and they are free
            cur.execute(""" CREATE TEMPORARY VIEW allowedDriver2 AS
                            (SELECT *
                            FROM CurrentlyClockedInDriver)
                            EXCEPT (SELECT * FROM OnRequestDriver);
                        """)

            # Allowed Driver Shift combined
            cur.execute(""" CREATE TEMPORARY VIEW AllowedDriver12 AS
                            (SELECT * FROM allowedDriver1) UNION
                            (SELECT * FROM allowedDriver2);
                        """)
            
            # allowed Driver all location
            cur.execute(""" CREATE TEMPORARY VIEW AllowedDriverAllLocation AS
                            SELECT shift_id, datetime, location
                            FROM AllowedDriver12 NATURAL JOIN Location;
                        """)
            # allowed Driver most recent datetime
            cur.execute(""" CREATE TEMPORARY VIEW AllowedDriverDatetime AS
                            SELECT shift_id, MAX(datetime) as datetime
                            FROM AllowedDriverAllLocation
                            GROUP BY shift_id;
                            """)
            # allowed Driver most recent location
            cur.execute(""" CREATE TEMPORARY VIEW AllowedDriverlocation AS
                            SELECT shift_id, datetime, location as source
                            FROM AllowedDriverAllLocation NATURAL JOIN AllowedDriverDatetime;
                            """)
            
            # target Driver that with in the range
            cur.execute(""" CREATE TEMPORARY VIEW TargetDriver AS
                           SELECT shift_id, source as location
                           FROM AllowedDriverlocation
                           WHERE source[0] >= %s
                            and source[0] <= %s
                            and source[1] <= %s
                            and source[1] >= %s;
                       """, (nw.longitude, se.longitude, nw.latitude, se.latitude))
            # Execute
            cur.execute(""" SELECT *
                            FROM TargetClientBill;
                                  """)
            if cur.rowcount > 0:
                clients = cur.fetchall()
                for row in clients:
                    request_id = row[0]
                    source = row[4]
                    cur.execute(""" SELECT shift_id, location
                                    FROM TargetDriver
                                    WHERE (location <@> %s) <= ALL (
                                    SELECT location <@> %s
                                    FROM TargetDriver);
                                    """, [source, source])
                    if cur.rowcount > 0:
                        all_cloest_driver = cur.fetchall()
                        cloest_driver_shift_id = all_cloest_driver[0][0]
                        cloest_driver_loc = all_cloest_driver[0][1]
                        cur.execute(""" INSERT INTO Dispatch VALUES (%s, %s, %s, %s);
                                    """ ,
                                    (request_id, cloest_driver_shift_id, cloest_driver_loc, when))
                    else:
                        break

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            raise ex
            return

    # =======================     Helper methods     ======================= #

    # You do not need to understand this code. See the doctest example in
    # class GeoLoc (look for ">>>") for how to use class GeoLoc.

    def _register_geo_loc(self) -> None:
        """Register the GeoLoc type and create the GeoLoc type adapter.

        This method
            (1) informs psycopg2 that the Python class GeoLoc corresponds
                to geo_loc in PostgreSQL.
            (2) defines the logic for quoting GeoLoc objects so that you
                can use GeoLoc objects in calls to execute.
            (3) defines the logic of reading GeoLoc objects from PostgreSQL.

        DO NOT make any modifications to this method.
        """

        def adapt_geo_loc(loc: GeoLoc) -> pg_ext.AsIs:
            """Convert the given geographical location <loc> to a quoted
            SQL string.
            """
            longitude = pg_ext.adapt(loc.longitude)
            latitude = pg_ext.adapt(loc.latitude)
            return pg_ext.AsIs(f"'({longitude}, {latitude})'::geo_loc")

        def cast_geo_loc(value: Optional[str], *args: List[Any]) \
                -> Optional[GeoLoc]:
            """Convert the given value <value> to a GeoLoc object.

            Throw an InterfaceError if the given value can't be converted to
            a GeoLoc object.
            """
            if value is None:
                return None
            m = re.match(r"\(([^)]+),([^)]+)\)", value)

            if m:
                return GeoLoc(float(m.group(1)), float(m.group(2)))
            else:
                raise pg.InterfaceError(f"bad geo_loc representation: {value}")

        with self.connection, self.connection.cursor() as cursor:
            cursor.execute("SELECT NULL::geo_loc")
            geo_loc_oid = cursor.description[0][1]

            geo_loc_type = pg_ext.new_type(
                (geo_loc_oid,), "GeoLoc", cast_geo_loc
            )
            pg_ext.register_type(geo_loc_type)
            pg_ext.register_adapter(GeoLoc, adapt_geo_loc)


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like all the doctest
    # examples (see ">>>" in the method and class docstrings) to be run
    # and checked.
    # import doctest
    # doctest.testmod()
    # sample_test_function()
