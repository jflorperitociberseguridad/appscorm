import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions not configured for this platform.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions not configured for this platform.');
    }
  }

  // TODO: Replace these values with your Firebase project settings.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    authDomain: 'TU_AUTH_DOMAIN',
    storageBucket: 'TU_BUCKET',
    measurementId: 'TU_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_BUCKET',
    iosBundleId: 'TU_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_BUCKET',
    iosBundleId: 'TU_MACOS_BUNDLE_ID',
  );
}
