#! /usr/bin/env bash

set -e

GENERATED_DOCS_DIR="./docs"

echo -e "Building docs into ${GENERATED_DOCS_DIR}"
echo -e "Clearing ${GENERATED_DOCS_DIR} directory"
rm -rf "${GENERATED_DOCS_DIR}"

echo -e "Running \`make docs\`..."
make docs

echo -e "Copying README.md and TEMPLATE_SYNTAX.md"

# "{{" and "{%"" need to be escaped, otherise Jekyll might interpret the expressions (on Github Pages)
ESCAPE_TEMPLATE='s/{{/{{"{{"}}/g; s/{\%/{{"{%"}}/g;'
sed "${ESCAPE_TEMPLATE}" README.md > "${GENERATED_DOCS_DIR}/README.md"
sed "${ESCAPE_TEMPLATE}" TEMPLATE_SYNTAX.md > "${GENERATED_DOCS_DIR}/TEMPLATE_SYNTAX.md"

echo -e "Copying playground files"
mkdir -p "${GENERATED_DOCS_DIR}/playground"
for file in playground/*.md; do
  sed "s/\`\`\`playground/\`\`\`crystal/g; ${ESCAPE_TEMPLATE}" "${file}" | cat <(echo -e "---\n---\n") - > "${GENERATED_DOCS_DIR}/${file}"
done
