#!/bin/bash
# This is for website deployment

# Get the current timestamp
timestamp=$(date +%s)

# Check if the web/index.html file exists
if [ ! -f "web/index.html" ]; then
  echo "web/index.html not found. Exiting."
  exit 1
fi

echo "Updating version number for $(basename $(pwd))"

# Make a backup of the original index.html file
cp web/index.html web/index.html.bak

# Replace the main.dart.js reference with the new version number
sed -i "s/main\.dart\.js?v=[0-9]*/main.dart.js?v=$timestamp/" web/index.html

# Remove the backup file
rm web/index.html.bak

echo "Version number updated successfully"