# Beatfy

Offline music player for Android. Plays MP3 files already on your device
no streaming, no ads, no third-party analytics. Built with Flutter.

## Privacy

Beatfy does not collect any user data, and has no ads or third-party
analytics. The only data that ever leaves your device is the music files
backed up to **your own** Google Drive account, and only if you turn the
backup feature on Beatfy has no server of its own that stores anything.

Google Sign-In is used solely to authorize that Drive backup and is entirely
optional; every core feature (offline playback) works fully without signing
in. The Drive access requested is the `drive.file` scope, which only grants
access to files Beatfy itself creates in your Drive — never your full Drive
contents.

Beatfy is open source, so you (or anyone) can read exactly what the code
does rather than take this description on faith.

### "Google hasn't verified this app"

If you sign in with Google, you may see a warning that Google hasn't
verified this app. That's expected and not a sign of malware it's simply
what Google shows for any personal/open-source app that hasn't gone through
their (paid, business-oriented) verification process. Click through to
continue if you trust the source you downloaded the APK from (see below).

## Installing

Grab the APK from the [Releases](../../releases) page. Since this isn't
published on the Play Store, Android will warn about installing from an
unknown source that's normal for sideloaded APKs.

To verify the APK you downloaded matches the official release and hasn't
been tampered with, compare its SHA-256 signing fingerprint against the one
published here:

```
SHA-256: B3:2C:97:C4:AC:7D:83:80:EC:60:11:3D:10:D9:69:4C:4D:E5:C7:4B:16:4A:C0:D8:CF:F5:9E:50:18:84:D6:B7
```

## Building from source

```
flutter pub get
flutter run
```

### Release build

The debug keystore is used automatically until a release keystore is set
up (`flutter build apk --release` will still work, but the resulting APK
must not be distributed until real signing is configured). To set one up:

1. Generate a keystore (do this once, keep the file and passwords safe —
   losing them means future releases can never be signed to match earlier
   ones):

   ```
   keytool -genkey -v -keystore beatfy-release.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias beatfy
   ```

   Place the resulting `beatfy-release.jks` **outside** of version control
   (e.g. `android/beatfy-release.jks` already covered by
   `android/.gitignore`'s `**/*.jks` rule).

2. Copy `android/key.properties.example` to `android/key.properties` and
   fill in the real `storePassword`/`keyPassword`/`storeFile` path.
   `key.properties` is git-ignored and must never be committed.

3. Build the release APK:

   ```
   flutter build apk --release
   ```

4. Get the SHA-256 fingerprint of the signing certificate (paste the result
   into the "Installing" section above when publishing a release):

   ```
   keytool -list -v -keystore android/beatfy-release.jks -alias beatfy
   ```
