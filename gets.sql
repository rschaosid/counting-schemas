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
