#!/bin/bash

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Install dependencies
flutter pub get

# Build web
flutter build web --release

# Create a _redirects file for SPA routing
echo "/* /index.html 200" > build/web/_redirects 