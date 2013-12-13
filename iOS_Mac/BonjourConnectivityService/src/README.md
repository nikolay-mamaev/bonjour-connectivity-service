BonjourConnectivityService for iOS and Mac
============================

To compile & install library files into your project, please do the following steps:

1. In XCode with opened 'BonjourConnectivityService' project, edit the 'BonjourConnectivityService_iOS' build scheme, select 'Run' in the left pane, make sure that the 'Debug' value is selected in the 'Build Configuration' drop-down list. Do the same for 'BonjourConnectivityService_MacOS' build scheme

2. Build the project 3 times:
+ For 'BonjourConnectivityService_iOS' build scheme, iOS device
+ For 'BonjourConnectivityService_iOS' build scheme, iPad Simulator
+ For 'BonjourConnectivityService_MacOS' build scheme
         
Doing this will give you 3 directories like this in your respective Xcode/DerivedData directory. Mine are these:
```shell
~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/Build/Products/Debug
~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/Build/Products/Debug-iphoneos
~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/Build/Products/Debug-iphonesimulator
```

3. Repeat steps 1 & 2 for 'Release' build configuration. As result, you'll have additional 3 directories:
```shell
~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/Build/Products/Release
~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/Build/Products/Release-iphoneos 
~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/Build/Products/Release-iphonesimulator
```

4. Change to your project's DerivedData directory:
```shell
cd ~/Library/Developer/Xcode/DerivedData/BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm/
```

5. Execute the following commands:
```shell
<BonjourConnectivityService_project_location>/makefat -debug
<BonjourConnectivityService_project_location>/makefat -release
```

You now have this:

```shell   nmamaev-mac:BonjourConnectivityService-adudfboalbabrvbyvmuebpzflxnm ruinnmam$ ls -1F Build
   Intermediates/
   Products/
   libBonjourConnectivityService-universal-debug.a
   libBonjourConnectivityService-universal-release.a
   libJSONCoding-universal-debug.a
   libJSONCoding-universal-release.a
```

6. Copy these files to your XCode project directory (or sub-directory).

7. Copy all header files from <BonjourConnectivityService_project_location>/BonjourConnectivityService/interface directory to your XCode project directory (or sub-directory).

8. Open you project in XCode, add all .h & .a files to the project.

9. In your project's settings, in the ‘Build Settings’ tab, ‘Linking’ section, expand ‘Other Linker Flags’ sub-section and add the following flags:
- Debug: -lJSONCoding-universal-debug, -lBonjourConnectivityService-universal-debug
- Release: -lJSONCoding-universal-release, -lBonjourConnectivityService-universal-release
