#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
APP_NAME="Browsey"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
INSTALL_DIR="${HOME}/Applications"

if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "Error: ${APP_BUNDLE} not found. Run ./build.sh first."
    exit 1
fi

# Ensure ~/Applications exists
mkdir -p "${INSTALL_DIR}"

# Remove previous install
rm -rf "${INSTALL_DIR}/${APP_NAME}.app"

# Copy to ~/Applications
cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/${APP_NAME}.app"
echo "Installed to ${INSTALL_DIR}/${APP_NAME}.app"

# Force Launch Services to re-register the app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${INSTALL_DIR}/${APP_NAME}.app"
echo "Registered with Launch Services."

# Touch to invalidate caches
touch "${INSTALL_DIR}/${APP_NAME}.app"

echo ""
echo "Done! Now go to:"
echo "  System Settings > Desktop & Dock > Default web browser"
echo "  and select '${APP_NAME}'"
