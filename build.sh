#!/bin/bash

# Exit on error
set -e

echo "Starting Flutter web build..."

# Check if Flutter is already available
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found, installing..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$(pwd)/flutter/bin"
fi

# Flutter doctor to check setup
flutter doctor

# Clean previous builds
flutter clean

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Build web release
echo "Building web release..."
flutter build web --release --web-renderer canvaskit

# Create dist directory and copy build output
echo "Copying build output..."
mkdir -p dist
cp -r build/web/* dist/

echo "Build completed successfully!" 