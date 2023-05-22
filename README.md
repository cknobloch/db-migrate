# DB Migrate

This is a dumb solution for managing database migrations. It is equal parts _script_ and a set of file-organizing conventions.

# Overview

There is a single script `migrate.sh` that lists all revision files for a schema (ex. `ls *.sql`), and runs any of them that haven't already been run (through the database command-line client, ex. `mysql` for MySQL). It tracks what files have run in a meta table in the target database/schema, similar to other migration tools. Since the logic in the script is so minimal, it's easy to port to other languages/platforms, such as an ETL job.

# Conventions (you must follow these!)
* All revisions for a schema should be kept under a single directory
* Filename identifies the revision (hopefully it also describes what it does, in a few words)
* Revisions are run in lexicographical order
* Filename should lead with an incrementing identifier.
  It doesn't matter exactly what it is as long as it's sequential (per the previous bullet),
  but incrementing digits like "00" -> "01" work well
* There is no concept of downgrading only upgrading!
  If you have a risky migration and really want to prepare a downgrade ahead of time,
  do so in a code branch with a tentative ID.
  Or feel free to include downgrade steps using one of the conventions:
  * as a comment in the revision,
  * in another directory,
  * using a filename that doesn't get picked up by the pattern matching (ex. `_00_init.sql.revert` for `_00_init.sql`)
* In target database
  * database-level migrations are handled through a meta schema `_revision_history` (as it is the schema tracking revisions to the db)
  * schema-level migrations are tracked through a `_revision_history` table that at least has to include the revision filename, but can optionally include more

# Getting Started

To start a new database or standalone-schema migration, no tools are needed.

1. Copy one of the top-level example directories
1. Replace directories to match your database and schema (keeping the db meta one `_revision_history`)
1. Update the local migration script to reflect your environment

# Add a New Revision

This could easily be put in to a script but why bother.

1. Copy the last revision under the target schema
1. Increment the identifier part of the filename, and replace the remainder of it with a short description of the change (don't worry if you make a mistake, `migrate.sh` takes notice!)
1. Replace the contents of the file with your database code

# Bash script `migrate.sh`

To use `migrate.sh`, download it then put it on your PATH or wherever you want to use it, duh.

## Notes
* Filename can only contain word characters (no spaces)
* Directory name must match schema name exactly
* DB_CLIENT calls to get history, then run migration/update-history, aren't atomic

## To dos
* Add support for .sh files along with .sql files, to allow more flexibility in migrations (like hooking data migrations, etc.)
