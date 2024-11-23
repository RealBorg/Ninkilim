CREATE TABLE sources (
    id SERIAL PRIMARY KEY,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    uri TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL
);
CREATE TABLE postings (
    id BIGINT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    full_text TEXT NOT NULL,
    lang CHAR(3) NOT NULL DEFAULT '',
    reposted BOOLEAN NOT NULL DEFAULT FALSE,
    in_reply_to BIGINT,
    highlight BOOLEAN NOT NULL DEFAULT FALSE,
    source INTEGER REFERENCES sources(id) NOT NULL
);
CREATE TABLE media (
    id SERIAL PRIMARY KEY,
    posting_id BIGINT REFERENCES postings(id) NOT NULL,
    filename TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL
);
CREATE INDEX idx_posting_created_at ON postings(created_at);
CREATE INDEX idx_posting_in_reply_to ON postings(in_reply_to);
CREATE INDEX idx_media_posting_id ON media(posting_id);
