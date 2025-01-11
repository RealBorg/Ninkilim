CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    email TEXT NOT NULL,
    username TEXT NOT NULL,
    displayname TEXT NOT NULL,
    bio TEXT NOT NULL DEFAULT '',
    website TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '',
    source TEXT NOT NULL DEFAULT ''
);
CREATE TABLE postings (
    id BIGINT PRIMARY KEY,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    text TEXT NOT NULL,
    lang CHAR(3) NOT NULL DEFAULT '',
    parent BIGINT,
    author BIGINT REFERENCES users(id) NOT NULL
);
CREATE TABLE medias (
    posting BIGINT REFERENCES postings(id) NOT NULL,
    filename TEXT PRIMARY KEY,
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
CREATE TABLE peers (
    url TEXT PRIMARY KEY,
    owner BIGINT REFERENCES users(id),
    last_id BIGINT
);
CREATE INDEX idx_postings_date ON postings(date);
CREATE INDEX idx_postings_parent ON postings(parent);
CREATE INDEX idx_medias_posting ON medias(posting);
