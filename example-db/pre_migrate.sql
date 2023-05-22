-- Beware! This script gets called on every migration

-- Initialize the meta schema, for managing the database itself
create schema if not exists _revision_history;

-- Always create meta table w/ the schema it's tracking
-- Note, all other revision history tables will be create "like" this one
create table  if not exists _revision_history._revision_history (
    revision varchar(255) not null,
    -- run_timestamp datetime DEFAULT CURRENT_TIMESTAMP,
    primary key (revision)
);