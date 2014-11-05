--
-- Helper functions
--

CREATE FUNCTION is_valid_username(username text) RETURNS boolean AS $$
  SELECT (username ~ E'^\\w{3,20}$');
$$ LANGUAGE sql;

CREATE FUNCTION is_valid_shortname(shortname text) RETURNS boolean AS $$
  SELECT (shortname ~ E'^[\\w\\-]+$');
$$ LANGUAGE sql;

--
-- Threads
--

CREATE TYPE thread_type AS ENUM('liveupdate', 'comment');

CREATE TABLE threads (
  type thread_type NOT NULL,
  thread_id smallserial PRIMARY KEY,
  category text,
  shortname text NOT NULL CHECK (is_valid_shortname(shortname)),
  name text,
  description text,
  creator text CHECK (is_valid_username(creator)),
  created timestamp
);

CREATE UNIQUE INDEX ON threads (shortname);

-- permissions for `threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON threads TO counting_write;
GRANT USAGE ON threads_thread_id_seq TO counting_write;
GRANT SELECT ON threads TO counting_read;

--
-- liveupdate threads and liveupdate thread invitations
--

CREATE TABLE liveupdate_threads (
  thread_id smallint NOT NULL REFERENCES threads (thread_id),
  liveupdate_thread_flake text UNIQUE NOT NULL,
  PRIMARY KEY (thread_id, thread_flake)
);

-- permissions for `liveupdate_threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON liveupdate_threads TO counting_write;
GRANT SELECT ON liveupdate_threads TO counting_read;

CREATE TABLE liveupdate_thread_invitations (
  thread_id smallint NOT NULL REFERENCES threads (thread_id),
  username text NOT NULL CHECK(is_valid_username(username)),
  submitted timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON liveupdate_thread_invitations (thread_id, username);

-- permissions for `invitations`
GRANT SELECT, INSERT, UPDATE, DELETE ON liveupdate_thread_invitations TO counting_write;
GRANT SELECT ON liveupdate_thread_invitations TO counting_read;

--
-- Counts
--

CREATE TABLE things (
  -- comments
  comment_id               bigint,
  comment_link_id          integer,
  
  -- liveupdate updates
  liveupdate_position      integer,
  liveupdate_update_id     uuid,
  liveupdate_thread_flake  text,
  
  -- common
  created                  timestamp,
  created_high             timestamp,
  thread_id                smallint   NOT NULL,
  author                   text       CHECK (is_valid_username(author)),
  original_author          text       CHECK (is_valid_username(true_author))
  body                     text,
  
  FOREIGN KEY (thread_id) REFERENCES threads (thread_id),
  
  -- row does not have both comment_id and liveupdate_update_id set
  CHECK (comment_id IS NULL OR liveupdate_update_id IS NULL),
  
  -- if comment_id or liveupdate_update_id is set, created is also set
  CHECK (created IS NOT NULL OR (comment_id IS NULL AND liveupdate_update_id IS NULL)),
  
  -- comment_id and comment_link_id are both set or both null
  CHECK (comment_id IS NULL = comment_link_id IS NULL),
  
  -- liveupdate_update_id, liveupdate_thread_flake, and liveupdate_position are all set or all null
  CHECK (liveupdate_update_id IS NULL = liveupdate_thread_flake IS NULL
     AND liveupdate_update_id IS NULL = liveupdate_position IS NULL),
  
  -- for updates, author and body are set
  CHECK ((author IS NOT NULL AND body IS NOT NULL) OR liveupdate_update_id IS NULL)
);

CREATE TABLE queue_things (
  FOREIGN KEY (thread_id) REFERENCES threads (thread_id),
  
  --comments
  parent_id  bigint,
  
  --liveupdate updates
  stricken   boolean,
  
  -- for updates, stricken is set
  CHECK (stricken IS NOT NULL OR liveupdate_update_id IS NULL)
) INHERITS (things);

-- permissions for `queue_things`
GRANT SELECT, INSERT, UPDATE, DELETE ON queue_things TO counting_write;
GRANT SELECT ON queue_things TO counting_read;

CREATE TABLE non_count_things (
  FOREIGN KEY (thread_id) REFERENCES threads (thread_id),
  
  raw_value  integer
) INHERITS (things);

-- permissions for `non_count_things`
GRANT SELECT, INSERT, UPDATE, DELETE ON non_count_things TO counting_write;
GRANT SELECT ON non_count_things TO counting_read;

CREATE TABLE count_things (
  FOREIGN KEY (thread_id) REFERENCES threads (thread_id),
  
  count_text               text,
  value                    integer    NOT NULL,
  
  PRIMARY KEY (thread_id, value)
) INHERITS (things);

CREATE UNIQUE INDEX ON count_things (thread_id, value);
CREATE UNIQUE INDEX ON count_things (thread_id, liveupdate_position)
  WHERE (liveupdate_position IS NOT NULL);

CREATE INDEX ON count_things (author);
CREATE INDEX ON count_things (created);

-- permissions for `count_things`
GRANT SELECT, INSERT, UPDATE, DELETE ON count_things TO counting_write;
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
