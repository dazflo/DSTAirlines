USE DATABASE DB_SL_EP_LAB;

USE SCHEMA DST;
USE WAREHOUSE WH_LAB_ENG;

ALTER SESSION SET TIMEZONE = 'UTC';


--------------------------------------
--------------AIRCRAFTS---------------
CREATE OR REPLACE TABLE F_DST_3NF_AIRCRAFTS AS
    SELECT DISTINCT
        t.value:AircraftCode::String as AIRCRAFTCODE,
        t.value:Names:Name:"$"::String as AIRCRAFTNAME
    FROM 
        DST_RAW_AIRCRAFTS r,
        LATERAL FLATTEN( INPUT => r.$1:AircraftResource:AircraftSummaries:AircraftSummary ) t;

ALTER TABLE F_DST_3NF_AIRCRAFTS ADD PRIMARY KEY (AIRCRAFTCODE);


--------------------------------------
--------------COUNTRIES---------------

CREATE OR REPLACE TABLE F_DST_3NF_COUNTRIES AS
    SELECT DISTINCT
        t.value:CountryCode::String as COUNTRYCODE,
        t.value:Names:Name:"$"::String as COUNTRYNAME
    FROM 
        DST_RAW_COUNTRIES r,
        LATERAL FLATTEN( INPUT => r.$1:CountryResource:Countries:Country ) t;

ALTER TABLE F_DST_3NF_COUNTRIES ADD PRIMARY KEY (COUNTRYCODE);

--------------------------------------
--------------TIMEZONES---------------

CREATE OR REPLACE TABLE F_DST_3NF_TIMEZONES AS
    SELECT DISTINCT
        t.value:TimeZoneId::String as TIMEZONEID,
        t.value:UtcOffset::String as UTCOFFSET
    FROM DST_RAW_AIRPORTS r,
        LATERAL FLATTEN( INPUT => r.$1:AirportResource:Airports:Airport ) t;

ALTER TABLE F_DST_3NF_TIMEZONES ADD PRIMARY KEY (TIMEZONEID);


--------------------------------------
---------------CITIES-----------------
CREATE OR REPLACE TABLE F_DST_3NF_CITIES AS
    SELECT DISTINCT
        t.value:CityCode::String as CITYCODE,
        t.value:Names:Name:"$"::String as CITYNAME,
        t.value:CountryCode::String as COUNTRYCODE,
        t.value:TimeZoneId::String as TIMEZONEID
    FROM 
        DST_RAW_CITIES r,
        LATERAL FLATTEN( INPUT => r.$1:CityResource:Cities:City ) t;

ALTER TABLE F_DST_3NF_CITIES ADD PRIMARY KEY (CITYCODE);
ALTER TABLE F_DST_3NF_CITIES ADD FOREIGN KEY (COUNTRYCODE) REFERENCES F_DST_3NF_COUNTRIES(COUNTRYCODE);
ALTER TABLE F_DST_3NF_CITIES ADD FOREIGN KEY (TIMEZONEID) REFERENCES F_DST_3NF_TIMEZONES(TIMEZONEID);


--------------------------------------
--------------AIRPORTS----------------
CREATE OR REPLACE TABLE F_DST_3NF_AIRPORTS AS
    SELECT DISTINCT
        t.value:AirportCode::String as AIRPORTCODE,
        t.value:CityCode::String as CITYCODE,
        t.value:LocationType::String as LOCATIONTYPE,
        t.value:Names:Name:"$"::String as AIRPORTNAME,
        t.value:Position:Coordinate:"Latitude"::FLOAT as LATITUDE,
        t.value:Position:Coordinate:"Longitude"::FLOAT as LONGITUDE
    FROM DST_RAW_AIRPORTS r,
        LATERAL FLATTEN( INPUT => r.$1:AirportResource:Airports:Airport ) t;

