echo -e "Clearing ./doc directory"
rm -rf ./doc

echo -e "Running crystal doc..."
crystal doc

echo -e "Copying README.md and ROADMAP.md"
# "{{" and "{%"" need to be escaped, otherise Jekyll might interpret the expressions (on Github Pages)
sed 's/{{/&#123;&#123;/g; s/{%/&#123;%/g' README.md > "doc/README.md"
sed 's/{{/&#123;&#123;/g; s/{%/&#123;%/g' ROADMAP.md > "doc/ROADMAP.md"
