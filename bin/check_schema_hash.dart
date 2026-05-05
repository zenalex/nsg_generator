import 'dart:io';

import 'schema_hash.dart';

/// Golden-проверка хеша схемы GeneratorConfig.
///
/// Использование:
///   dart run nsg_generator:check_schema_hash \
///       --config-dir <path> \
///       (--expected <hex> | --expected-file <path>)
///
/// Exit codes:
///   0 — хеш совпал. Вывод: `OK`.
///   1 — несовпадение. Вывод: `expected <hex>, got <hex>`.
///   2 — невалидный аргумент / директория или файл baseline не найдены.
///
/// Семантика — см. TASK01.md, §1.4 «Golden-тест baseline-а».
Future<int> run(List<String> args) async {
  String? configDir;
  String? expectedHex;
  String? expectedFile;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String? next() {
      if (i + 1 >= args.length) return null;
      i++;
      return args[i];
    }

    switch (a) {
      case '--config-dir':
        configDir = next();
        if (configDir == null) {
          stderr.writeln('error: --config-dir requires a value');
          return 2;
        }
        break;
      case '--expected':
        expectedHex = next();
        if (expectedHex == null) {
          stderr.writeln('error: --expected requires a hex value');
          return 2;
        }
        break;
      case '--expected-file':
        expectedFile = next();
        if (expectedFile == null) {
          stderr.writeln('error: --expected-file requires a path');
          return 2;
        }
        break;
      case '-h':
      case '--help':
        stdout.writeln(_usage);
        return 0;
      default:
        stderr.writeln('error: unknown argument: $a');
        stderr.writeln(_usage);
        return 2;
    }
  }

  if (configDir == null) {
    stderr.writeln('error: --config-dir is required');
    return 2;
  }
  if ((expectedHex == null) == (expectedFile == null)) {
    stderr.writeln(
        'error: exactly one of --expected or --expected-file is required');
    return 2;
  }

  if (!await Directory(configDir).exists()) {
    stderr.writeln('error: config-dir not found: $configDir');
    return 2;
  }

  if (expectedFile != null) {
    final f = File(expectedFile);
    if (!await f.exists()) {
      stderr.writeln('error: expected-file not found: $expectedFile');
      return 2;
    }
    expectedHex = (await f.readAsString()).trim();
    if (expectedHex.isEmpty) {
      stderr.writeln('error: expected-file is empty: $expectedFile');
      return 2;
    }
  }

  final actualHex = await SchemaHash.compute(configDir);
  if (actualHex == expectedHex) {
    stdout.writeln('OK');
    return 0;
  }
  stdout.writeln('expected $expectedHex, got $actualHex');
  return 1;
}

const String _usage = '''
Usage: dart run nsg_generator:check_schema_hash \\
           --config-dir <path> \\
           (--expected <hex> | --expected-file <path>)

Exit codes:
  0  hash matches            (prints "OK")
  1  hash mismatch           (prints "expected <hex>, got <hex>")
  2  bad argument / missing  (error to stderr)
''';

Future<void> main(List<String> args) async {
  exitCode = await run(args);
}
