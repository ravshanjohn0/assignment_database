=============================================================
ENUM TYPES
=============================================================

CREATE TYPE type_time_unit AS ENUM (
    'seconds',
    'minutes',
    'hours',
    'days'
);

CREATE TYPE type_user_active_status AS ENUM (
    'pending',
    'active',
    'suspended',
    'banned',
    'deleted',
    'inactive'
);

CREATE TYPE type_employee_role AS ENUM (
    'instructor',
    'tester'
);

CREATE TYPE type_token_type AS ENUM (
    'verify_account_email',
    'update_account_password',
    'cookie_token_login'
);

CREATE TYPE type_email_usage_case AS ENUM (
    'reset_password_account_email',
    'update_password_account_email',
    'verify_account_email',
    'welcome_user_email'
);

CREATE TYPE type_exercise_difficulty AS ENUM (
    'beginner',
    'intermediate',
    'advanced'
);

CREATE TYPE type_exercise_status AS ENUM (
    'pending',
    'available',
    'deleted'
);

CREATE TYPE type_exercise_access_level AS ENUM (
    'public',
    'private'
);

CREATE TYPE type_user_exercise_status_exercise AS ENUM (
    'not_started',
    'in_progress',
    'stopped',
    'completed'
);

CREATE TYPE type_user_exercise_event_reason AS ENUM (
    'restart',
    'completed'
);

CREATE TYPE type_user_games_attempts_status AS ENUM (
    'in_progress',
    'finished',
    'abandoned'
);

CREATE TYPE type_games_difficulty AS ENUM (
    'easy',
    'medium',
    'hard',
    'human'
);

=============================================================
TABLES
=============================================================

CREATE TABLE users (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL CHECK (length(btrim(first_name)) > 0),
    last_name   VARCHAR(100) DEFAULT NULL CHECK (last_name IS NULL OR length(btrim(last_name)) > 0),
    email       TEXT NOT NULL UNIQUE,
    password    TEXT NOT NULL,
    avatar      TEXT DEFAULT NULL,
    balance     INT NOT NULL DEFAULT 0,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    active_status type_user_active_status NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ DEFAULT NULL,
    reason      TEXT DEFAULT NULL
);