ALTER TABLE F_DST_3NF_AIRPORTS ADD PRIMARY KEY (AIRPORTCODE);
ALTER TABLE F_DST_3NF_AIRPORTS ADD FOREIGN KEY (CITYCODE) REFERENCES F_DST_3NF_CITIES(CITYCODE);

--------------------------------------
-------------TIMESTATUS---------------

CREATE OR REPLACE TABLE F_DST_3NF_TIME_STATUS (
    TIMESTATUSCODE VARCHAR PRIMARY KEY,
    TIMESTATUSDEFINITION VARCHAR
);
INSERT INTO F_DST_3NF_TIME_STATUS (TIMESTATUSCODE, TIMESTATUSDEFINITION) 
VALUES 
    ('FE', 'Flight Early'),
    ('NI', 'Next Information'),
    ('OT', 'Flight On Time'),
    ('DL', 'Flight Delayed'),
    ('NO', 'No status');


--------------------------------------
------------FLIGHTSTATUS--------------
CREATE OR REPLACE TABLE F_DST_3NF_FLIGHT_STATUS (
    FLIGHTSTATUSCODE VARCHAR PRIMARY KEY,
    FLIGHTSTATUSDEFINITION VARCHAR
);
INSERT INTO F_DST_3NF_FLIGHT_STATUS (FLIGHTSTATUSCODE, FLIGHTSTATUSDEFINITION) 
VALUES 
    ('CD', 'Flight Cancelled'),
    ('DP', 'Flight Departed'),
    ('LD', 'Flight Landed'),
    ('RT', 'Flight Rerouted'),
    ('NA', 'No status');
    
--------------------------------------
--------------AIRLINES----------------
CREATE OR REPLACE TABLE F_DST_3NF_AIRLINES AS
SELECT DISTINCT
    t.value:AirlineID::String as AIRLINEID,
    t.value:Names:Name:"$"::String as AIRLINENAME,
    t.value:AirlineID_ICAO::String as AIRLINEID_ICAO
FROM DST_RAW_AIRLINES r,
LATERAL FLATTEN( INPUT => r.$1:AirlineResource:Airlines:Airline ) t;

ALTER TABLE F_DST_3NF_AIRLINES ADD PRIMARY KEY (AIRLINEID);


--------------------------------------
--------------COUNTRIES---------------
CREATE OR REPLACE TABLE F_DST_3NF_COUNTRIES AS
    SELECT DISTINCT
        t.value:CountryCode::String as COUNTRYCODE,
        t.value:Names:Name:"$"::String as COUNTRYNAME
    FROM 
        DST_RAW_COUNTRIES r,
        LATERAL FLATTEN( INPUT => r.$1:CountryResource:Countries:Country ) t;

ALTER TABLE F_DST_3NF_COUNTRIES ADD PRIMARY KEY (COUNTRYCODE);


--------------------------------------
------------SERVICE_TYPES-------------
CREATE OR REPLACE TABLE F_DST_3NF_SERVICE_TYPES (
    SERVICETYPECODE VARCHAR PRIMARY KEY,
    SERVICETYPEDESC VARCHAR,
    SERVICETYPEAPP VARCHAR,
    SERVICETYPECONTENT VARCHAR
);

