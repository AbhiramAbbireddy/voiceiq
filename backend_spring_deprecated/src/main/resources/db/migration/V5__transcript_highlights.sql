alter table transcripts
    add column if not exists highlights_json text;
