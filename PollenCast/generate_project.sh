#!/bin/bash
# Generate Xcode project for PollenCast
# This script creates an Xcode project using xcodegen if available,
# otherwise provides instructions for manual setup.

echo "=== PollenCast Project Setup ==="
echo ""

# Check for xcodegen
if command -v xcodegen &> /dev/null; then
    echo "Found xcodegen. Generating project..."
    cd "$(dirname "$0")"
    xcodegen generate
    echo "Project generated successfully!"
    echo "Open PollenCast.xcodeproj in Xcode."
else
    echo "xcodegen not found."
    echo ""
    echo "Option 1: Install xcodegen and run this script again"
    echo "  brew install xcodegen"
    echo "  ./generate_project.sh"
    echo ""
    echo "Option 2: Create project manually in Xcode"
    echo "  1. Open Xcode -> File -> New -> Project"
    echo "  2. Choose 'App' template (SwiftUI, Swift)"
    echo "  3. Name it 'PollenCast'"
    echo "  4. Save to this directory"
    echo "  5. Remove the auto-generated files"
    echo "  6. Add all files from PollenCast/ folder to the project"
    echo "  7. Add WeatherKit capability in Signing & Capabilities"
    echo "  8. Set Info.plist to PollenCast/Info.plist"
    echo "  9. Add Debug.xcconfig and Release.xcconfig in project settings"
    echo ""
    echo "Option 3: Use the provided project.yml with xcodegen"
fi
