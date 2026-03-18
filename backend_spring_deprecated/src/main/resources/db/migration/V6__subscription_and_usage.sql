create table if not exists subscriptions (
    id uuid primary key,
    user_id uuid not null unique references users(id),
    plan varchar(40) not null,
    status varchar(40) not null,
    provider varchar(40) not null,
    external_subscription_id varchar(120),
    current_period_start timestamp not null,
    current_period_end timestamp not null,
    created_at timestamp not null,
    updated_at timestamp not null
);

create table if not exists usage_counters (
    id uuid primary key,
    user_id uuid not null references users(id),
    period_start timestamp not null,
    period_end timestamp not null,
    sessions_used integer not null,
    processed_seconds integer not null,
    created_at timestamp not null,
    updated_at timestamp not null,
    constraint uq_usage_counters_user_period unique (user_id, period_start, period_end)
);
