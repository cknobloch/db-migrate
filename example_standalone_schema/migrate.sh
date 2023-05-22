#!/bin/bash

set -e

# This is a customizable migration script. Change it however you want.

MIGRATE_SCRIPT=../migrate.sh # this should be on PATH in real world
TARGET_REVISION="" # no specific revision / allow the way to head

# Optionally override env vars here
# REVISION_PATTERN=*.sql
# REVISION_ID_REGEX='_([0-9]+)'
# DB_CLIENT="$@"
# DB_CLIENT_SCHEMA_ARG_NAME="-D"
# DB_CLIENT_SELECT_ARGS="--skip-column-names"
# DB_CLIENT_INSERT_ARGS=""

mysql $@ -e "create schema if not exists example_standalone_schema"

$MIGRATE_SCRIPT "$TARGET_REVISION" mysql $@