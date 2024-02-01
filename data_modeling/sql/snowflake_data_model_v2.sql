USE DATABASE DB_SL_EP_LAB;

USE SCHEMA DST;
USE WAREHOUSE WH_LAB_ENG;


/**********************************************************************************************/
/****************************************TABLE DEFINITION**************************************/
/**********************************************************************************************/


/*****************AIRPORTS*****************/
CREATE OR REPLACE TABLE DST_DIM_AIRPORTS (
    ID_DIM_AIRPORTS NUMBER IDENTITY PRIMARY KEY,
    AIRPORTCODE VARCHAR,
    NAME VARCHAR,
    LATITUDE NUMBER,
    LONGITUDE NUMBER,
    CITY_NAME VARCHAR,
    COUNTRY_NAME VARCHAR,
    LOCATIONTYPE VARCHAR
)


/*******************FLIGHT_SCHEDULES************************/
CREATE OR REPLACE TABLE DST_DIM_FLIGHT_SCHEDULES (
    ID_DIM_FLIGHT_SCHEDULES NUMBER IDENTITY PRIMARY KEY,
    FLIGHTNUMBER NUMBER,
    AIRCRAFTTYPE VARCHAR,
    AIRCRAFTARRIVALTIMELT NUMBER,
    AIRCRAFTOWNER VARCHAR,
    DESTINATION VARCHAR,
    ORIGIN VARCHAR,
    DAYSOFOPERATION NUMBER,
    AIRCRAFT_NAME VARCHAR,
    AIRLINE_NAME VARCHAR,
    SERVICETYPE VARCHAR,
    ENDATE VARCHAR,
    STARTDATE VARCHAR
)


/****************************************************************************************/
/**************************************DATA INGESTION************************************/
/****************************************************************************************/


/*****************AIRPORTS*****************/
MERGE INTO DST_DIM_AIRPORTS AS TGT
USING (
    SELECT DISTINCT
        A.AIRPORTCODE,
        A.NAME,
        A.LATITUDE,
        A.LONGITUDE,
        A.CITYCODE,
        B.NAME AS "CITY_NAME",
        C.COUNTRYNAME AS "COUNTRY_NAME",
        D.LOCATIONTYPE
    FROM
        DST_3NF_AIRPORTS A
    LEFT JOIN
        (SELECT DISTINCT * FROM DST_3NF_CITIES) B ON A.CITYCODE = B.CITYCODE
    LEFT JOIN
        DST_3NF_COUNTRIES C ON A.COUNTRYCODE = C.COUNTRYCODE
    LEFT JOIN
        DST_3NF_LOCATIONTYPE D ON A.LOCATIONTYPE = D.ID_LOCATIONTYPE
) 
    AS SRC
ON (TGT.AIRPORTCODE = SRC.AIRPORTCODE AND COALESCE(TGT.CITY_NAME, 'N/A') = COALESCE(SRC.CITY_NAME, 'N/A') AND TGT.LATITUDE = SRC.LATITUDE AND TGT.LONGITUDE = SRC.LONGITUDE)
WHEN MATCHED THEN 
UPDATE SET
    TGT.LATITUDE = SRC.LATITUDE,
    TGT.LONGITUDE = SRC.LONGITUDE,
    TGT.NAME = SRC.NAME,
    TGT.CITY_NAME = SRC.CITY_NAME,
    TGT.COUNTRY_NAME = SRC.COUNTRY_NAME,
    TGT.LOCATIONTYPE = SRC.LOCATIONTYPE
WHEN NOT MATCHED THEN
    INSERT(TGT.AIRPORTCODE, TGT.LATITUDE, TGT.LONGITUDE, TGT.NAME, TGT.CITY_NAME, TGT.COUNTRY_NAME, TGT.LOCATIONTYPE) VALUES (SRC.AIRPORTCODE, SRC.LATITUDE, SRC.LONGITUDE, SRC.NAME, SRC.CITY_NAME, SRC.COUNTRY_NAME, SRC.LOCATIONTYPE)


