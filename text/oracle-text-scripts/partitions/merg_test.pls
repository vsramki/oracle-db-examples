-- This example shows how to do a "merge partition" equivalent with an Oracle Text index present,
-- without the application being offline for the time needed to recreate the index
-- on the newly merged partition

-- The basic technique is to create a separate table to which we copy all the data to be
-- merged.  We then create an index on that table, and when it is complete we swap it in 
-- using "EXCHANGE PARTITION ... INCLUDING INDEXES"


-- "drop table XXX" statements are included here so the code is re-runnable
-- they will produce errors on the first run

set echo on

-- create a partitioned base table

DROP TABLE bike_items;

CREATE TABLE bike_items 
( id      NUMBER,
  price   NUMBER,
  descrip VARCHAR2(40)
)
PARTITION BY RANGE (price)
( PARTITION p1 VALUES LESS THAN  (       10 ) TABLESPACE users,
  PARTITION p2 VALUES LESS THAN  (       50 ) TABLESPACE users,
  PARTITION p3 VALUES LESS THAN  (      100 ) TABLESPACE users,
  PARTITION p4 VALUES LESS THAN  ( maxvalue ) TABLESPACE users 
);

-- add some data to that table

INSERT INTO bike_items VALUES ( 1, 2.50,  'inner tube for MTB wheel');
INSERT INTO bike_items VALUES ( 2, 29,    'wheel, front, basic');
INSERT INTO bike_items VALUES ( 3, 75,    'wheel, front, top quality');
INSERT INTO bike_items VALUES ( 4, 1.99,  'valve caps, set of 4');
INSERT INTO bike_items VALUES ( 5, 15.99, 'seat');
INSERT INTO bike_items VALUES ( 6, 130,   'hydraulic disk brake, front wheel');
INSERT INTO bike_items VALUES ( 7, 25,    'v-type brake, rear wheel');
INSERT INTO bike_items VALUES ( 8, 750,   'full-suspension mountain bike');
INSERT INTO bike_items VALUES ( 9, 250,   'mountain bike frame');
INSERT INTO bike_items VALUES (10, 40,    'tires - pair');
INSERT INTO bike_items VALUES (11, 45,    'wheel, rear, basic');
INSERT INTO bike_items VALUES (12, 89.99, 'wheel, rear top quality');

COMMIT;

-- create a local partitioned index on the table

CREATE INDEX bike_items_idx ON bike_items (descrip)
INDEXTYPE IS ctxsys.context
LOCAL
PARAMETERS ('memory 20M')
;

-- now prepare for the merge. We are aiming to merge p2 and p3 
-- First we create a temporary table

DROP TABLE bike_items_temp;

CREATE TABLE bike_items_temp
( id      NUMBER,
  price   NUMBER,
  descrip VARCHAR2(40)
);

-- we're going to copy the data from the main table to temporary tables
-- for indexing "off line".  But we need to account for new rows added during that
-- indexing.  So we'll create a staging table and create triggers so that gets
-- populated with any inserts or updates in the meantime.
-- We need a sequence to ensure that multiple updates to the same row are reapplied
-- in the correct order
-- THIS SECTION CAN BE IGNORED if you're able to prevent changes to the base table
-- during this process.

DROP SEQUENCE bike_items_stage_sequence;

CREATE SEQUENCE bike_items_stage_sequence;

DROP TABLE bike_items_stage;

CREATE TABLE bike_items_stage
( id               NUMBER,
  price            NUMBER,
  descrip          VARCHAR2(40),
  update_number    NUMBER,
  insert_or_update VARCHAR2(1)
);

CREATE OR REPLACE TRIGGER bike_items_insert_monitor
  AFTER INSERT ON bike_items
  FOR EACH ROW
BEGIN
  IF :new.price BETWEEN 10 AND 100 THEN
    INSERT INTO bike_items_stage VALUES ( :new.id, :new.price, :new.descrip, null, 'I' );
  END IF;
END;
/

CREATE OR REPLACE TRIGGER bike_items_update_monitor
  AFTER UPDATE ON bike_items
  FOR EACH ROW
BEGIN
  IF :new.price BETWEEN 10 AND 100 THEN
    INSERT INTO bike_items_stage VALUES ( :new.id, :new.price, :new.descrip, bike_items_stage_sequence.NEXTVAL, 'U' );
  END IF;
END;
/

-- copy the rows from the partition to be split into the temporary table
-- must ensure that the restriction here match the boundaries for the partitions we will be merging

INSERT INTO bike_items_temp
  SELECT * FROM bike_items WHERE price >= 10 AND price < 100;

-- and create an indexes on the temp table
-- remember the original table and index is fully usable at this time

CREATE INDEX bike_items_temp_idx ON bike_items_temp (descrip)
INDEXTYPE IS ctxsys.context
PARAMETERS ('memory 20M')
;

--- Meanwhile some changes have occurred in the base table
--  these changes will check that our change monitoring is working properly

INSERT INTO bike_items VALUES (13, 45, 'wheel rim');

UPDATE bike_items SET price = 98 WHERE id = 3;
UPDATE bike_items SET descrip = 'wheel, front, super quality' WHERE id = 3;

-- merge the partition, do not update the index
-- for a short time our index is unusable - best if we can take the application down here

ALTER TABLE bike_items 
  MERGE PARTITIONS p1, p2, p3 
  INTO PARTITION p2and3;

-- the index on partition p2 is currently marked as unusable
-- the following query *** will FAIL ***
---                    -----------------

SELECT price, descrip FROM bike_items
WHERE CONTAINS( descrip, 'wheel' ) > 0;

-- now do the exchange partition to replace the data and the unusable indexes
-- "without validation" avoids it having to check that the partition keys are correct

ALTER TABLE bike_items
  EXCHANGE PARTITION p2and3 WITH TABLE bike_items_temp
  INCLUDING INDEXES
  WITHOUT VALIDATION;

-- now the index is usable again and the following query will work

SELECT price, descrip FROM bike_items
WHERE CONTAINS( descrip, 'wheel' ) > 0;

-- apply any inserts and updates from the staging table

-- first inserts

INSERT INTO bike_items 
  SELECT id, price, descrip FROM bike_items_stage
    WHERE  insert_or_update = 'I';

-- then updates. We need to make sure these happen in the same order
-- as originally, hence the cursor

BEGIN
  FOR c IN (
    SELECT id, price, descrip FROM bike_items_stage
      WHERE  insert_or_update = 'U'
      ORDER BY update_number ) LOOP
    UPDATE bike_items SET price = c.price, descrip = c.descrip
    WHERE id = c.id;
 END LOOP;
END;
/

-- delete the triggers

DROP TRIGGER bike_items_insert_monitor;
DROP TRIGGER bike_items_update_monitor

-- and sync the new merged partition of the index

EXECUTE ctx_ddl.sync_index( idx_name => 'bike_items_idx', part_name => 'p2and3' )

-- and run the query again, looking for the updated row

SELECT price, descrip FROM bike_items
WHERE CONTAINS( descrip, 'wheel AND super' ) > 0;

-- clean up temp and staging tables (commented out here for cleaner re-runs)

-- DROP TABLE bike_items_temp;
-- DROP TABLE bike_items_stage;