CREATE TABLE students (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE instructors (
    users_id BIGINT PRIMARY KEY REFERENCES users(id)
    -- Note: use a function/trigger before inserting into this table
);

CREATE TABLE employee (
    id          BIGINT NOT NULL REFERENCES users(id),
    birth_date  DATE NOT NULL,
    role        type_employee_role NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ DEFAULT NULL,
    reason      TEXT DEFAULT NULL,
    PRIMARY KEY (id, role)
);


=============================================================
TOKENS
=============================================================

CREATE TABLE tokens (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token      TEXT NOT NULL,
    token_type type_token_type NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked    BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


=============================================================
EMAIL RULES & LOGS
=============================================================

CREATE TABLE email_rules (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email_usage_case  type_email_usage_case NOT NULL,
    max_per_day       INT NOT NULL DEFAULT 3,
    cooldown_duration INT NOT NULL DEFAULT 1,
    cooldown_unit     type_time_unit NOT NULL DEFAULT 'minutes',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE email_usage (
    user_id          BIGINT NOT NULL REFERENCES users(id),
    email_usage_case BIGINT NOT NULL REFERENCES email_rules(id),
    last_sent        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, email_usage_case)
);

CREATE TABLE email_logs (
    user_id          BIGINT NOT NULL REFERENCES users(id),
    email_usage_case BIGINT NOT NULL REFERENCES email_rules(id),
    sent_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

=============================================================
EXERCISE MODULE
=============================================================

CREATE TABLE topic (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    slug       VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE languages (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    slug       VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE technology (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    slug       VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


=============================================================
EXERCISE MODULE
=============================================================

CREATE TABLE exercise (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    position            INT NOT NULL UNIQUE,
    title               VARCHAR(100) NOT NULL UNIQUE,
    slug                VARCHAR(100) NOT NULL UNIQUE,
    description         TEXT NOT NULL,
    instructions        TEXT NOT NULL,
    icon                TEXT NOT NULL,
    difficulty          type_exercise_difficulty NOT NULL,
    estimated_time      INT NOT NULL,
    estimated_time_unit type_time_unit NOT NULL,
    status              type_exercise_status,
    access_level        type_exercise_access_level NOT NULL,
    instructor_id       BIGINT NOT NULL REFERENCES instructors(users_id),
    published_at        TIMESTAMPTZ DEFAULT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at          TIMESTAMPTZ NULL,
    reason              TEXT DEFAULT NULL
);


=============================================================
EXERCISE MODULE RELATIONSHIPS
=============================================================

CREATE TABLE exercise_topic (
    exercise_id BIGINT NOT NULL REFERENCES exercise(id),
    topic_id    BIGINT NOT NULL REFERENCES topic(id),
    PRIMARY KEY (exercise_id, topic_id)
);

CREATE TABLE exercise_language (
    exercise_id BIGINT NOT NULL REFERENCES exercise(id),
    language_id BIGINT NOT NULL REFERENCES languages(id),
    PRIMARY KEY (exercise_id, language_id)
);

CREATE TABLE exercise_technology (
    exercise_id   BIGINT NOT NULL REFERENCES exercise(id),
    technology_id BIGINT NOT NULL REFERENCES technology(id),
    PRIMARY KEY (exercise_id, technology_id)
);


=============================================================
VIDEOS
=============================================================

CREATE TABLE video (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    url         TEXT NOT NULL,
    position    INT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ DEFAULT NULL,
    reason      TEXT DEFAULT NULL
);

CREATE TABLE exercise_video (
    exercise_id BIGINT NOT NULL REFERENCES exercise(id),
    video_id    BIGINT NOT NULL REFERENCES video(id),
    PRIMARY KEY (exercise_id, video_id)
);


=============================================================
CODE SNIPPETS
=============================================================

CREATE TABLE solution_code (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT NOT NULL,
    position      INT NOT NULL UNIQUE,
    solution_code TEXT NOT NULL,
    explanation   TEXT NOT NULL,
    language_id   BIGINT NOT NULL REFERENCES languages(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ DEFAULT NULL,
    reason        TEXT DEFAULT NULL
);

CREATE TABLE exercise_solution_code (
    solution_code_id BIGINT NOT NULL REFERENCES solution_code(id),
    exercise_id      BIGINT NOT NULL REFERENCES exercise(id),
    PRIMARY KEY (solution_code_id, exercise_id)
);

CREATE TABLE initial_code (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    initial_code TEXT NOT NULL,
    language_id  BIGINT NOT NULL REFERENCES languages(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ DEFAULT NULL,
    reason       TEXT DEFAULT NULL
);

CREATE TABLE exercise_initial_code (
    initial_code_id BIGINT NOT NULL REFERENCES initial_code(id),
    exercise_id     BIGINT NOT NULL REFERENCES exercise(id),
    PRIMARY KEY (initial_code_id, exercise_id)
);


=============================================================
TEST CASES
=============================================================

CREATE TABLE exercise_test_case (
    id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    language_id          BIGINT NOT NULL REFERENCES languages(id),
    input_display        TEXT NOT NULL,
    scenario             TEXT NOT NULL,
    expected_output_json JSONB NOT NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at           TIMESTAMPTZ DEFAULT NULL,
    reason               TEXT DEFAULT NULL
);

CREATE TABLE exercise_exercise_test_case (
    exercise_id          BIGINT NOT NULL REFERENCES exercise(id),
    exercise_test_case_id BIGINT NOT NULL REFERENCES exercise_test_case(id),
    PRIMARY KEY (exercise_id, exercise_test_case_id)
);

CREATE TABLE signature_exercise (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    language_id   BIGINT NOT NULL REFERENCES languages(id),
    function_name TEXT NOT NULL,
    params_json   JSONB NOT NULL,
    return_type   JSONB NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ DEFAULT NULL,
    reason        TEXT DEFAULT NULL
);

CREATE TABLE exercise_signature_exercise (
    exercise_id          BIGINT NOT NULL REFERENCES exercise(id),
    signature_exercise_id BIGINT NOT NULL REFERENCES signature_exercise(id),
    PRIMARY KEY (exercise_id, signature_exercise_id)
);


=============================================================
USER EXERCISE PROGRESS
=============================================================

CREATE TABLE user_exercise (
    id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id              BIGINT NOT NULL REFERENCES users(id),
    exercise_id          BIGINT NOT NULL REFERENCES exercise(id),
    status_exercise      type_user_exercise_status_exercise NOT NULL DEFAULT 'not_started',
    started_at           TIMESTAMPTZ DEFAULT NULL,
    last_started_at      TIMESTAMPTZ DEFAULT NULL,
    time_spent_in_seconds INT NOT NULL DEFAULT 0,
    completed_at         TIMESTAMPTZ DEFAULT NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, exercise_id)
);

CREATE TABLE user_code (
    user_exercise_id BIGINT NOT NULL REFERENCES user_exercise(id),
    language_id      BIGINT NOT NULL REFERENCES languages(id),
    code             TEXT NOT NULL DEFAULT '',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_exercise_id, language_id)
);

CREATE TABLE user_exercise_event (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_exercise_id BIGINT NOT NULL REFERENCES user_exercise(id),
    reason           type_user_exercise_event_reason NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_exercise_event_code (
    user_exercise_event_id BIGINT NOT NULL REFERENCES user_exercise_event(id),
    language_id            BIGINT NOT NULL REFERENCES languages(id),
    code                   TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (user_exercise_event_id, language_id)
);

CREATE TABLE user_exercise_viewed (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    exercise_id BIGINT NOT NULL REFERENCES exercise(id),
    viewed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, exercise_id)
);


=============================================================
 GAMES MODULE
=============================================================

CREATE TABLE games (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR(100) NOT NULL UNIQUE,
    slug             VARCHAR(100) NOT NULL UNIQUE,
    description      TEXT NOT NULL,
    media_url        TEXT NOT NULL,
    challenge_levels INT NOT NULL DEFAULT 3,
    is_active        BOOLEAN NOT NULL DEFAULT false,
    deleted_at       TIMESTAMPTZ DEFAULT NULL,
    reason           TEXT DEFAULT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_games_attempts (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    game_id     BIGINT NOT NULL REFERENCES games(id),
    score       INT NOT NULL DEFAULT 0 CHECK (score >= 0),
    difficulty  type_games_difficulty NOT NULL DEFAULT 'easy',
    status      type_user_games_attempts_status NOT NULL DEFAULT 'in_progress',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id, game_id, difficulty)
);

CREATE TABLE user_games_score (
    user_id       BIGINT NOT NULL REFERENCES users(id),
    game_id       BIGINT NOT NULL REFERENCES games(id),
    difficulty    type_games_difficulty NOT NULL DEFAULT 'easy',
    score         INT NOT NULL DEFAULT 0 CHECK (score >= 0),
    last_score_id BIGINT NOT NULL REFERENCES user_games_attempts(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, game_id, difficulty)
);


============================================================
-- SECTION 3: INDEXES
============================================================

-- Partial unique index: only active (non-deleted) users must have unique email
-- This allows a deleted user's email to be reused by a new account
CREATE UNIQUE INDEX users_email_unique_active
    ON users (email)
    WHERE deleted_at IS NULL;

-- Speed up lookups by user status (e.g. filter active users)
CREATE INDEX idx_users_active_status
    ON users (active_status);

-- Speed up exercise lookups by status and access level
CREATE INDEX idx_exercise_status
    ON exercise (status);

CREATE INDEX idx_exercise_access_level
    ON exercise (access_level);

-- Speed up finding exercises by instructor
CREATE INDEX idx_exercise_instructor
    ON exercise (instructor_id);

-- Speed up user exercise progress lookups
CREATE INDEX idx_user_exercise_user_id
    ON user_exercise (user_id);

CREATE INDEX idx_user_exercise_status
    ON user_exercise (status_exercise);

-- Speed up game score lookups per user
CREATE INDEX idx_user_games_score_user_id
    ON user_games_score (user_id);

-- Speed up game attempt lookups
CREATE INDEX idx_user_games_attempts_user_id
    ON user_games_attempts (user_id);

-- Speed up email log lookups per user
CREATE INDEX idx_email_logs_user_id
    ON email_logs (user_id);

-- Speed up token lookups (e.g. finding valid tokens)
CREATE INDEX idx_tokens_token_type
    ON tokens (token_type);

CREATE INDEX idx_tokens_revoked
    ON tokens (revoked);