/*******************FLIGHT_SCHEDULES************************/
MERGE INTO DST_DIM_FLIGHT_SCHEDULES AS TGT
USING (
    SELECT 
        A.FLIGHTNUMBER,
        A.AIRCRAFTTYPE,
        A.AIRCRAFTARRIVALTIMELT,
        A.AIRCRAFTOWNER,
        A.DESTINATION,
        A.ORIGIN,
        A.DAYSOFOPERATION,
        A.ENDATE,
        A.STARTDATE,
        B.SERVICETYPE,
        C.NAME AS AIRCRAFT_NAME,
        D.NAME AS AIRLINE_NAME
    FROM
        DST_3NF_FLIGHT_SCHEDULES A
    INNER JOIN
        DST_3NF_SERVICETYPE B ON A.SERVICETYPE = B.ID_SERVICETYPE
    INNER JOIN
        DST_3NF_AIRCRAFTS C ON A.AIRCRAFTTYPE = C.AIRCRAFTCODE
    INNER JOIN
        DST_3NF_AIRLINES D ON A.AIRLINEID = D.AIRLINEID
WHERE
    TO_DATE(CONCAT(right(startdate,2), '-', 
                    CASE
                        WHEN substr(startdate,3,3) = 'JAN' THEN 1
                        WHEN substr(startdate,3,3) = 'FEB' THEN 2
                        WHEN substr(startdate,3,3) = 'MAR' THEN 3
                        WHEN substr(startdate,3,3) = 'APR' THEN 4
                        WHEN substr(startdate,3,3) = 'MAY' THEN 5
                        WHEN substr(startdate,3,3) = 'JUN' THEN 6
                        WHEN substr(startdate,3,3) = 'JUL' THEN 7
                        WHEN substr(startdate,3,3) = 'AUG' THEN 8
                        WHEN substr(startdate,3,3) = 'SEP' THEN 9
                        WHEN substr(startdate,3,3) = 'OCT' THEN 10
                        WHEN substr(startdate,3,3) = 'NOV' THEN 11
                        WHEN substr(startdate,3,3) = 'DEC' THEN 12
                    END, '-', left(startdate,2)), 'YY-MM-DD') BETWEEN TO_DATE('24-01-01', 'YY-MM-DD') AND TO_DATE('31-03-01', 'YY-MM-DD')
)
AS SRC
ON (SRC.AIRLINE_NAME = TGT.AIRLINE_NAME AND SRC.STARTDATE = TGT.STARTDATE AND SRC.FLIGHTNUMBER = TGT.FLIGHTNUMBER)
WHEN MATCHED THEN
UPDATE SET
    TGT.FLIGHTNUMBER = SRC.FLIGHTNUMBER,
    TGT.AIRCRAFTTYPE = SRC.AIRCRAFTTYPE,
    TGT.AIRCRAFTARRIVALTIMELT = SRC.AIRCRAFTARRIVALTIMELT,
    TGT.AIRCRAFTOWNER = SRC.AIRCRAFTOWNER,
    TGT.DESTINATION = SRC.DESTINATION,
    TGT.ORIGIN = SRC.ORIGIN,
    TGT.DAYSOFOPERATION = SRC.DAYSOFOPERATION,
    TGT.ENDATE = SRC.ENDATE,
    TGT.STARTDATE = SRC.ENDATE,
    TGT.SERVICETYPE = SRC.SERVICETYPE,
    TGT.AIRCRAFT_NAME = SRC.AIRCRAFT_NAME,
    TGT.AIRLINE_NAME = SRC.AIRLINE_NAME
WHEN NOT MATCHED THEN
INSERT(TGT.FLIGHTNUMBER, TGT.AIRCRAFTTYPE, TGT.AIRCRAFTARRIVALTIMELT, TGT.AIRCRAFTOWNER, TGT.DESTINATION, TGT.ORIGIN, TGT.DAYSOFOPERATION, TGT.ENDATE, TGT.STARTDATE, TGT.SERVICETYPE, TGT.AIRCRAFT_NAME, TGT.AIRLINE_NAME) VALUES(SRC.FLIGHTNUMBER, SRC.AIRCRAFTTYPE, SRC.AIRCRAFTARRIVALTIMELT, SRC.AIRCRAFTOWNER, SRC.DESTINATION, SRC.ORIGIN, SRC.DAYSOFOPERATION, SRC.ENDATE, SRC.STARTDATE, SRC.SERVICETYPE, SRC.AIRCRAFT_NAME, SRC.AIRLINE_NAME)




/************************************************************************************************/
/**************************************CREATION OF TIME TABLE************************************/
/************************************************************************************************/
CREATE OR REPLACE TABLE "DST_DIM_TIME"
AS
WITH "GAPLESS_ROW_NUMBERS" AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY seq4()) - 1 as "ROW_NUMBER" 
  FROM TABLE(GENERATOR(rowcount => 366 * (2025 - 2023)) ) 
)
SELECT
    ROW_NUMBER AS "ID_DIM_TIME",
    DATEADD('day', "ROW_NUMBER", DATE('2023-01-01')) as "DATE"
  , EXTRACT(year FROM "DATE") as "YEAR"
  , EXTRACT(month FROM "DATE") as "MONTH"
  , EXTRACT(day FROM "DATE") as "DAY"
  , EXTRACT(dayofweek FROM "DATE") as "DAY_OF_WEEK"
  , EXTRACT(dayofyear FROM "DATE") as "DAY_OF_YEAR"
  , EXTRACT(quarter FROM "DATE") as "QUARTER"
  , MIN("DAY_OF_YEAR") OVER (PARTITION BY "YEAR", "QUARTER") as "QUARTER_START_DAY_OF_YEAR"
  , "DAY_OF_YEAR" - "QUARTER_START_DAY_OF_YEAR" + 1 as "DAY_OF_QUARTER"
  , TO_VARCHAR("DATE", 'MMMM') as "MONTH_NAME"
  , TO_VARCHAR("DATE", 'MON') as "MONTH_NAME_SHORT"
  , CASE "DAY_OF_WEEK"
     WHEN 0 THEN 'Sunday'
     WHEN 1 THEN 'Monday'
     WHEN 2 THEN 'Tuesday'
     WHEN 3 THEN 'Wednesday'
     WHEN 4 THEN 'Thursday'
     WHEN 5 THEN 'Friday'
     WHEN 6 THEN 'Saturday'
    END as "DAY_NAME"
  , TO_VARCHAR("DATE", 'DY') as "DAY_NAME_SHORT"
  , EXTRACT(yearofweekiso FROM "DATE") as "ISO_YEAR"
  , EXTRACT(weekiso FROM "DATE") as "ISO_WEEK"
  , CASE
      WHEN "ISO_WEEK" <= 13 THEN 1
      WHEN "ISO_WEEK" <= 26 THEN 2
      WHEN "ISO_WEEK" <= 39 THEN 3
      ELSE 4
    END as "ISO_QUARTER"
  , EXTRACT(dayofweekiso FROM "DATE") as "ISO_DAY_OF_WEEK"
  , MAX("DAY_OF_YEAR") OVER (PARTITION BY "YEAR") as "DAYS_IN_YEAR"
  , "DAYS_IN_YEAR" - "DAY_OF_YEAR" as "DAYS_REMAINING_IN_YEAR"
