#! /bin/sh
# This script builds the latest documentation and copies it into a doc directory.
DOC_ROOT=${1:-"_doc"}

echo "Building docs: `crystal doc`"
crystal doc
echo "Done."

[ -d ${DOC_ROOT}/doc/latest/ ] && rm -r ${DOC_ROOT}/doc/latest/
cp -r doc/ ${DOC_ROOT}/doc/latest

# escape jinja2 delimiters, so Jekyll does not interpret them
sed 's/{{/{{ "{{" }}/g; s/{%/{{ "{%" }}/g' README.md > "${DOC_ROOT}/README.md"
