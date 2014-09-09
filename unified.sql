CREATE TYPE thread_type AS ENUM('live', 'dead');
CREATE SEQUENCE threads_id_seq;
CREATE TABLE threads (
  type thread_type NOT NULL,
  id smallint PRIMARY KEY DEFAULT nextval(threads_id_seq),
  reddit_id text NOT NULL,
  category text,
  name text,
  creator text,
  scheme_name text,
  scheme_module text
);
ALTER SEQUENCE threads_id_seq OWNED BY threads.id;

-- permissions for `threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON threads TO counting_write;
GRANT USAGE ON threads_id_seq TO counting_write;
GRANT SELECT ON threads TO counting_read;

CREATE TABLE valid_comments (
  thread       smallint  NOT NULL REFERENCES threads (id),
  serial       integer   NOT NULL,
  name         text      UNIQUE NOT NULL,
  author       text,
  created_utc  integer   NOT NULL,
  body         text      NOT NULL,
  stricken     boolean   NOT NULL,
  value        bigint    NOT NULL,
  PRIMARY KEY (thread, serial)
);

-- I am not good at indexes but this should do okay
CREATE INDEX ON valid_comments (thread, value, stricken, serial);
CREATE INDEX ON valid_comments (serial);
CREATE INDEX ON valid_comments (name);
CREATE INDEX ON valid_comments (author);
CREATE INDEX ON valid_comments (created_utc);

-- permissions for `valid_comments`
GRANT SELECT, INSERT, UPDATE, DELETE ON valid_comments TO counting_write;
GRANT SELECT ON valid_comments TO counting_read;

-- selects a valid comment for each (thread, value) combination (there is almost always only one)
CREATE VIEW count_comments AS SELECT DISTINCT ON (thread, value) *
FROM valid_comments ORDER BY thread, value, stricken ASC, serial ASC;

-- permissions for `count_comments`
GRANT SELECT ON count_comments TO counting_read;

CREATE TABLE invitations (
  thread smallint NOT NULL REFERENCES threads (id),
  username text NOT NULL CHECK(username ~ E'^\\w{3,20}$'),
  submitted timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (thread, username)
);

-- permissions for `invitations`
GRANT SELECT, INSERT, UPDATE, DELETE ON invitations TO counting_write;
GRANT SELECT ON invitations TO counting_read;
