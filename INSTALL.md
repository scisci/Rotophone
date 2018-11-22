After upgrading to Xcode 7.3 and copying the 10.6 SDK into Xcode.app, xcodebuild gave me the following error when building a 10.6 SDK-based project:

[MT] DVTSDK: Skipped SDK /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.6.sdk; its version (10.6) is below required minimum (10.11) for the macosx platform.

Xcode 7.3's /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Info.plist now contains a MinimumSDKVersion key which is set to 10.11. After removing this key/value from the Info.plist, building with the 10.6 SDK works as it did before.
I haven't tested XcodeLegacy, but I imagine it will need to make this change for Xcode 7.3+.

sdks here: https://github.com/phracker/MacOSX-SDKs

Update crt
Just copy crt1.10.6.o from MacOSX10.11.sdk /usr/lib/ to the same dir of your 10.7 sdk.
