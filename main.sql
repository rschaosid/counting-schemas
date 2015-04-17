/*
Copyright 2015 Anders Cornell.

This file is part of counting-schemas.

counting-schemas is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

counting-schemas is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with counting-schemas.  If not, see <http://www.gnu.org/licenses/>.
*/

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

CREATE TABLE threads (
  thread_id    smallserial  PRIMARY KEY,
  shortname    text         CHECK (is_valid_shortname(shortname)),
  name         text,
  description  text,
  creator      text         CHECK (is_valid_username(creator)),
  created      timestamp
);

-- indexes for `threads`
CREATE UNIQUE INDEX ON threads (shortname);

-- permissions for `threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON threads TO counting_write;
GRANT USAGE ON threads_thread_id_seq TO counting_write;
GRANT SELECT ON threads TO counting_read;

--
-- Thread labels
--

CREATE TABLE thread_labels (
  thread_id smallserial NOT NULL references threads (thread_id),
  label text NOT NULL
);

-- indexes for `thread_labels`
CREATE UNIQUE INDEX ON thread_labels (thread_id, label);

-- permissions for `thread_labels`
GRANT SELECT, INSERT, UPDATE, DELETE ON thread_labels TO counting_write;
GRANT SELECT ON thread_labels TO counting_read;

--
-- liveupdate threads
--

CREATE TABLE liveupdate_threads (
  id         smallint  PRIMARY KEY,
  thread_id  smallint  REFERENCES threads (thread_id),
  flake      text      UNIQUE NOT NULL
);

-- permissions for `liveupdate_threads`
GRANT SELECT, INSERT, UPDATE, DELETE ON liveupdate_threads TO counting_write;
GRANT SELECT ON liveupdate_threads TO counting_read;

--
-- Comments
--

CREATE TABLE comments (
--id                 bigint     NOT NULL
--parent_id          bigint
--link_id            integer    NOT NULL
--
--created            timestamp  NOT NULL
--author             text       CHECK (is_valid_username(author))
--body               text

  -- (columns ordered for performance)
  id                 bigint     NOT NULL,
  parent_id          bigint,
  created            timestamp  NOT NULL,
  link_id            integer    NOT NULL,
  author             text       CHECK (is_valid_username(author)),
  body               text
);

-- indexes for `comments`
CREATE UNIQUE INDEX ON comments (id);

-- permissions for `comments`
GRANT SELECT, INSERT, UPDATE, DELETE ON comments TO counting_write;
GRANT SELECT ON comments TO counting_read;

--
-- Updates
--

CREATE TABLE updates (
--liveupdate_thread_id  smallint   NOT NULL REFERENCES liveupdate_threads (id)
--rank                  integer    NOT NULL
--id                    uuid       NOT NULL
--
--created               timestamp  NOT NULL
--author                text       NOT NULL CHECK (is_valid_username(author))
--body                  text       NOT NULL
--
--stricken              boolean    NOT NULL

  -- (columns ordered for performance)
  id                    uuid       NOT NULL,
  rank                  integer    NOT NULL,
  liveupdate_thread_id  smallint   NOT NULL REFERENCES liveupdate_threads (id),
  stricken              boolean    NOT NULL,
  created               timestamp  NOT NULL,
  author                text       NOT NULL CHECK (is_valid_username(author)),
  body                  text       NOT NULL
);

-- indexes for `updates`
CREATE UNIQUE INDEX ON updates (id);
CREATE UNIQUE INDEX ON updates (liveupdate_thread_id, rank);

-- permissions for `updates`
GRANT SELECT, INSERT, UPDATE, DELETE ON updates TO counting_write;
GRANT SELECT ON updates TO counting_read;

--
-- Counts
--

CREATE TABLE counts (
--comment_id               bigint     REFERENCES comments (id),
--update_id                uuid       REFERENCES updates (id),

--thread_id                smallint   NOT NULL REFERENCES threads (thread_id),
--value                    integer    NOT NULL,

--created                  timestamp,
--author                   text       CHECK (is_valid_username(author)),

  -- (columns ordered for performance)
  update_id                uuid       REFERENCES updates (id),
  comment_id               bigint     REFERENCES comments (id),
  created                  timestamp,
  value                    integer    NOT NULL,
  thread_id                smallint   NOT NULL REFERENCES threads (thread_id),
  author                   text       CHECK (is_valid_username(author)),
  count_text               text,

  -- row does not have both comment_id and update_id set
  CHECK (comment_id IS NULL OR update_id IS NULL)
);

-- indexes for `counts`
CREATE UNIQUE INDEX ON counts (thread_id, value);
CREATE INDEX ON counts (author);
CREATE INDEX ON counts (created);

-- permissions for `counts`
GRANT SELECT, INSERT, UPDATE, DELETE ON counts TO counting_write;
GRANT SELECT ON counts TO counting_read;