INSERT INTO F_DST_3NF_SERVICE_TYPES (SERVICETYPECODE, SERVICETYPEDESC, SERVICETYPEAPP, SERVICETYPECONTENT) 
VALUES 
    ('F', 'Loose Loaded cargo and/or preloaded devices', 'Scheduled', 'Cargo/Mail'),
    ('M', 'Mail only', 'Scheduled', 'Cargo/Mail'),
    ('H', 'Cargo and/or Mail', 'Charter', 'Cargo/Mail'),
    ('V', 'Service operated by Surface Vehicle', 'Scheduled', 'Cargo/Mail'),
    ('A', 'Cargo/Mail', 'Additional Flights', 'Cargo/Mail'),
    ('W', 'Military', 'Others', 'Not specific'),
    ('E', 'Special (FAA/Government)', 'Others', 'Not specific'),
    ('D', 'General Aviation, non-commercial (e.g. school training) and empty flights', 'General Aviation', 'Not specific'),
    ('N', 'Business Aviation/Air Taxi', 'Business Aviation', 'Not specific'),
    ('I', 'State/Diplomatic (Chapter 6 only)', 'Others', 'Not specific'),
    ('X', 'Technical Stop (for Chapter 6 applications only)', 'Others', 'Not specific'),
    ('K', 'Crew training (other than GABA operators)', 'Others', 'Not specific'),
    ('T', 'Technical Test', 'Others', 'Not specific'),
    ('P', 'Non-revenue (Positioning/Ferry/Delivery/Demo)', 'Others', 'Not specific'),
    ('J', 'Normal Service', 'Scheduled', 'Passenger'),
    ('C', 'Passenger Only', 'Charter', 'Passenger'),
    ('B', 'Shuttle Mode', 'Additional Flights', 'Passenger'),
    ('G', 'Normal Service', 'Additional Flights', 'Passenger'),
    ('S', 'Shuttle Mode', 'Scheduled', 'Passenger'),
    ('U', 'Service operated by Surface Vehicle Chapter 6 only-Air Ambulance/Humanitarian', 'Scheduled', 'Passenger Non-specific'),
    ('R', 'Passenger/Cargo in Cabin (mixed configuration aircraft)', 'Additional Flights', 'Passenger/Cargo'),
    ('Q', 'Passenger/Cargo in Cabin (mixed configuration aircraft)', 'Scheduled', 'Passenger/Cargo'),
    ('L', 'Passenger and Cargo and/or Mail', 'Charter', 'Passenger/Cargo/Mail'),
    ('O', 'Charter requiring special handling (e.g., Migrants/immigrant Flights)', 'Charter', 'Special Handling');



--------------------------------------
---------------FLIGHTS----------------

CREATE OR REPLACE FUNCTION DST_ConvertNumberToTime(minutes INT)
  RETURNS TIME
  AS
  $$
  SELECT CASE
           WHEN minutes = 1440 THEN TO_TIME('0')
           ELSE TO_TIME(CONCAT(
                  LPAD(FLOOR(minutes / 60), 2, '0'),
                  ':',
                  LPAD(minutes % 60, 2, '0')
                ))
         END
  $$;


