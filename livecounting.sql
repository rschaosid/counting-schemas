CREATE TABLE threads (
  id SMALLSERIAL PRIMARY KEY,
  reddit_id text NOT NULL,
  category text,
  name text,
  creator text,
  scheme_name text,
  scheme_module text
);

-- permissions for `threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON threads TO livecounting_write;
GRANT SELECT ON threads TO livecounting_read;

CREATE TABLE valid_comments (
  thread       smallint  NOT NULL REFERENCES threads (id),
  serial       integer   NOT NULL,
  name         text      UNIQUE NOT NULL,
  permalink    text,
  author       text      NOT NULL CHECK(author ~ E'^\\w{3,20}$'),
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
GRANT SELECT, INSERT, UPDATE, DELETE ON valid_comments TO livecounting_write;
GRANT SELECT ON valid_comments TO livecounting_read;

-- selects a valid comment for each (thread, value) combination (there is almost always only one)
CREATE VIEW count_comments AS SELECT DISTINCT ON (thread, value) *
FROM valid_comments ORDER BY thread, value, stricken ASC, serial ASC;

-- permissions for `count_comments`
GRANT SELECT ON count_comments TO livecounting_read;

--
-- these should be moved to app logic at some point
--

CREATE VIEW nonsequential_comments AS SELECT * FROM (SELECT
  serial,
  name,
  author,
  created_utc,
  body,
  value,
  value = 1 + lag(value) OVER serial_window AS sequential,
  lag(value) OVER serial_window AS previous_value
FROM count_comments WINDOW serial_window AS (ORDER BY serial ASC)) AS t0 WHERE NOT sequential ORDER BY value;
GRANT SELECT ON nonsequential_comments TO livecounting_read;

CREATE VIEW contributors AS SELECT DISTINCT author, COUNT(*) AS contribution_count
FROM count_comments GROUP BY author;
GRANT SELECT ON contributors TO livecounting_read;