FROM "GAPLESS_ROW_NUMBERS"
WHERE "YEAR" < 2025 


/************************************************************************************************/
/**************************************CREATION OF FACT TABLE************************************/
/************************************************************************************************/
CREATE OR REPLACE TABLE DST_DIM_FACT_FLIGHT_SCHEDULES (
    ID_DIM_FACT_FLIGHT_SCHEDULES NUMBER IDENTITY PRIMARY KEY,
    ID_DIM_FLIGHT_SCHEDULES NUMBER,
    ID_DIM_AIRPORTS NUMBER,
    ID_DIM_TIME NUMBER,
    AIRCRAFTARRIVALTIMELT NUMBER,
    DAYSOFOPERATION NUMBER
)


MERGE INTO DST_DIM_FACT_FLIGHT_SCHEDULES AS TGT
USING (
        SELECT DISTINCT        
        A.ID_DIM_FLIGHT_SCHEDULES,
        D.ID_DIM_AIRPORTS,
        E.ID_DIM_TIME,
        A.AIRCRAFTARRIVALTIMELT,
        A.DAYSOFOPERATION
    FROM
        DST_DIM_FLIGHT_SCHEDULES A
    INNER JOIN
        DST_DIM_AIRPORTS D ON A.ORIGIN = D.AIRPORTCODE
    INNER JOIN 
        DST_DIM_TIME E ON 
                TO_DATE(CONCAT(right(startdate,2), '-', 
                    CASE
                        WHEN substr(startdate,3,3) = 'JAN' THEN 1
                        WHEN substr(startdate,3,3) = 'FEB' THEN 2
                        WHEN substr(startdate,3,3) = 'MAR' THEN 3
                        WHEN substr(startdate,3,3) = 'APR' THEN 4
                        WHEN substr(startdate,3,3) = 'MAY' THEN 5
                        WHEN substr(startdate,3,3) = 'JUN' THEN 6
                        WHEN substr(startdate,3,3) = 'JUL' THEN 7
                        WHEN substr(startdate,3,3) = 'AUG' THEN 8
                        WHEN substr(startdate,3,3) = 'SEP' THEN 9
                        WHEN substr(startdate,3,3) = 'OCT' THEN 10
                        WHEN substr(startdate,3,3) = 'NOV' THEN 11
                        WHEN substr(startdate,3,3) = 'DEC' THEN 12
                    END, '-', left(startdate,2)), 'YY-MM-DD') = E.DATE
) AS SRC
ON (SRC.ID_DIM_FLIGHT_SCHEDULES = TGT.ID_DIM_FLIGHT_SCHEDULES AND SRC.ID_DIM_AIRPORTS = TGT.ID_DIM_AIRPORTS AND SRC.ID_DIM_TIME = TGT.ID_DIM_TIME)
WHEN MATCHED THEN
UPDATE SET
    TGT.AIRCRAFTARRIVALTIMELT = SRC.AIRCRAFTARRIVALTIMELT,
    TGT.DAYSOFOPERATION = SRC.DAYSOFOPERATION
WHEN NOT MATCHED THEN
    INSERT(TGT.ID_DIM_FLIGHT_SCHEDULES, TGT.ID_DIM_AIRPORTS, TGT.ID_DIM_TIME, TGT.AIRCRAFTARRIVALTIMELT, TGT.DAYSOFOPERATION) VALUES(SRC.ID_DIM_FLIGHT_SCHEDULES, SRC.ID_DIM_AIRPORTS, SRC.ID_DIM_TIME, SRC.AIRCRAFTARRIVALTIMELT, SRC.DAYSOFOPERATION)





