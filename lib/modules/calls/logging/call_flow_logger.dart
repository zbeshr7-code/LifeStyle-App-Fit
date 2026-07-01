import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// End-to-end call flow logging. Filter Logcat/console with: `[Call]`
abstract final class CallFlowLogger {
  static final Logger _log = Logger(
    level: kDebugMode ? Level.trace : Level.warning,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 110,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void trace(
    String step, {
    Map<String, Object?>? context,
  }) {
    _log.t(_line('TRACE', step, context));
  }

  static void info(
    String step, {
    Map<String, Object?>? context,
  }) {
    _log.i(_line('INFO', step, context));
  }

  static void warn(
    String step, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.w(
      _line('WARN', step, context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String step, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log.e(
      _line('ERROR', step, context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String tokenPreview(String token) {
    if (token.isEmpty) return '(empty)';
    if (token.length <= 16) return 'len=${token.length}';
    return '${token.substring(0, 8)}…len=${token.length}';
  }

  static String _line(
    String level,
    String step,
    Map<String, Object?>? context,
  ) {
    final ctx = _formatContext(context);
    return ctx.isEmpty ? '[Call][$level] $step' : '[Call][$level] $step | $ctx';
  }

  static String _formatContext(Map<String, Object?>? context) {
    if (context == null || context.isEmpty) return '';
    return context.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
  }
}
