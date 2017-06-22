echo -e "Clearing ./doc directory"
rm -rf ./doc

echo -e "Running crystal doc..."
crystal doc

echo -e "Copying README.md and ROADMAP.md"
sed 's/{{/{{ "{{" }}/g; s/{%/{{ "{%" }}/g' README.md > "doc/README.md"
sed 's/{{/{{ "{{" }}/g; s/{%/{{ "{%" }}/g' ROADMAP.md > "doc/ROADMAP.md.md"
