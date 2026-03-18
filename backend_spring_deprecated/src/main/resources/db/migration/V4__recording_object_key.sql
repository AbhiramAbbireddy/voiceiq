alter table recordings
    add column if not exists object_key varchar(512);
