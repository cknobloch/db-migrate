-- Beware! This script gets called on every migration

-- Initialize the meta schema + table
create schema if not exists example_standalone_schema;
create table  if not exists example_standalone_schema._revision_history (
    revision varchar(255) not null,
    -- run_timestamp datetime DEFAULT CURRENT_TIMESTAMP,
    primary key (revision)
);