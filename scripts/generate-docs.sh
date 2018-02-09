GENERATED_DOCS_DIR="./docs"

echo -e "Building docs into ${GENERATED_DOCS_DIR}"
echo -e "Clearing ${GENERATED_DOCS_DIR} directory"
rm -rf "${GENERATED_DOCS_DIR}"

echo -e "Running `crystal docs`..."
crystal doc

echo -e "Copying README.md and TEMPLATE_SYNTAX.md"
# "{{" and "{%"" need to be escaped, otherise Jekyll might interpret the expressions (on Github Pages)
sed 's/{{/&#123;&#123;/g; s/{%/&#123;%/g' README.md > "${GENERATED_DOCS_DIR}/README.md"
sed 's/{{/&#123;&#123;/g; s/{%/&#123;%/g' TEMPLATE_SYNTAX.md > "${GENERATED_DOCS_DIR}/TEMPLATE_SYNTAX.md"
