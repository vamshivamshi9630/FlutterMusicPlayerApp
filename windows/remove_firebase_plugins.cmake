# This script comments out Firebase plugins from generated_plugins.cmake
# Executed BEFORE generated_plugins.cmake is included to prevent Firebase compilation on Windows
# Firebase is disabled for Windows (guest-only mode), but packages remain in pubspec.yaml for Android/iOS

set(PLUGINS_FILE "${CMAKE_CURRENT_SOURCE_DIR}/flutter/generated_plugins.cmake")

# Read the generated_plugins.cmake file
if(EXISTS ${PLUGINS_FILE})
  file(READ ${PLUGINS_FILE} PLUGINS_CONTENT)
  
  # Comment out Firebase plugin entries
  string(REGEX REPLACE "^([[:space:]]*)cloud_firestore$" "\\1#cloud_firestore" PLUGINS_CONTENT "${PLUGINS_CONTENT}")
  string(REGEX REPLACE "^([[:space:]]*)firebase_auth$" "\\1#firebase_auth" PLUGINS_CONTENT "${PLUGINS_CONTENT}")
  string(REGEX REPLACE "^([[:space:]]*)firebase_core$" "\\1#firebase_core" PLUGINS_CONTENT "${PLUGINS_CONTENT}")
  string(REGEX REPLACE "^([[:space:]]*)firebase_storage$" "\\1#firebase_storage" PLUGINS_CONTENT "${PLUGINS_CONTENT}")
  
  # Write back the modified content
  file(WRITE ${PLUGINS_FILE} "${PLUGINS_CONTENT}")
  
  message(STATUS "✓ Firebase plugins removed from Windows build")
endif()

