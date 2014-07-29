CREATE TABLE comments (
  serial integer UNIQUE,
  name text UNIQUE NOT NULL,
  author text NOT NULL CHECK(author ~ E'^\\w{3,20}$'),
  created_utc integer NOT NULL,
  body text NOT NULL,
  stricken boolean NOT NULL
);

CREATE VIEW valid_comments AS SELECT * FROM (SELECT
  serial,
  name,
  author,
  created_utc,
  body,
  CAST(translate(substring(body FROM E'^[~#*`_\\s\\[]*([1-9]\\d{0,2}(?:,\\d{3})*|[1-9]\\d{3}),?(?:[^\\d,].*)?$'), ',', '') AS integer) AS value,
  stricken
FROM comments) AS t0
WHERE value IS NOT NULL;

CREATE VIEW count_comments AS SELECT * FROM valid_comments
WHERE serial = (SELECT min(serial) FROM valid_comments AS t2 WHERE value=valid_comments.value);

CREATE VIEW contributors AS SELECT author, (SELECT COUNT(*)
FROM count_comments AS t3 WHERE author = count_comments.author) AS contribution_count FROM count_comments;
