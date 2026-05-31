#!/bin/bash
# Payload Manager - Versioned Build Script

# 1. Extract version from include/pldmgr.h
VERSION=$(grep '#define MENU_VERSION' include/pldmgr.h | awk '{print $3}' | tr -d '"' | tr -d '\r')

if [ -z "$VERSION" ]; then
    echo "Error: Could not find MENU_VERSION in include/pldmgr.h"
    exit 1
fi

OUTPUT_ELF="pldmgr_v${VERSION}.elf"
OUTPUT_BUNDLE="pldmgr_elfldr_v${VERSION}.elf"
IMAGE_NAME="ps5-payload-sdk-pldmgr"

echo "--- Building Payload Manager v$VERSION ---"

# 2. Build React Frontend (on Host)
echo "[1/4] Building React Frontend..."
make frontend-build > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "      !!! Frontend build FAILED!"
    exit 1
fi
echo "      Frontend build successful."

# 2b. Build/verify the docker image
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "      Docker image $IMAGE_NAME not found. Building... (this may take a few minutes)"
    docker build -t $IMAGE_NAME -f Dockerfile.sdk .
    if [ $? -ne 0 ]; then
        echo "      !!! Docker image build FAILED!"
        exit 1
    fi
    echo "      Docker image built successfully."
fi

# 3. Build native ELF via Docker
echo "[2/4] Building native ELF via Docker..."
docker run --rm -v "$(pwd)":/src -w /src $IMAGE_NAME make clean all > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "      !!! ELF build FAILED!"
    exit 1
fi
echo "      ELF build successful."

# 4. Build bundled ELF via Docker
echo "[3/4] Building bundled ELF via Docker..."
docker run --rm -v "$(pwd)":/src -w /src $IMAGE_NAME make bundle > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "      !!! Bundled ELF build FAILED!"
    exit 1
fi
echo "      Bundled ELF build successful."


# 5. Rename output
if [ -f "pldmgr.elf" ]; then
    mv pldmgr.elf "$OUTPUT_ELF"
    echo "[4/4] Created versioned binary: $OUTPUT_ELF"
else
    echo "      !!! pldmgr.elf not found after build!"
    exit 1
fi

if [ -f "pldmgr_elfldr.elf" ]; then
    mv pldmgr_elfldr.elf "$OUTPUT_BUNDLE"
    echo "[4/4] Created versioned bundled binary: $OUTPUT_BUNDLE"
else
    echo "      !!! pldmgr_elfldr.elf not found after build!"
    exit 1
fi

echo "--- Build Complete! ---"
