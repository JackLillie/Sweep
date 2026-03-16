#!/bin/bash
# Bundle Mole into the app's Resources directory.
# Called as an Xcode build phase script.

set -euo pipefail

MOLE_SRC="${SRCROOT}/mole"
BUNDLE_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/mole"

echo "Bundling Mole from ${MOLE_SRC}..."

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"
mkdir -p "${BUNDLE_DIR}/bin"
mkdir -p "${BUNDLE_DIR}/lib"

# Build Go binaries
echo "Building Go binaries..."
cd "${MOLE_SRC}"
export PATH="/usr/local/go/bin:/opt/homebrew/bin:$PATH"

if command -v go &> /dev/null; then
    go build -ldflags="-s -w" -o "${BUNDLE_DIR}/bin/status-go" ./cmd/status
    go build -ldflags="-s -w" -o "${BUNDLE_DIR}/bin/analyze-go" ./cmd/analyze
    echo "Go binaries built successfully"
else
    echo "warning: Go not found, skipping Go binary build. Install Go to bundle mole."
    echo "warning: The app will fall back to system-installed mole."
fi

cd "${SRCROOT}"

# Copy main scripts
cp "${MOLE_SRC}/mole" "${BUNDLE_DIR}/mole"
chmod +x "${BUNDLE_DIR}/mole"

# Copy bin scripts
for script in "${MOLE_SRC}/bin/"*.sh; do
    cp "$script" "${BUNDLE_DIR}/bin/"
    chmod +x "${BUNDLE_DIR}/bin/$(basename "$script")"
done

# Copy lib directory
cp -R "${MOLE_SRC}/lib" "${BUNDLE_DIR}/lib"

# Make all scripts executable
find "${BUNDLE_DIR}" -name "*.sh" -exec chmod +x {} \;
chmod +x "${BUNDLE_DIR}/mole"

echo "Mole bundled successfully at ${BUNDLE_DIR}"
