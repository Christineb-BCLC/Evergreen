BEGIN;

ALTER TABLE config.record_attr_definition
    ADD COLUMN vocabulary TEXT;

ALTER TABLE config.coded_value_map
    ADD COLUMN concept_uri TEXT;

COMMIT;