CREATE OR REPLACE TABLE F_DST_3NF_FLIGHTS AS
    WITH Schedule AS (
        SELECT
            t.value,
            REPLACE(CONCAT(t.value:airline::String, t.value:flightNumber::String, TIMESTAMP_FROM_PARTS(TO_DATE(t.value:periodOfOperationUTC:"startDate"::String, 'DDMONYY'), DST_ConvertNumberToTime(l.value:aircraftDepartureTimeUTC::number))), ' ') as FLIGHTID,
            t.value:flightNumber::varchar as FLIGHTNUMBER,
            t.value:airline::String as AIRLINEID,
            l.value:serviceType::String as SERVICETYPECODE,
            l.value:aircraftType::String as AIRCRAFTCODE,
            l.value:origin::String as DEPARTUREAIRPORTCODE,
            --l.value:sequenceNumber::number as SEQUENCENUMBER,
            DST_ConvertNumberToTime(l.value:aircraftDepartureTimeUTC::number) as DEPARTUREDATETIMEUTC,
            l.value:destination::String as ARRIVALAIRPORTCODE,
            DST_ConvertNumberToTime(l.value:aircraftArrivalTimeUTC::number) as ARRIVALDATETIMEUTC,
            l.value:aircraftOwner::String AS AIRCRAFTOWNER
        FROM
            DST_RAW_FLIGHTSCHEDULES r,
            LATERAL FLATTEN( INPUT => r.$1 ) t,
            LATERAL FLATTEN(INPUT => t.value:legs) l
    ),
    Status AS (
        SELECT
            REPLACE(CONCAT(f.value:MarketingCarrier:AirlineID::String, f.value:MarketingCarrier:FlightNumber::number, TO_CHAR(f.value:Departure:ScheduledTimeUTC:DateTime::TIMESTAMP_NTZ)), ' ') as FLIGHTID,
            f.value:MarketingCarrier:AirlineID::String AS MARKETINGCARRIERAIRLINEID,
            f.value:MarketingCarrier:FlightNumber::String AS MARKETINGCARRIERFLIGHTNUMBER,
            f.value:OperatingCarrier:AirlineID::String AS OPERATINGCARRIERAIRLINEID,
            f.value:OperatingCarrier:FlightNumber::String AS OPERATINGCARRIERFLIGHTNUMBER,
            f.value:Departure:AirportCode::String AS DEPARTUREAIRPORTCODE,
            f.value:Departure:ScheduledTimeUTC:DateTime::TIMESTAMP_TZ AS DEPARTUREDATETIMEUTC,
            f.value:Departure:ActualTimeUTC:DateTime::TIMESTAMP_TZ AS DEPARTUREACTUALDATETIMEUTC,
            f.value:Departure:TimeStatus:Code::String AS DEPARTURETIMESTATUSCODE,
            f.value:Arrival:AirportCode::String AS ARRIVALAIRPORTCODE,
            f.value:Arrival:ScheduledTimeUTC:DateTime::TIMESTAMP_TZ AS ARRIVALDATETIMEUTC,
            f.value:Arrival:ActualTimeUTC:DateTime::TIMESTAMP_TZ AS ARRIVALACTUALDATETIMEUTC,
            --f.value:Arrival:EstimatedTimeUTC:DateTime::TIMESTAMP_TZ AS ARRIVALESTIMATEDDATETIMEUTC,
            f.value:Arrival:TimeStatus:Code::String ARRIVALTIMESTATUSCODE,
            f.value:FlightStatus:Code::String FLIGHTSTATUSCODE
        FROM
            DST_RAW_FLIGHTSTATUS r,
            LATERAL FLATTEN(INPUT => r.$1:"FlightStatusResource":Flights:Flight) f
    )
    SELECT st.FLIGHTID, sc.SERVICETYPECODE, sc.FLIGHTNUMBER, sc.AIRCRAFTCODE, sc.AIRCRAFTOWNER, st.DEPARTUREAIRPORTCODE, st.DEPARTUREDATETIMEUTC, st.DEPARTUREACTUALDATETIMEUTC, st.DEPARTURETIMESTATUSCODE, st.ARRIVALAIRPORTCODE, st.ARRIVALDATETIMEUTC, st.ARRIVALACTUALDATETIMEUTC, st.ARRIVALTIMESTATUSCODE, st.OPERATINGCARRIERAIRLINEID, st.OPERATINGCARRIERFLIGHTNUMBER, st.MARKETINGCARRIERAIRLINEID, st.MARKETINGCARRIERFLIGHTNUMBER, st.FLIGHTSTATUSCODE
    FROM Schedule sc
    JOIN Status st ON sc.FLIGHTID = st.FLIGHTID;

