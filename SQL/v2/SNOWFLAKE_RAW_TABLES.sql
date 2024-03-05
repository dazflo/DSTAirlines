USE DATABASE DB_SL_EP_LAB;

USE SCHEMA DST;
USE WAREHOUSE WH_LAB_ENG;

---------------------------------------
-------------- COUNTRIES --------------
CREATE OR REPLACE TABLE DST_RAW_COUNTRIES (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);
    
COPY INTO DST_RAW_COUNTRIES
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/references/countries)
PATTERN ='.*countries.*[.]json';


---------------------------------------
--------------- CITIES ----------------
CREATE OR REPLACE TABLE DST_RAW_CITIES (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);

COPY INTO DST_RAW_CITIES
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/references/cities)
PATTERN ='.*cities.*[.]json';

-- LH581


---------------------------------------
------------- AIRPORTS ----------------
CREATE OR REPLACE TABLE DST_RAW_AIRPORTS (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);

COPY INTO DST_RAW_AIRPORTS
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/references/airports)
PATTERN ='.*airports.*[.]json';


---------------------------------------
------------- AIRLINES ----------------
CREATE OR REPLACE TABLE DST_RAW_AIRLINES (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);

COPY INTO DST_RAW_AIRLINES
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/references/airlines)
PATTERN ='.*airlines.*[.]json';

---------------------------------------
------------- AIRCRAFTS ---------------
CREATE OR REPLACE TABLE DST_RAW_AIRCRAFTS (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);

COPY INTO DST_RAW_AIRCRAFTS
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/references/aircrafts)
PATTERN ='.*aircraft.*[.]json';


---------------------------------------
----------- FLIGHT SCHEDULES ----------
CREATE OR REPLACE TABLE DST_RAW_FLIGHTSCHEDULES (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);

COPY INTO DST_RAW_FLIGHTSCHEDULES
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/flightsschedules)
PATTERN ='.*flightschedules.*[.]json';


---------------------------------------
----------- FLIGHT STATUS ------------
CREATE OR REPLACE TABLE DST_RAW_FLIGHTSTATUS (
    value VARIANT,
    metadata_filename TEXT,
    metadata_file_row_number BIGINT,
    dt_ingestion_timestamp TIMESTAMP
);

COPY INTO DST_RAW_FLIGHTSTATUS
FROM
    (select 
        $1::variant, 
        metadata$filename::varchar, 
        metadata$file_row_number::bigint,
        current_timestamp::timestamp
    from
        @DST_STAGE/flightsstatus)
PATTERN ='.*flightsstatus.*[.]json';