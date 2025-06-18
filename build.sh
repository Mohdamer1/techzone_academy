#!/bin/bash

# Exit on error
set -e

echo "=== Starting Flutter web build ==="
echo "Current directory: $(pwd)"
echo "Contents of current directory:"
ls -la

# Check if Flutter is already available
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found, installing..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$(pwd)/flutter/bin"
    echo "Flutter installed at: $(which flutter)"
else
    echo "Flutter found at: $(which flutter)"
fi

# Flutter doctor to check setup
echo "=== Running Flutter doctor ==="
flutter doctor

# Clean previous builds
echo "=== Cleaning previous builds ==="
flutter clean

# Install dependencies
echo "=== Installing dependencies ==="
flutter pub get

# Build web release
echo "=== Building web release ==="
flutter build web --release --web-renderer canvaskit

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo "ERROR: build/web directory not found!"
    exit 1
fi

# Create dist directory and copy build output
echo "=== Copying build output to dist ==="
mkdir -p dist
cp -r build/web/* dist/

echo "=== Build completed successfully! ==="
echo "Contents of dist directory:"
ls -la dist/ 