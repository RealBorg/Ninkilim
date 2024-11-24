CREATE TABLE sources (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL
);
CREATE TABLE postings (
    id BIGINT PRIMARY KEY,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    text TEXT NOT NULL,
    lang CHAR(3) NOT NULL DEFAULT '',
    parent BIGINT,
    source INTEGER REFERENCES sources(id) NOT NULL
);
CREATE TABLE medias (
    id SERIAL PRIMARY KEY,
    posting BIGINT REFERENCES postings(id) NOT NULL,
    filename TEXT NOT NULL,
    type VARCHAR(20) NOT NULL
);
CREATE INDEX idx_postings_date ON postings(date);
CREATE INDEX idx_postings_parent ON postings(parent);
CREATE INDEX idx_medias_posting ON medias(posting);
