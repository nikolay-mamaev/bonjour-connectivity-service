BonjourConnectivityService for iOS and Mac
============================

Universal binaries (single file for Mac OS X, iOS, iOS Simulator) built with the following settings:
- Mac OS X: Base SDK 10.9, OS X Deployment Target 10.8
- iOS: Base SDK 7.0, iOS Deployment Target 5.0

To use the library in your project, please do the following steps:

1. Open you project in XCode, add all .h & .a files to the project.

2. In your project's settings, in the ‘Build Settings’ tab, ‘Linking’ section, expand ‘Other Linker Flags’ sub-section and add the following flags:
- Debug: 
```shell
-lJSONCoding-universal-debug, -lBonjourConnectivityService-universal-debug
```
- Release:
```shell
-lJSONCoding-universal-release, -lBonjourConnectivityService-universal-release
```
