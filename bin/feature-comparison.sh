#! /usr/bin/env bash

diff -B <( ./bin/jinja/default_lib.py ) <( crystal ./src/cli.cr -- --library-defaults=only-names )
