create table if not exists users (
    id uuid primary key,
    full_name varchar(120) not null,
    email varchar(180) not null unique,
    password_hash varchar(255) not null,
    target_role varchar(80) not null,
    plan varchar(40) not null,
    created_at timestamp not null,
    updated_at timestamp not null
);

create table if not exists sessions (
    id uuid primary key,
    user_id uuid not null references users(id),
    type varchar(40) not null,
    status varchar(40) not null,
    prompt_text text not null,
    created_at timestamp not null,
    updated_at timestamp not null
);

create table if not exists recordings (
    id uuid primary key,
    session_id uuid not null references sessions(id),
    storage_url varchar(512),
    duration_seconds integer not null,
    mime_type varchar(80) not null,
    created_at timestamp not null
);

create table if not exists transcripts (
    id uuid primary key,
    session_id uuid not null references sessions(id),
    transcript_text text not null,
    filler_count integer not null,
    words_per_minute integer not null,
    created_at timestamp not null
);

create table if not exists feedback_reports (
    id uuid primary key,
    session_id uuid not null unique references sessions(id),
    overall_score integer not null,
    pace_score integer not null,
    clarity_score integer not null,
    confidence_score integer not null,
    filler_score integer not null,
    summary text not null,
    suggestions text not null,
    created_at timestamp not null
);

create table if not exists progress_scores (
    id uuid primary key,
    user_id uuid not null references users(id),
    session_id uuid not null unique references sessions(id),
    overall_score integer not null,
    improvement_delta integer not null,
    created_at timestamp not null
);
