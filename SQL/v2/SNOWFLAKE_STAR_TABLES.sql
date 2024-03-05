USE DATABASE DB_SL_EP_LAB;

USE SCHEMA DST;
USE WAREHOUSE WH_LAB_ENG;

ALTER SESSION SET TIMEZONE = 'UTC';

--------------------------------------------------------------------------------
---------------------------DIMESION TABLES--------------------------------------
--------------------------------------

--------------------------------------
--------------AIRPORTS----------------

CREATE OR REPLACE TABLE F_DST_DIM_AIRPORTS AS
    SELECT
        a.AIRPORTCODE,
        a.AIRPORTNAME,
        a.LOCATIONTYPE,
        ci.CITYCODE,
        ci.CITYNAME,
        t.TIMEZONEID,
        t.UTCOFFSET,
        a.LATITUDE,
        a.LONGITUDE,
        co.COUNTRYCODE,
        co.COUNTRYNAME
    FROM F_DST_3NF_AIRPORTS a
        INNER JOIN F_DST_3NF_CITIES ci ON a.CITYCODE=ci.CITYCODE
        INNER JOIN F_DST_3NF_COUNTRIES co ON  ci.COUNTRYCODE=co.COUNTRYCODE
        INNER JOIN F_DST_3NF_TIMEZONES t ON ci.TIMEZONEID=t.TIMEZONEID
    ;

ALTER TABLE F_DST_DIM_AIRPORTS ADD PRIMARY KEY (AIRPORTCODE);

CREATE OR REPLACE TABLE F_DST_DIM_AIRCRAFTS
    CLONE F_DST_3NF_AIRCRAFTS;

CREATE OR REPLACE TABLE F_DST_DIM_AIRLINES
    CLONE F_DST_3NF_AIRLINES;

CREATE OR REPLACE TABLE F_DST_DIM_SERVICE_TYPES
    CLONE F_DST_3NF_SERVICE_TYPES;

CREATE OR REPLACE TABLE F_DST_DIM_TIME_STATUS
    CLONE F_DST_3NF_TIME_STATUS;

CREATE OR REPLACE TABLE F_DST_DIM_FLIGHT_STATUS
    CLONE F_DST_3NF_FLIGHT_STATUS;


SET day_num = (SELECT DATEDIFF('day', '2023-01-01', '2024-03-01'));
CREATE OR REPLACE TABLE F_DST_DIM_DATE AS 
    WITH CTE_MY_DATE AS (
        SELECT DATEADD(DAY, SEQ4(), TO_DATE('2023-01-01')) AS MY_DATE
        FROM TABLE(GENERATOR(ROWCOUNT => $day_num))
    )
    SELECT 
        TO_CHAR(MY_DATE::DATE, 'YYYYMMDD') AS DATEID, 
        MY_DATE AS DATEFULL,
        YEAROFWEEKISO(MY_DATE) AS DATEYEAR,
        TO_CHAR(MY_DATE,'MMMM') AS DATEMONTH,
        WEEK(MY_DATE) AS DATEWEEK,
        CASE DAYOFWEEKISO(MY_DATE)
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
            WHEN 7 THEN 'Sunday'
         END AS DATEDAY
    FROM CTE_MY_DATE;

ALTER TABLE F_DST_DIM_DATE ADD PRIMARY KEY (DATEID);

--------------------------------------------------------------------------------
------------------------------FACT TABLE----------------------------------------
--------------------------------------
---------------FLIGHTS----------------

CREATE OR REPLACE TABLE F_DST_FACT_FLIGHTS AS
    SELECT
        FLIGHTID,
        --FLIGHTNUMBER, 
        SERVICETYPECODE, 
        AIRCRAFTCODE, 
        AIRCRAFTOWNER, 
        DEPARTUREAIRPORTCODE,
        DEPARTURETIMESTATUSCODE,
        TO_CHAR(DEPARTUREDATETIMEUTC, 'YYYYMMDD') AS DEPARTUREDATEID,
        DATEDIFF(minutes, DEPARTUREDATETIMEUTC, DEPARTUREACTUALDATETIMEUTC) AS DEPARTURETIMEGAP,
        ARRIVALAIRPORTCODE,
        ARRIVALTIMESTATUSCODE,
        TO_CHAR(ARRIVALDATETIMEUTC, 'YYYYMMDD') AS ARRIVALDATEID,
        DATEDIFF(minutes, ARRIVALDATETIMEUTC, ARRIVALACTUALDATETIMEUTC) AS ARRIVALTIMEGAP,
        DATEDIFF(minutes, DEPARTUREDATETIMEUTC, DEPARTUREACTUALDATETIMEUTC) + DATEDIFF(minutes, ARRIVALDATETIMEUTC, ARRIVALACTUALDATETIMEUTC) AS TOTALTIMEDIFF,
        OPERATINGCARRIERAIRLINEID,
        OPERATINGCARRIERFLIGHTNUMBER,
        MARKETINGCARRIERAIRLINEID,
        MARKETINGCARRIERFLIGHTNUMBER,
        FLIGHTSTATUSCODE
    FROM F_DST_3NF_FLIGHTS 
    ;

ALTER TABLE F_DST_FACT_FLIGHTS ADD PRIMARY KEY (FLIGHTID);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (DEPARTUREDATEID) REFERENCES F_DST_DIM_DATE(DATEID);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (ARRIVALDATEID) REFERENCES F_DST_DIM_DATE(DATEID);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (DEPARTUREAIRPORTCODE) REFERENCES F_DST_DIM_AIRPORTS(AIRPORTCODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (ARRIVALAIRPORTCODE) REFERENCES F_DST_DIM_AIRPORTS(AIRPORTCODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (AIRCRAFTCODE) REFERENCES F_DST_3NF_AIRCRAFTS(AIRCRAFTCODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (SERVICETYPECODE) REFERENCES F_DST_DIM_SERVICE_TYPES(SERVICETYPECODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (DEPARTURETIMESTATUSCODE) REFERENCES F_DST_DIM_TIME_STATUS(TIMESTATUSCODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (ARRIVALTIMESTATUSCODE) REFERENCES F_DST_DIM_TIME_STATUS(TIMESTATUSCODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (FLIGHTSTATUSCODE) REFERENCES F_DST_DIM_FLIGHT_STATUS(FLIGHTSTATUSCODE);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (MARKETINGCARRIERAIRLINEID) REFERENCES F_DST_DIM_AIRLINES(AIRLINEID);
ALTER TABLE F_DST_FACT_FLIGHTS ADD FOREIGN KEY (OPERATINGCARRIERAIRLINEID) REFERENCES F_DST_DIM_AIRLINES(AIRLINEID);

SELECT * FROM F_DST_FACT_FLIGHTS WHERE OPERATINGCARRIERAIRLINEID != MARKETINGCARRIERAIRLINEID AND DEPARTUREDATEID = '20240210';