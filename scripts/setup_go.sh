#!/bin/bash

# Go version to install
GO_VERSION="1.23.4"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Convert architecture name if needed
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH="arm64"
fi

# Download URL
DOWNLOAD_URL="https://go.dev/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
DOWNLOAD_FILE="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"

echo "Setting up Go ${GO_VERSION} for ${OS}-${ARCH}"
echo "Download URL: ${DOWNLOAD_URL}"

# Create backend directory if it doesn't exist
mkdir -p backend

# Download Go
echo "Downloading Go..."
curl -L -o "backend/${DOWNLOAD_FILE}" "${DOWNLOAD_URL}"

# Extract Go (remove old installation if exists)
echo "Extracting Go..."
rm -rf backend/go
tar -C backend -xzf "backend/${DOWNLOAD_FILE}"

# Clean up downloaded archive
rm "backend/${DOWNLOAD_FILE}"

# Print success message and version
echo "Go ${GO_VERSION} has been installed successfully!"
backend/go/bin/go version 