ALTER TABLE F_DST_3NF_FLIGHTS ADD PRIMARY KEY (FLIGHTID);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (SERVICETYPECODE) REFERENCES F_DST_3NF_SERVICE_TYPES(SERVICETYPECODE);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (AIRCRAFTCODE) REFERENCES F_DST_3NF_AIRCRAFTS(AIRCRAFTCODE);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (DEPARTUREAIRPORTCODE) REFERENCES F_DST_3NF_AIRPORTS(AIRPORTCODE);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (DEPARTURETIMESTATUSCODE) REFERENCES F_DST_3NF_TIME_STATUS(TIMESTATUSCODE);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (ARRIVALTIMESTATUSCODE) REFERENCES F_DST_3NF_TIME_STATUS(TIMESTATUSCODE);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (AIRCRAFTOWNER) REFERENCES F_DST_3NF_AIRLINES(AIRLINEID);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (OPERATINGCARRIERAIRLINEID) REFERENCES F_DST_3NF_AIRLINES(AIRLINEID);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (MARKETINGCARRIERAIRLINEID) REFERENCES F_DST_3NF_AIRLINES(AIRLINEID);
ALTER TABLE F_DST_3NF_FLIGHTS ADD FOREIGN KEY (FLIGHTSTATUSCODE) REFERENCES F_DST_3NF_FLIGHT_STATUS(FLIGHTSTATUSCODE);

select * from F_DST_3NF_FLIGHTS where DEPARTUREAIRPORTCODE = 'AAL' and DEPARTUREDATETIMEUTC > '2024-02-14 05:45:00.000 +0000';
--LH60912024-02-0505:45:00.000	J	6091	32N	SK	AAL	2024-02-05 05:45:00.000 +0000	2024-02-05 05:40:00.000 +0000	FE	CPH	2024-02-05 06:35:00.000 +0000		FE	SK	1202	LH	6091	DP

SELECT
    f.value,
            REPLACE(CONCAT(f.value:MarketingCarrier:AirlineID::String, f.value:MarketingCarrier:FlightNumber::number, TO_CHAR(f.value:Departure:ScheduledTimeUTC:DateTime::TIMESTAMP_NTZ)), ' ') as FLIGHTID,
            f.value:MarketingCarrier:AirlineID::String AS MARKETINGCARRIERAIRLINEID,
            f.value:MarketingCarrier:FlightNumber::String AS MARKETINGCARRIERFLIGHTNUMBER,
            f.value:OperatingCarrier:AirlineID::String AS OPERATINGCARRIERAIRLINEID,
            f.value:OperatingCarrier:FlightNumber::String AS OPERATINGCARRIERFLIGHTNUMBER,
            f.value:Departure:AirportCode::String AS DEPARTUREAIRPORTCODE,
            f.value:Departure:ScheduledTimeUTC:DateTime::TIMESTAMP_TZ AS DEPARTUREDATETIMEUTC,
            COALESCE(f.value:Departure:ActualTimeUTC:DateTime::TIMESTAMP_TZ, f.value:Departure:EstimatedTimeUTC:DateTime::TIMESTAMP_TZ)  AS DEPARTUREACTUALDATETIMEUTC,
            f.value:Departure:TimeStatus:Code::String AS DEPARTURETIMESTATUSCODE,
            f.value:Arrival:AirportCode::String AS ARRIVALAIRPORTCODE,
            f.value:Arrival:ScheduledTimeUTC:DateTime::TIMESTAMP_TZ AS ARRIVALDATETIMEUTC,
            COALESCE(f.value:Arrival:ActualTimeUTC:DateTime::TIMESTAMP_TZ,  f.value:Arrival:EstimatedTimeUTC:DateTime::TIMESTAMP_TZ)AS ARRIVALACTUALDATETIMEUTC,
            --f.value:Arrival:EstimatedTimeUTC:DateTime::TIMESTAMP_TZ AS ARRIVALESTIMATEDDATETIMEUTC,
            f.value:Arrival:TimeStatus:Code::String ARRIVALTIMESTATUSCODE,
            f.value:FlightStatus:Code::String FLIGHTSTATUSCODE
        FROM
            DST_RAW_FLIGHTSTATUS r,
            LATERAL FLATTEN(INPUT => r.$1:"FlightStatusResource":Flights:Flight) f
        WHERE 
            MARKETINGCARRIERFLIGHTNUMBER = '6091'
        AND DEPARTUREDATETIMEUTC = '2024-02-05 05:45:00.000 +0000';
            
            
