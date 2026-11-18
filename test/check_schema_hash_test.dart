import 'dart:io';

import 'package:test/test.dart';

import '../bin/check_schema_hash.dart' as cli;
import '../bin/schema_hash.dart';

void main() {
  // Точная ссылка на baseline-фикстуру из schema_hash_test.dart, чтобы CLI не
  // зависела от изменений в `case_baseline` (если фикстуру правят, baseline
  // пересчитается через SchemaHash.compute и тест останется консистентным).
  late String fixtureDir;
  late String fixtureHash;

  setUpAll(() async {
    fixtureDir = 'test/fixtures/case_baseline';
    fixtureHash = await SchemaHash.compute(fixtureDir);
  });

  group('check_schema_hash CLI', () {
    test('exit 0 on match (--expected)', () async {
      final code = await cli.run([
        '--config-dir',
        fixtureDir,
        '--expected',
        fixtureHash,
      ]);
      expect(code, 0);
    });

    test('exit 1 on mismatch', () async {
      final code = await cli.run([
        '--config-dir',
        fixtureDir,
        '--expected',
        '0000000000000000',
      ]);
      expect(code, 1);
    });

    test('exit 2 on missing config-dir', () async {
      final code = await cli.run([
        '--config-dir',
        'test/fixtures/this_does_not_exist',
        '--expected',
        '0000000000000000',
      ]);
      expect(code, 2);
    });

    test('exit 2 on missing required arg', () async {
      final code = await cli.run(['--expected', '0000000000000000']);
      expect(code, 2);
    });

    test('exit 2 on both --expected and --expected-file', () async {
      final code = await cli.run([
        '--config-dir',
        fixtureDir,
        '--expected',
        '0000000000000000',
        '--expected-file',
        'foo',
      ]);
      expect(code, 2);
    });

    test('exit 2 on neither --expected nor --expected-file', () async {
      final code = await cli.run(['--config-dir', fixtureDir]);
      expect(code, 2);
    });

    test('exit 0 with --expected-file (matching)', () async {
      final tmp = await File.fromUri(
        Uri.file('${Directory.systemTemp.path}/nsg_check_expected_match.txt'),
      ).create();
      try {
        await tmp.writeAsString('$fixtureHash\n');
        final code = await cli.run([
          '--config-dir',
          fixtureDir,
          '--expected-file',
          tmp.path,
        ]);
        expect(code, 0);
      } finally {
        await tmp.delete();
      }
    });

    test('exit 1 with --expected-file (mismatching)', () async {
      final tmp = await File.fromUri(
        Uri.file('${Directory.systemTemp.path}/nsg_check_expected_miss.txt'),
      ).create();
      try {
        await tmp.writeAsString('deadbeefdeadbeef\n');
        final code = await cli.run([
          '--config-dir',
          fixtureDir,
          '--expected-file',
          tmp.path,
        ]);
        expect(code, 1);
      } finally {
        await tmp.delete();
      }
    });

    test('exit 2 on missing --expected-file', () async {
      final code = await cli.run([
        '--config-dir',
        fixtureDir,
        '--expected-file',
        '/no/such/file/here.txt',
      ]);
      expect(code, 2);
    });

    test('exit 2 on unknown argument', () async {
      final code = await cli.run([
        '--config-dir',
        fixtureDir,
        '--expected',
        fixtureHash,
        '--bogus-flag',
      ]);
      expect(code, 2);
    });
  });
}
