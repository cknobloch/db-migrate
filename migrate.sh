#!/bin/bash

#
# Ex. usage: cd <schema_path> && ./migrate.sh mysql -h127.0.0.1 -P3307 -uclover -pclover
#
# Notes:
# * Filename can only contain word characters (no spaces)
# * Directory name must match schema name exactly
# * DB_CLIENT calls to get history, then run migration/update-history, aren't atomic
#
# TODO:
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