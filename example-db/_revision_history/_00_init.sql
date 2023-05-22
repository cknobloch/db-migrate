create table _revision_history (
    revision varchar(255) not null,
    -- run_timestamp datetime DEFAULT CURRENT_TIMESTAMP,
    primary key (revision)
);