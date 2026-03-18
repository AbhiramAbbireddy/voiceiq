alter table recordings
    add column if not exists local_path varchar(512);

alter table recordings
    add column if not exists original_file_name varchar(255);

alter table recordings
    add column if not exists file_size_bytes bigint;
