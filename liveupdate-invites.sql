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
-- liveupdate thread invitations
--

CREATE TABLE liveupdate_thread_invitations (
  thread_id             smallint   NOT NULL REFERENCES threads (thread_id),
  liveupdate_thread_id  smallint   NOT NULL REFERENCES liveupdate_threads (id),
  username              text       NOT NULL CHECK(is_valid_username(username)),
  submitted             timestamp  DEFAULT CURRENT_TIMESTAMP
);

-- indexes for `liveupdate_thread_invitations`
CREATE INDEX ON liveupdate_thread_invitations (thread_id, username);

-- permissions for `liveupdate_thread_invitations`
GRANT SELECT, INSERT, UPDATE, DELETE ON liveupdate_thread_invitations TO counting_write;
GRANT SELECT ON liveupdate_thread_invitations TO counting_read;
