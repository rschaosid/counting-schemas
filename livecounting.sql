CREATE TABLE comments (
  serial integer UNIQUE,
  name text UNIQUE NOT NULL,
  author text NOT NULL CHECK(author ~ E'^\\w{3,20}$'),
  created_utc integer NOT NULL,
  body text NOT NULL,
  stricken boolean NOT NULL
);

CREATE FUNCTION get_value(body text) RETURNS integer AS $$
  SELECT CAST(translate(translate(substring(body FROM E'^[~#*`_\\s\\[]*([1-9]\\d{0,2}(?:,? ?\\d{3})*),?(?:[^\\d,].*)?$'), ',', ''), ' ', '') AS integer)
$$ LANGUAGE SQL;

CREATE INDEX ON comments (serial);
CREATE INDEX ON comments (get_value(body));
GRANT SELECT, INSERT, UPDATE, DELETE ON comments TO livecounting_write;
GRANT SELECT ON comments TO livecounting_read;

CREATE VIEW valid_comments AS SELECT * FROM (SELECT
  serial,
  name,
  author,
  created_utc,
  body,
  get_value(body) AS value,
  stricken
FROM comments) AS t0
WHERE value IS NOT NULL;
GRANT SELECT ON valid_comments TO livecounting_read;

CREATE VIEW count_comments AS SELECT DISTINCT ON (value) *
FROM valid_comments ORDER BY value, stricken ASC, serial ASC;
GRANT SELECT ON count_comments TO livecounting_read;

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
