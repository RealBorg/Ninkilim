CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    email TEXT NOT NULL,
    username TEXT NOT NULL,
    displayname TEXT NOT NULL,
    bio TEXT NOT NULL,
    website TEXT NOT NULL,
    location TEXT NOT NULL
);
CREATE TABLE postings (
    id BIGINT PRIMARY KEY,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    text TEXT NOT NULL,
    lang CHAR(3) NOT NULL DEFAULT '',
    parent BIGINT,
    author BIGINT REFERENCES users(id) NOT NULL
);
CREATE TABLE medias (
    id SERIAL PRIMARY KEY,
    posting BIGINT REFERENCES postings(id) NOT NULL,
    filename TEXT NOT NULL,
    type VARCHAR(20) NOT NULL
);
CREATE TABLE login_tokens (
    user_id BIGINT REFERENCES users(id),
    token TEXT NOT NULL PRIMARY KEY,
    created TIMESTAMP NOT NULL
);
CREATE TABLE sessions (
    id CHAR(72) PRIMARY KEY,
    session_data TEXT,
    expires INTEGER
);
CREATE INDEX idx_postings_date ON postings(date);
CREATE INDEX idx_postings_parent ON postings(parent);
CREATE INDEX idx_medias_posting ON medias(posting);
