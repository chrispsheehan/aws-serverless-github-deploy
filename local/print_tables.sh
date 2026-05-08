#!/usr/bin/env sh
set -eu

psql -v ON_ERROR_STOP=1 -c '\dt'
