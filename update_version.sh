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

# Replace the flutter.js and main.dart.js references with versioned ones
sed -i "s|flutter.js|flutter.js?v=$timestamp|g" web/index.html
sed -i "s|main.dart.js|main.dart.js?v=$timestamp|g" web/index.html

# Update the serviceWorkerVersion
sed -i "s|const serviceWorkerVersion = null;|const serviceWorkerVersion = '$timestamp';|" web/index.html

# Remove the backup file
rm web/index.html.bak

echo "Version number updated successfully"