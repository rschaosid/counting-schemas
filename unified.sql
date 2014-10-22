--
-- Helper functions
--

CREATE FUNCTION is_valid_username(username text) RETURNS boolean AS $$
  SELECT (username ~ E'^\\w{3,20}$');
$$ LANGUAGE sql;

CREATE FUNCTION is_valid_shortname(shortname text) RETURNS boolean AS $$
  SELECT (shortname ~ E'^\\w+$');
$$ LANGUAGE sql;

CREATE FUNCTION is_valid_simpleflake(flake bytea) RETURNS boolean AS $$
  SELECT octet_length(flake) = 8;
$$ LANGUAGE sql;

--
-- Threads
--

CREATE TYPE thread_type AS ENUM('liveupdate', 'comment');

CREATE TABLE threads (
  type thread_type NOT NULL,
  thread_id smallserial PRIMARY KEY,
  category text,
  shortname text UNIQUE NOT NULL CHECK (is_valid_shortname(shortname)),
  name text,
  description text,
  creator text CHECK (is_valid_username(creator)),
  created timestamp,
  scheme_name text,
  scheme_module text
);

-- permissions for `threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON threads TO counting_write;
GRANT USAGE ON threads_thread_id_seq TO counting_write;
GRANT SELECT ON threads TO counting_read;

--
-- Live thread invitations
--

CREATE TABLE liveupdate_threads (
  thread_id smallint NOT NULL REFERENCES threads (thread_id),
  thread_flake bytea UNIQUE NOT NULL CHECK (is_valid_simpleflake(thread_flake))
);

-- permissions for `liveupdate_threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON liveupdate_threads TO counting_write;
GRANT SELECT ON liveupdate_threads TO counting_read;

CREATE TABLE liveupdate_thread_invitations (
  thread smallint NOT NULL REFERENCES threads (thread_id),
  username text NOT NULL CHECK(is_valid_username(username)),
  submitted timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (thread, username)
);

-- permissions for `invitations`
GRANT SELECT, INSERT, UPDATE, DELETE ON liveupdate_thread_invitations TO counting_write;
GRANT SELECT ON liveupdate_thread_invitations TO counting_read;

--
-- Updates and comments
--

CREATE TABLE valid_updates (
  thread_id     smallint   NOT NULL REFERENCES threads (thread_id),
  thread_flake  bytea      CHECK (is_valid_simpleflake(thread_flake)),
  serial        integer    NOT NULL,
  update_id     uuid,
  author        text       CHECK (is_valid_username(author)),
  created       timestamp,
  body          text,
  stricken      boolean,
  value         integer     NOT NULL
);

-- Index to make count_updates fast
CREATE INDEX ON valid_updates (thread_id, value, stricken, serial);

-- Other indexes
CREATE INDEX ON valid_updates (author);
CREATE INDEX ON valid_updates (created);

-- permissions for `valid_updates`
GRANT SELECT, INSERT, UPDATE, DELETE ON valid_updates TO counting_write;
GRANT SELECT ON valid_updates TO counting_read;

-- selects a valid update for each (thread, value) combination (there is almost always only one)
CREATE VIEW count_updates AS SELECT DISTINCT ON (thread_id, value) *
FROM valid_updates ORDER BY thread_id, value, stricken ASC, serial ASC;

-- permissions for `count_updates`
GRANT SELECT ON count_updates TO counting_read;

CREATE TABLE count_comments (
  thread_id   smallint   NOT NULL REFERENCES threads (thread_id),
  link_id     integer,
  comment_id  bigint,
  author      text       CHECK (is_valid_username(author)),
  created     timestamp,
  body        text,
  value       integer     NOT NULL,
  PRIMARY KEY (thread_id, value)
);

CREATE INDEX ON count_comments (author);
CREATE INDEX ON count_comments (created);
CREATE INDEX ON count_comments (value);

-- permissions for `count_comments`
GRANT SELECT, INSERT, UPDATE, DELETE ON count_comments TO counting_write;
GRANT SELECT ON count_comments TO counting_read;

CREATE VIEW count_things AS ((SELECT thread_id, author, created, body, value FROM count_updates)
                   UNION ALL (SELECT thread_id, author, created, body, value FROM count_comments));

GRANT SELECT ON count_things TO counting_read;

--
-- Gettables
--

CREATE TABLE periodic_gettables (
  thread_id  smallint NOT NULL REFERENCES threads (thread_id),
  phase      integer NOT NULL,
  period     integer NOT NULL,
  shortname  text CHECK (is_valid_shortname(shortname)),
  name       text,
  PRIMARY KEY (shortname),
  UNIQUE (thread_id, phase, period)
);

-- permissions for `periodic_gettables`
GRANT SELECT, INSERT, UPDATE, DELETE ON periodic_gettables TO counting_write;
GRANT SELECT ON periodic_gettables TO counting_read;

CREATE TABLE point_gettables (
  thread_id  smallint NOT NULL REFERENCES threads (thread_id),
  value      integer NOT NULL,
  class      text CHECK (is_valid_shortname(class)),
  shortname  text CHECK (is_valid_shortname(shortname)),
  name       text,
  PRIMARY KEY (shortname),
  UNIQUE (thread_id, value)
);

-- permissions for `point_gettables`
GRANT SELECT, INSERT, UPDATE, DELETE ON point_gettables TO counting_write;
GRANT SELECT ON point_gettables TO counting_read;
