-- {{ config(materialized='table') }}

-- SELECT * 
-- FROM {{ source('dst_externals', 'aircrafts') }}

-- -- COPY INTO DB_SL_EP_LAB.DST.DST_RAW_AIRCRAFT
-- --     FROM ( 
-- --         SELECT
-- --             $1::variant as value,
-- --             metadata$filename::varchar as metadata_filename,
-- --             metadata$file_row_number::bigint as metadata_file_row_number,
-- --             current_timestamp::timestamp as dt_ingestion_timestamp
-- --         FROM {{ source('dst_raw_dim', 'aircrafts') }}
-- --     )