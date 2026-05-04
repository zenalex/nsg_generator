import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/schema_hash.dart';

void main() {
  group('SchemaHash.canonicalizeJson', () {
    test('reordered keys produce identical canonical output', () {
      final a = '{"b":2,"a":1,"c":{"y":2,"x":1}}';
      final b = '{"a":1,"c":{"x":1,"y":2},"b":2}';
      expect(SchemaHash.canonicalizeJson(a), equals(SchemaHash.canonicalizeJson(b)));
    });

    test('null-valued keys are dropped from objects', () {
      final withNull = '{"a":1,"b":null,"c":3}';
      final without = '{"a":1,"c":3}';
      expect(
        SchemaHash.canonicalizeJson(withNull),
        equals(SchemaHash.canonicalizeJson(without)),
      );
    });

    test('null inside array is preserved positionally', () {
      final a = '{"arr":[1,null,3]}';
      final b = '{"arr":[1,3]}';
      expect(
        SchemaHash.canonicalizeJson(a),
        isNot(equals(SchemaHash.canonicalizeJson(b))),
      );
    });

    test('NFC and NFD forms of the same string canonicalize to the same bytes', () {
      // "ё" = U+0451 (NFC) vs "е" + U+0308 (NFD)
      final nfc = '{"name":"ёлка"}';
      final nfd = '{"name":"ёлка"}';
      expect(
        SchemaHash.canonicalizeJson(nfc),
        equals(SchemaHash.canonicalizeJson(nfd)),
      );
    });

    test('whitespace and CRLF between tokens do not affect canonical form', () {
      final compact = '{"a":1,"b":2}';
      final spaced = '{ "a" : 1 ,\r\n  "b" : 2 }';
      expect(
        SchemaHash.canonicalizeJson(compact),
        equals(SchemaHash.canonicalizeJson(spaced)),
      );
    });

    test('numeric form is preserved by jsonDecode/jsonEncode roundtrip', () {
      // Зафиксировано: 1 != 1.0; 1e2 → 100.0. Авторы схемы держат единый стиль.
      expect(SchemaHash.canonicalizeJson('{"x":1}'), '{"x":1}');
      expect(SchemaHash.canonicalizeJson('{"x":1.0}'), '{"x":1.0}');
      expect(SchemaHash.canonicalizeJson('{"x":1e2}'), '{"x":100.0}');
    });
  });

  group('SchemaHash.compute', () {
    final fixtures = Directory('test/fixtures');
    final baselineDir = '${fixtures.path}/case_baseline';

    test('hash is 16 lowercase hex chars', () async {
      final h = await SchemaHash.compute(baselineDir);
      expect(h, matches(RegExp(r'^[0-9a-f]{16}$')));
    });

    test('empty directory yields fnv1a-64 offset basis', () async {
      final tmp = await Directory.systemTemp.createTemp('schema_hash_empty_');
      try {
        final h = await SchemaHash.compute(tmp.path);
        expect(h, equals('cbf29ce484222325'));
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('two consecutive runs over the same directory produce identical hash', () async {
      final h1 = await SchemaHash.compute(baselineDir);
      final h2 = await SchemaHash.compute(baselineDir);
      expect(h1, equals(h2));
    });

    test('reordered keys + CRLF + BOM in fixture files do not change hash', () async {
      final tmp = await Directory.systemTemp.createTemp('schema_hash_perturb_');
      try {
        // Скопировать baseline-файлы, переставив ключи, добавив BOM и CRLF.
        final src = Directory(baselineDir);
        await for (final e in src.list()) {
          if (e is File && e.path.endsWith('.json')) {
            final parsed = jsonDecode(await e.readAsString());
            final reordered = _reorderKeysReverse(parsed);
            final crlfText = '﻿' +
                const JsonEncoder.withIndent('  ').convert(reordered).replaceAll('\n', '\r\n');
            final relName = e.uri.pathSegments.last;
            await File('${tmp.path}/$relName').writeAsString(crlfText);
          }
        }
        final hBaseline = await SchemaHash.compute(baselineDir);
        final hPerturbed = await SchemaHash.compute(tmp.path);
        expect(hPerturbed, equals(hBaseline));
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('content change shifts the hash', () async {
      final tmp = await Directory.systemTemp.createTemp('schema_hash_changed_');
      try {
        await File('${tmp.path}/x.json').writeAsString('{"a":1}');
        final h1 = await SchemaHash.compute(tmp.path);
        await File('${tmp.path}/x.json').writeAsString('{"a":2}');
        final h2 = await SchemaHash.compute(tmp.path);
        expect(h1, isNot(equals(h2)));
      } finally {
        await tmp.delete(recursive: true);
      }
    });
  });
}

dynamic _reorderKeysReverse(dynamic v) {
  if (v is Map) {
    final keys = v.keys.toList()..sort((a, b) => b.toString().compareTo(a.toString()));
    final out = <String, dynamic>{};
    for (final k in keys) {
      out[k.toString()] = _reorderKeysReverse(v[k]);
    }
    return out;
  }
  if (v is List) return v.map(_reorderKeysReverse).toList();
  return v;
}
