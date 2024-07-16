#!/bin/bash

# Navigate to the build directory
cd build/web

# Generate a version hash based on the current timestamp
VERSION=$(date +%s | md5sum | cut -d' ' -f1)

# Update flutter.js reference in index.html
sed -i.bak "s/flutter\.js/flutter.js?v=$VERSION/" index.html

# Update manifest.json reference
sed -i.bak "s/manifest\.json/manifest.json?v=$VERSION/" index.html

# Update favicon reference
sed -i.bak "s/favicon\.png/favicon.png?v=$VERSION/" index.html

# Update Icon-192.png reference
sed -i.bak "s/Icon-192\.png/Icon-192.png?v=$VERSION/" index.html

# Optionally, update other asset references
# sed -i.bak "s/assets\/fonts/assets\/fonts?v=$VERSION/g" index.html
# sed -i.bak "s/assets\/images/assets\/images?v=$VERSION/g" index.html

# Remove the backup file created by sed
rm index.html.bak

echo "Asset versioning completed. Version: $VERSION"

# Optionally, update the serviceWorkerVersion in index.html
# This ensures that the service worker is updated with each deployment
sed -i.bak "s/const serviceWorkerVersion = null;/const serviceWorkerVersion = '$VERSION';/" index.html
rm index.html.bak

echo "Service worker version updated to: $VERSION"