
  
CREATE TABLE table_to_delete as
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7
               

               
               SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';  --575MB, toast: 8192 byte 
               
  DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

--a) 37 seconds in total
--b) same as previously
               VACUUM FULL VERBOSE table_to_delete;
--c ) previously 575MB, now it is 383MB it decreased by 192MB
              
              
              drop table table_to_delete;  -- after this i could re-create the table_to_delete
              
                TRUNCATE table_to_delete; -- 1 second, 0 mb
                
--Assumption: The assumption of mine is that TRUNCATE operation is faster, however that basically removes the whole table's database, which may be not what we want in some case. 
                -- So truncate is perfect to clean all data inside a table, however with DELETE we can decide what to delete and what to keep, but that requieres more time
                -- I am not sure, but in some cases maybe it is more efficient to truncate the dataset and then insert it again.
--Answers in one place: 
-- DELETE operation took 37 seconds to execute and the table size was 575MB, after the DELETE operation it was 383MB so decreased by 192 MB  
-- TRUNCATE operation took 1 second to execute and the table size was 575MB, after the Truncate operation it us 0MB so decreased by 575
                
           
              