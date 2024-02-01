USE DATABASE DB_SL_EP_LAB;

USE SCHEMA DST;
USE WAREHOUSE WH_LAB_ENG;

/*CREATE OR REPLACE STAGE DST_STAGE
URL = 'azure://landingzonestlastage.blob.core.windows.net/eng-lab/data/raw/ep/DST/' 
	CREDENTIALS = ( AZURE_SAS_TOKEN = 'xxxxx')
    FILE_FORMAT = ( TYPE = JSON)
	DIRECTORY = ( ENABLE = false );
*/

CREATE OR REPLACE TABLE DST_COUNTRIES AS
    select distinct t.value:CountryCode::String as CountryCode, t.value:Names:Name:"$"::String as CountryName, t.value:Names:Name:"@LanguageCode"::String as LanguageCode
    from 
    @DST_STAGE (pattern=>'.*countries.*[.]json') r,
    LATERAL FLATTEN( INPUT => r.$1:CountryResource:Countries:Country ) t;

--SELECT * FROM DST_COUNTRIES order by COUNTRYNAME;

CREATE OR REPLACE TABLE DST_AIRCRAFTS AS
    select distinct 
    t.value:AircraftCode::String as AircraftCode,
    t.value:AirlineEquipCode::String as AirlineEquipCode, 
    t.value:Names:Name:"$"::String as Name, 
    t.value:Names:Name:"@LanguageCode"::String as LanguageCode
    from 
    @DST_STAGE (pattern=>'.*aircraft.*[.]json') r,
    LATERAL FLATTEN( INPUT => r.$1:AircraftResource:AircraftSummaries:AircraftSummary ) t;

--select * from DST_AIRCRAFTS

CREATE OR REPLACE TABLE DST_CITIES AS
select
    t.value:Airports:"AirportCode"::Array as AirportCode,
    t.value:CityCode::String as CityCode,
    t.value:CountryCode::String as CountryCode,
    t.value:Names:Name:"$"::String as Name,
    t.value:Names:Name:"@LanguageCode"::String as LanguageCode,
    t.value:TimeZoneId::String as TimeZoneId,
    t.value:UtcOffset::String as UtcOffset
from
    @DST_STAGE (pattern=>'.*cities.*[.]json') r,
    LATERAL FLATTEN( INPUT => r.$1:CityResource:Cities:City ) t;

select * from dst_cities where AIRPORTCODE is not null order by LENGTH(AIRPORTCODE) desc

    
CREATE OR REPLACE TABLE DST_AIRPORTS AS
select
    t.value:AirportCode::String as AirportCode,
    t.value:CityCode::String as CityCode,
    t.value:CountryCode::String as CountryCode,
    t.value:LocationType::String as LocationType,
    t.value:Names:Name:"$"::String as Name,
    t.value:Names:Name:"@LanguageCode"::String as LanguageCode,
    t.value:Position:Coordinate:"Latitude"::String as Latitude,
    t.value:Position:Coordinate:"Longitude"::String as Longitude,
    t.value:timeZoneId::String as timeZoneId,
    t.value:UtcOffset::String as UtcOffset
from @DST_STAGE (pattern=>'.*airports.*[.]json') r,
    LATERAL FLATTEN( INPUT => r.$1:AirportResource:Airports:Airport ) t;

--select * from dst_airports

CREATE OR REPLACE TABLE DST_AIRLINES AS
select 
    t.value:AirlineID::String as AirlineID,
    t.value:Names:Name:"$"::String as Name,
    t.value:Names:Name:"@LanguageCode"::String as LanguageCode,
    t.value:AirlineID_ICAO::String as Airline_ICAO
from @DST_STAGE (pattern=>'.*airlines.*[.]json') r,
LATERAL FLATTEN( INPUT => r.$1:AirlineResource:Airlines:Airline ) t;

--select * from DST_AIRLINES


CREATE OR REPLACE TABLE DST_FLIGHT_SCHEDULES AS
select
    t.value,
    t.value:airline::String as AirlineID,
    t.value:flightNumber::String as flightNumber,
    t.value:legs[0]:serviceType::String as serviceType,
    t.value:legs[0]:aircraftType::String as aircraftType,
    t.value:legs[0]:aircraftArrivalTimeLT::number as aircraftArrivalTimeLT,
    t.value:legs[0]:aircraftOwner::String as aircraftOwner,
    t.value:legs[0]:destination::String as destination,
    t.value:legs[0]:origin::String as origin,
    t.value:periodOfOperationLT:"daysOfOperation"::number as daysOfOperation,
    t.value:periodOfOperationLT:"endDate"::String as enDate,
    t.value:periodOfOperationLT:"startDate"::String as startDate
from
    @DST_STAGE (pattern=>'.*flightschedules_.*[.]json') r,
LATERAL FLATTEN( INPUT => r.$1 ) t;

select * from DST_FLIGHT_SCHEDULES






    
    