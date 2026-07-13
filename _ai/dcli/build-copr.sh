#!/usr/bin/env bash
# build-copr.sh - Bump version, build SRPM, and submit to COPR
#
# Usage:
#   ./build-copr.sh                    # Bump patch, build & submit
#   ./build-copr.sh --bump minor       # Bump minor version
#   ./build-copr.sh --bump major       # Bump major version
#   ./build-copr.sh --version 1.5.0    # Set exact version
#   ./build-copr.sh --no-bump          # Don't bump (use current)
#   ./build-copr.sh --srpm-only        # Only build SRPM locally
#   ./build-copr.sh --submit           # Submit pre-built SRPM
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="dcli"
NAME="dcli"

SRPM_ONLY=false
SUBMIT_ONLY=false
NO_BUMP=false
BUMP_TYPE="patch"
EXPLICIT_VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --srpm-only) SRPM_ONLY=true; shift ;;
        --submit)    SUBMIT_ONLY=true; shift ;;
        --no-bump)   NO_BUMP=true; shift ;;
        --bump)
            BUMP_TYPE="$2"
            [[ "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]] || {
                echo "Error: --bump must be major, minor, or patch"; exit 1; }
            shift 2 ;;
        --bump=*)
            BUMP_TYPE="${1#*=}"
            [[ "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]] || {
                echo "Error: --bump must be major, minor, or patch"; exit 1; }
            shift ;;
        --version)
            EXPLICIT_VERSION="$2"
            [[ "$EXPLICIT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
                echo "Error: --version must be X.Y.Z format"; exit 1; }
            shift 2 ;;
        --version=*)
            EXPLICIT_VERSION="${1#*=}"
            [[ "$EXPLICIT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
                echo "Error: --version must be X.Y.Z format"; exit 1; }
            shift ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# --- Version bumping ---
cd "$SCRIPT_DIR"
CURRENT_VERSION=$(grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')

if $NO_BUMP; then
    NEW_VERSION="$CURRENT_VERSION"
    echo "==> Using current version: ${NEW_VERSION} (no bump)"
elif [ -n "$EXPLICIT_VERSION" ]; then
    NEW_VERSION="$EXPLICIT_VERSION"
    echo "==> Setting version: ${CURRENT_VERSION} -> ${NEW_VERSION}"
else
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    case "$BUMP_TYPE" in
        major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
        minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
        patch) PATCH=$((PATCH + 1)) ;;
    esac
    NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
    echo "==> Bumping ${BUMP_TYPE}: ${CURRENT_VERSION} -> ${NEW_VERSION}"
fi

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    # Update Cargo.toml
    sed -i "s/^version = \"${CURRENT_VERSION}\"/version = \"${NEW_VERSION}\"/" Cargo.toml

    # Update dcli.spec Version
    sed -i "s/^Version:.*/Version:        ${NEW_VERSION}/" dcli.spec

    # Add changelog entries after %changelog line
    DATE=$(date "+%a %b %d %Y")
    sed -i "/^%changelog/a - Update to ${NEW_VERSION}" dcli.spec
    sed -i "/^%changelog/a * ${DATE} Don <theblackdonatello@gmail.com> - ${NEW_VERSION}-1" dcli.spec

    echo "==> Updated Cargo.toml, dcli.spec, and changelog"
fi

# Ensure rpmbuild directories exist
mkdir -p "${HOME}/rpmbuild/"{SOURCES,SPECS,SRPMS,RPMS}

TARBALL="${NAME}-${NEW_VERSION}.tar.gz"
BUILD_DIR="/tmp/copr-build-${NAME}"

# --- Build SRPM ---
if ! $SUBMIT_ONLY; then
    echo "==> Preparing source tarball for ${NAME} v${NEW_VERSION}..."

    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}/${NAME}-${NEW_VERSION}"

    echo "==> Running cargo vendor to ensure dependencies are vendored..."
    # Clean and re-vendor to ensure vendor dir is complete and consistent
    rm -rf vendor
    cargo vendor --versioned-dirs 2>/dev/null || cargo vendor

    # Verify vendor directory was created and is non-empty
    if [ ! -d vendor ] || [ -z "$(ls -A vendor 2>/dev/null)" ]; then
        echo "Error: cargo vendor failed or produced an empty vendor directory"
        exit 1
    fi
    echo "==> Vendor directory populated successfully"

    echo "==> Copying source files..."
    rsync -a --exclude='.git' \
             --exclude='/target' \
             --exclude='*.rpm' \
             --exclude='*.tar.gz' \
             --exclude='dcli' \
             --exclude="${BUILD_DIR}" \
             ./ "${BUILD_DIR}/${NAME}-${NEW_VERSION}/"

    cd "${BUILD_DIR}"
    echo "==> Creating tarball..."
    tar czf "${HOME}/rpmbuild/SOURCES/${TARBALL}" "${NAME}-${NEW_VERSION}/"
    cp "${BUILD_DIR}/${NAME}-${NEW_VERSION}/${NAME}.spec" "${HOME}/rpmbuild/SPECS/"
    echo "==> Tarball created: ${HOME}/rpmbuild/SOURCES/${TARBALL}"
    cd "$SCRIPT_DIR"
    rm -rf "${BUILD_DIR}"
fi

# Build SRPM
echo "==> Building SRPM..."
rpmbuild -bs "${HOME}/rpmbuild/SPECS/${NAME}.spec" \
    --define "_sourcedir ${HOME}/rpmbuild/SOURCES" \
    --define "_srcrpmdir ${HOME}/rpmbuild/SRPMS"

SRPM_PATH=$(ls -t "${HOME}/rpmbuild/SRPMS/${NAME}-${NEW_VERSION}"*.src.rpm 2>/dev/null | head -1)

if [ -z "${SRPM_PATH}" ]; then
    echo "Error: SRPM not found!"
    exit 1
fi

echo "==> SRPM built: ${SRPM_PATH}"

if $SRPM_ONLY; then
    echo "==> Done (SRPM only). Submit with: copr-cli build dcli ${SRPM_PATH}"
    exit 0
fi

# --- Submit to COPR ---
echo "==> Submitting to COPR..."
copr-cli build "${PROJECT}" "${SRPM_PATH}"

echo "==> Done! Check build status at:"
echo "    https://copr.fedorainfracloud.org/coprs/theblackdon/${PROJECT}/"
