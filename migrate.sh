#!/bin/bash

#
# Ex. usage: cd <schema_path> && ./migrate.sh mysql -h127.0.0.1 -P3307 -uclover -pclover
#
# This single "nameless" script is a super simple system for managing database migrations.
# Basically, it reads a directory of sql files and runs any of them that haven't already run!
# It tracks what files have run in a table in the target database/schema, similar to other tools.
# Since the logic is so minimal, it's easy to port this script under any language/platform,
# such as an ETL job.
#
# Getting started
# 1. Put `migrate.sh` on your PATH or wherever you want to use it
# 1. Copy an example directory
# 1. Rename directories to match your database and schema
# 1. Add schema directories (by copy+paste from example)
# 1. Add revisions (copy+paste most recent under that schema)
#
# Hard conventions of the system
# * All revisions for a schema should be kept under a single directory
# * Filename identifies the revision (hopefully it also describes what it does, in a few words)
# * Revisions are run in lexicographical order
# * Filename should lead with an incrementing identifier.
#   It doesn't matter exactly what it is as long as it's sequential (per the previous bullet),
#   but incrementing digits like "00" -> "01" work well.
# * There is no concept of downgrading only upgrading!
#   If you have a risky migration and really want to prepare a downgrade ahead of time,
#   do so in a code branch with a tentative ID.
#   Or feel free to include downgrade steps using one of the conventions:
#   * as a comment in the revision,
#   * in another directory,
#   * using a filename that doesn't get picked up by the pattern matching (ex. "_00_init.sql.revert" for "_00_init.sql")
#
# Implementation conventions
# * Filename can only contain word characters (no spaces)
# * Directory name must match schema name exactly
# * DB_CLIENT calls to get history, then run migration/update-history, aren't atomic
#
# Implementation TO DOs
# * Use of env vars (esp. for arguments) seems hacky, but I'm no bash expert
#

set -e

SCHEMA_DIR="$( pwd )"
SCHEMA="$(basename -- "$SCHEMA_DIR" )"

TARGET_REVISION=$1

DEFAULT_REVISION_PATTERN=*.sql
DEFAULT_REVISION_ID_REGEX='_([0-9]+)'
REVISION_PATTERN=${REVISION_PATTERN:-$DEFAULT_REVISION_PATTERN}
REVISION_ID_REGEX=${REVISION_ID_REGEX:-$DEFAULT_REVISION_ID_REGEX}
DB_CLIENT="${@:2}"
DB_CLIENT_SCHEMA_ARG_NAME="-D"
DB_CLIENT_SELECT_ARGS="--skip-column-names"
DB_CLIENT_INSERT_ARGS=""

# Find all revisions that exist
ls -1 -- $REVISION_PATTERN | sort > .all_revisions

# Sanity check migrations for bad or duplicate IDs
head=""
error_count=0
for revision_name in $( cat .all_revisions ); do
    if [[ $revision_name =~ $REVISION_ID_REGEX ]]; then
        rev="${BASH_REMATCH[1]}"
    else
        echo "Invalid revision $revision_name"
        error_count=$error_count+1
        continue
    fi

    if [[ ! "$rev" > "$head" ]]; then
        echo "Conflicting revisions $revision_name / $head_name"
        error_count=$error_count+1
        continue
    fi

    head_name=$revision_name
    head=$rev
done

if [[ $error_count > 0 ]]; then
    exit 1
fi

# Find target revisions only
if [ -z "$TARGET_REVISION" ]; then
    cp .all_revisions .target_revisions
else
    echo "" > .target_revisions
    for revision_name in $( cat .all_revisions ); do
        if [[ "$revision_name" > "$TARGET_REVISION" ]]; then
            break
        fi
        echo "$revision_name" >> .target_revisions
    done
fi

# Find set of revisions that've been migrated
echo "select revision from _revision_history" \
    | $DB_CLIENT $DB_CLIENT_SELECT_ARGS $DB_CLIENT_SCHEMA_ARG_NAME $SCHEMA \
    | sort > .revision_history

# Check for migrations that've somehow gone missing
if [[ $( comm -13 .target_revisions .revision_history ) ]]; then
    echo "Revision(s) found in history doesn't exist"
    exit 1
fi

# Find last revision to use as fail-safe, _just in case_ list comparison goes awry
last_revision="$( tail -n1 .revision_history )"

# Find revisions that have not been migrated and run them!
for revision_name in $( comm -3 .target_revisions .revision_history ); do
    if [[ ! "$revision_name" > "$last_revision" ]]; then
        echo "Revision $revision_name precedes current revision $last_revision"
        exit 1
    fi

    echo "Running revision $revision_name"

    echo "insert into _revision_history ( revision ) values ( '$revision_name' );" \
        | cat $revision_name - \
        | $DB_CLIENT $DB_CLIENT_INSERT_ARGS $DB_CLIENT_SCHEMA_ARG_NAME $SCHEMA
done

# Remove working files after successful run only
rm .all_revisions .target_revisions .revision_history