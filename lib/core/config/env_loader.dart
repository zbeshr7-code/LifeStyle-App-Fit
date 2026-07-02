import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Bundled config for release/web builds (Firebase Hosting ignores dotfiles like `.env`).
const bundledEnvAsset = 'assets/config/app.env';

Future<void> loadAppEnv() async {
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      return;
    } catch (_) {
      // Local `.env` is optional; fall back to bundled config.
    }
  }

  await dotenv.load(fileName: bundledEnvAsset);
}
