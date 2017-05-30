#! /usr/bin/env bash
# This script builds the latest documentation and copies it into a doc directory.
DOC_ROOT=${1:-"_doc"}

if [ ! -d ${DOC_ROOT} ]; then
  echo "${DOC_ROOT} does not exist"
  exit 1
fi

echo "Building docs with \`crystal doc\`."
rm -r doc/*
crystal doc
echo "Done."
echo "Moving generated docs to ${DOC_ROOT}/doc/latest"

if [ -d ${DOC_ROOT}/doc/latest/ ]; then
  rm -r ${DOC_ROOT}/doc/latest/
fi
cp -r doc/ ${DOC_ROOT}/doc/latest

echo "Moving README files to doc root."
# escape jinja2 delimiters, so Jekyll does not interpret them
sed 's/{{/{{ "{{" }}/g; s/{%/{{ "{%" }}/g' README.md > "${DOC_ROOT}/README.md"
sed 's/{{/{{ "{{" }}/g; s/{%/{{ "{%" }}/g' ROADMAP.md > "${DOC_ROOT}/ROADMAP.md.md"
