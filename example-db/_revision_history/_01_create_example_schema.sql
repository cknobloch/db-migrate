-- Create new schema
create schema example;
-- Always create meta table w/ the schema it's tracking
create table  example._revision_history like _revision_history;
