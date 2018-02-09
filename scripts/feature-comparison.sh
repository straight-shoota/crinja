#! /usr/bin/env bash

diff -B <( ./scripts/jinja/default_lib.py ) <( crystal ./src/cli.cr -- --library-defaults --only-names )
