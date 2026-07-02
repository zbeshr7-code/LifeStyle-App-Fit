import 'package:flutter_dotenv/flutter_dotenv.dart';

const bundledEnvAsset = 'assets/config/app.env';

Future<void> loadAppEnv() async {
  await dotenv.load(fileName: bundledEnvAsset);
}
