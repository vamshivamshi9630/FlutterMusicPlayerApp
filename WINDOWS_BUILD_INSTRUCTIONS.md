# Windows Build Instructions

## Project Status
This Flutter music player app has been configured for Windows desktop builds with guest-mode support and Windows-specific plugin exclusions.

### Features Implemented
- ✅ Google Sign-In authentication (Android/iOS only)
- ✅ Guest browsing mode (especially for Windows where Firebase is disabled)
- ✅ Local audio playback with search and favorites
- ✅ Search history persistence (last 10 searches)
- ✅ Album player with play controls
- ✅ Download management
- ✅ Offline mode support
- ✅ Windows UI with player controls positioned above bottom edge (SafeArea)

### Android/iOS Status
- ✅ Firebase Core, Auth, Firestore, Storage fully integrated
- ✅ Google Sign-In working
- ✅ Cloud sync ready (implementation stubbed)

### Windows Status
- ✅ Guest-only mode (no Firebase SDK required)
- ✅ Analyzer: All errors fixed (0 errors, ~130 infos/warnings—mostly `avoid_print`)
- ✅ Plugin configuration: Firebase plugins excluded from Windows build (see `windows/flutter/generated_plugins.cmake`)
- ⚠️ Native build: Requires Visual Studio 2019+ with C++ tools and Windows 10 SDK

## Building for Windows

### Prerequisites
1. **Flutter**: Latest stable version (`flutter --version`)
2. **Visual Studio 2019 or 2022**: With C++ development tools
3. **Windows 10 SDK** (matching VS version)
4. **CMake**: Usually installed with Visual Studio

### Clean Build
```bash
flutter clean
rm -r build/windows -Force  # PowerShell; on cmd: rmdir build\windows /s /q
flutter pub get
```

### Build Steps
```bash
# Debug build (faster, recommended for testing)
flutter build windows

# Release build (optimized, larger initial download)
flutter build windows --release
```

### Output Location
- **Debug**: `build/windows/runner/Debug/music_player.exe`
- **Release**: `build/windows/runner/Release/music_player.exe`

### Troubleshooting

#### CMake Platform Mismatch
**Error**: `Does not match the platform used previously: Either remove the CMakeCache.txt file...`

**Fix**:
```bash
rm -r build/windows -Force  # Clear build cache
flutter build windows
```

#### Firebase Plugin Errors (Windows)
This is expected and intentional. Firebase plugins are:
- **Included in pubspec.yaml** (for Android/iOS)
- **Excluded at CMake level** for Windows (see `windows/flutter/generated_plugins.cmake`)

Windows uses guest-only mode via `AuthService` detection.

#### Long Build Times
- First build takes 5–10 minutes (downloading SDKs, compiling)
- Subsequent builds: 2–3 minutes
- Use `-j8` or adjust Visual Studio project settings for parallel compilation

#### "Error MSB8066: Custom build for ... exited with code 1"
This usually indicates a missing dependency or plugin configuration issue. Ensure:
1. `windows/flutter/generated_plugins.cmake` excludes Firebase plugins
2. All required plugins (audioplayers_windows, connectivity_plus) are installed
3. Run `flutter pub get` before rebuilding

## Project Structure
```
lib/
├── main.dart                   # App entry point (guest mode for Windows)
├── albums_screen.dart          # Albums listing with search (AppBar, PopScope)
├── player_screen.dart          # Full player UI (SafeArea positioned controls)
├── models/                      # Song model
├── screens/                     # Login, downloads, offline screens
├── services/                    # Audio, auth, connectivity, downloads, Firebase (Android/iOS)
└── widgets/                     # Mini player, etc.

windows/
├── flutter/generated_plugins.cmake  # Firebase plugins excluded
├── CMakeLists.txt              # Windows build config
└── runner/                      # Native Windows app code
```

## Environment Variables
Set these for faster/optimized builds:
```powershell
$env:FLUTTER_BUILD_VERBOSE = 1  # See build details
$env:FLU TTER_ANDROID_SDK = "C:\Android\sdk"  # (optional, for multi-platform)
```

## Sharing the Build
To share the Windows exe:
1. Build with `flutter build windows --release`
2. Archive: `build/windows/runner/Release/music_player.exe` + required DLL dependencies
   - Or: Use `msix` plugin to create Windows Installer (`.msix`)
   - Or: Zip the entire `Release` folder

### Creating a Windows Installer (Optional)
```bash
flutter pub add msix
flutter pub run msix:create
```
Output: `build/windows/runner/Release/music_player.msix`

## Analysis & Testing
```bash
# Run analyzer (should show only infos/warnings, no errors)
flutter analyze

# Run on connected Windows desktop
flutter run -d windows

# Run tests
flutter test
```

## Additional Notes
- **Print statements**: `avoid_print` lints appear throughout (for debugging). Safe to ignore or replace with logging framework if needed.
- **WillPopScope deprecation**: Migrated to `PopScope` in `albums_screen.dart`
- **withOpacity deprecation**: Replaced with `withValues(alpha: ...)` in player_screen & login_screen
- **Search history**: Persisted in SharedPreferences; dropdown in AppBar search field

## Support
For Flutter documentation: https://flutter.dev/docs/deployment/windows

---
**Last Updated**: December 19, 2025
**Flutter Version**: 3.x+
