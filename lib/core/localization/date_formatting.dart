import 'package:intl/date_symbol_data_local.dart';

/// Loads locale data required by [DateFormat] for supported app languages.
Future<void> initializeAppDateFormatting() async {
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
}
