# DB Migrate

This is a dumb solution for managing database migrations. It is equal parts _script_ and a set of file organization conventions.

# Overview

There is a single script `migrate.sh` reads a directory of sql files and runs any of them that haven't already run. It tracks what files have run in a meta table in the target database/schema, similar to other tools. Since the logic in the script is so minimal, it's easy to port to other languages/platforms,
such as an ETL job.

# Usage
1. Put `migrate.sh` on your PATH or wherever you want to use it
1. Copy an example directory
1. Rename directories to match your database and schema
1. Add schema directories (by copy+paste from example)
1. Add revisions (copy+paste most recent under that schema)

# Hard Conventions (you must follow these!)
* All revisions for a schema should be kept under a single directory
* Filename identifies the revision (hopefully it also describes what it does, in a few words)
* Revisions are run in lexicographical order
* Filename should lead with an incrementing identifier.
  It doesn't matter exactly what it is as long as it's sequential (per the previous bullet),
  but incrementing digits like "00" -> "01" work well (this is a requirement of safeguards)
* There is no concept of downgrading only upgrading!
  If you have a risky migration and really want to prepare a downgrade ahead of time,
  do so in a code branch with a tentative ID.
  Or feel free to include downgrade steps using one of the conventions:
  * as a comment in the revision,
  * in another directory,
  * using a filename that doesn't get picked up by the pattern matching (ex. `_00_init.sql.revert` for `_00_init.sql`)

# Bash script `migrate.sh`

## Notes
* Filename can only contain word characters (no spaces)
* Directory name must match schema name exactly
* DB_CLIENT calls to get history, then run migration/update-history, aren't atomic

## To dos
* Add support for .sh files along with .sql files, to allow more flexibility in migrations (like hooking data migrations, etc.)
