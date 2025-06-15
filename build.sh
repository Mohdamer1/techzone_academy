#!/bin/bash

# Exit on error
set -e

# Install Flutter (if not already cached)
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"
flutter doctor

# Install dependencies
flutter pub get

# Build web release
flutter build web --release 