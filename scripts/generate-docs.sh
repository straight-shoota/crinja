GENERATED_DOCS_DIR="./doc"

echo -e "Building docs into ${GENERATED_DOCS_DIR}"
echo -e "Clearing ${GENERATED_DOCS_DIR} directory"
rm -rf "${GENERATED_DOCS_DIR}"

echo -e "Running crystal doc..."
crystal doc

echo -e "Copying README.md and ROADMAP.md"
# "{{" and "{%"" need to be escaped, otherise Jekyll might interpret the expressions (on Github Pages)
#cp README.md "${GENERATED_DOCS_DIR}/README.md"
#cp ROADMAP.md "${GENERATED_DOCS_DIR}/ROADMAP.md"
sed 's/{{/&#123;&#123;/g; s/{%/&#123;%/g' README.md > "${GENERATED_DOCS_DIR}/README.md"
sed 's/{{/&#123;&#123;/g; s/{%/&#123;%/g' ROADMAP.md > "${GENERATED_DOCS_DIR}/ROADMAP.md"
