import 'dart:io';

void main() {
  final pattern = RegExp(
    r'AppColors\.(primary|primaryForeground|error|iconMuted|textPrimary|textSecondary)',
  );
  final openers = RegExp(
    r'const\s+(Center|SizedBox|Padding|Icon|CircularProgressIndicator|TextStyle|BoxDecoration|DecoratedBox|Material|InkWell|Row|Column|Text)\s*[\(\{]',
  );
  final lib = Directory('lib');
  var files = 0;

  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final lines = entity.readAsLinesSync();
    var changed = false;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      while (line.contains('const ') && pattern.hasMatch(line)) {
        line = line.replaceFirst('const ', '');
        changed = true;
      }

      if (openers.hasMatch(line)) {
        final chunk = StringBuffer();
        for (var j = i; j < lines.length && j < i + 12; j++) {
          chunk.writeln(lines[j]);
          if (lines[j].contains(');') || lines[j].trim().endsWith('),')) {
            if (j > i) break;
          }
        }
        if (pattern.hasMatch(chunk.toString())) {
          line = line.replaceFirst('const ', '');
          changed = true;
        }
      }

      lines[i] = line;
    }

    if (changed) {
      entity.writeAsStringSync('${lines.join('\n')}\n');
      files++;
    }
  }

  stdout.writeln('Updated $files files.');
}
