#!/usr/bin/env bash
set -e

if [[ "$1" = "ghost" ]]; then
  exec gosu node "$@"
fi

exec "$@"
