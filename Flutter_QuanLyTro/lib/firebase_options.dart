
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEYLO3YbmlrsFHP-pw0hLcYE53f4GycH0',
    appId: '1:744024889096:android:03d9496d85543df3f23ebd',
    messagingSenderId: '744024889096',
    projectId: 'quanlytro-be',
    storageBucket: 'quanlytro-be.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNZN1moR3XSYm5_R2E3HtBoqn9Us8M5n8',
    appId: '1:744024889096:ios:bcd44886170e6553f23ebd',
    messagingSenderId: '744024889096',
    projectId: 'quanlytro-be',
    storageBucket: 'quanlytro-be.firebasestorage.app',
    iosBundleId: 'com.example.flutterQuanlytro',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDNZN1moR3XSYm5_R2E3HtBoqn9Us8M5n8',
    appId: '1:744024889096:ios:bcd44886170e6553f23ebd',
    messagingSenderId: '744024889096',
    projectId: 'quanlytro-be',
    storageBucket: 'quanlytro-be.firebasestorage.app',
    iosBundleId: 'com.example.flutterQuanlytro',
  );
}
