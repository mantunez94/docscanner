import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  final String tag;
  final bool enabled;

  const Logger({this.tag = '', this.enabled = true});

  void d(String message) => _log(LogLevel.debug, message);
  void i(String message) => _log(LogLevel.info, message);
  void w(String message) => _log(LogLevel.warning, message);
  void e(String message) => _log(LogLevel.error, message);

  void _log(LogLevel level, String message) {
    if (!enabled) return;
    final prefix = switch (level) {
      LogLevel.debug => '[D]',
      LogLevel.info => '[I]',
      LogLevel.warning => '[W]',
      LogLevel.error => '[E]',
    };
    final tagStr = tag.isNotEmpty ? '[$tag]' : '';
    final line = '$prefix$tagStr $message';
    debugPrint(line);
  }
}

final appLogger = Logger(tag: 'DocScanner', enabled: true);
