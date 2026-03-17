#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
APP_NAME="Browsey"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
BUNDLE_ID="com.robinson.browsey"

echo "Building ${APP_NAME}.app ..."

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Compile AppleScript into .app bundle
osacompile -o "${APP_BUNDLE}" "${SCRIPT_DIR}/browsey.applescript"

# Patch Info.plist to register as a browser (handle http/https URLs)
PLIST="${APP_BUNDLE}/Contents/Info.plist"

# Set bundle identifier
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${PLIST}" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string ${BUNDLE_ID}" "${PLIST}"

# Set bundle name
/usr/libexec/PlistBuddy -c "Set :CFBundleName ${APP_NAME}" "${PLIST}" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleName string ${APP_NAME}" "${PLIST}"

# Add URL scheme handler for http and https
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'Web URL'" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Viewer" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string https" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string http" "${PLIST}"

# Add document types for HTML content
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes array" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0 dict" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string 'HTML document'" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string public.html" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:1 string public.xhtml" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:2 string public.url" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSHandlerRank string Alternate" "${PLIST}"

# Use Chrome's icon
cp /Applications/Google\ Chrome.app/Contents/Resources/app.icns "${APP_BUNDLE}/Contents/Resources/applet.icns"

echo "Built ${APP_BUNDLE}"
echo "Info.plist patched with URL scheme handlers."
