alter table feedback_reports
    add column if not exists strengths text;

alter table feedback_reports
    add column if not exists weaknesses text;

alter table feedback_reports
    add column if not exists better_answer text;

alter table feedback_reports
    add column if not exists filler_breakdown text;

alter table feedback_reports
    add column if not exists hesitation_phrases text;
