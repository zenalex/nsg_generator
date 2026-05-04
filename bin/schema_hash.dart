import 'dart:convert';
import 'dart:io';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Детерминированный хеш схемы GeneratorConfig.
///
/// Алгоритм — FNV-1a-64. Канонизация:
/// 1. Берутся ВСЕ `*.json` файлы рекурсивно от корня. Сортировка — лексикографически
///    по относительному пути с прямыми слешами (case-sensitive).
/// 2. Каждый файл парсится через `jsonDecode` → переэмитится через `jsonEncode`
///    с отсортированными ключами на всех уровнях.
/// 3. Ключи объектов со значением `null` отбрасываются рекурсивно. В массивах
///    `null` сохраняется (позиция значима).
/// 4. Все строки и ключи объектов нормализуются в Unicode NFC.
/// 5. Хеш — fnv1a-64 от потока `<rel-path>\0<canonical-json>\0` для каждого файла
///    в порядке п. 1.
///
/// Вывод — 16-символьная hex-строка нижним регистром.
class SchemaHash {
  /// Считает хеш по всем `*.json` файлам в [rootDir] (рекурсивно).
  static Future<String> compute(String rootDir) async {
    final root = Directory(rootDir);
    if (!await root.exists()) {
      throw FileSystemException('Schema root not found', rootDir);
    }
    final entries = <_FileEntry>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
        entries.add(_FileEntry(_relPath(root.path, entity.path), entity));
      }
    }
    entries.sort((a, b) => a.relPath.compareTo(b.relPath));

    var hash = _fnv1aOffset;
    for (final e in entries) {
      final raw = await e.file.readAsString();
      final canonical = canonicalizeJson(raw);
      hash = _fnv1aBytes(hash, utf8.encode(e.relPath));
      hash = _fnv1aByte(hash, 0);
      hash = _fnv1aBytes(hash, utf8.encode(canonical));
      hash = _fnv1aByte(hash, 0);
    }
    return _toUnsignedHex64(hash);
  }

  static String _toUnsignedHex64(int v) {
    // Dart VM int — 64-bit signed; для отрицательных битпаттернов
    // `int.toUnsigned(64)` не помогает (значение не помещается). BigInt — да.
    return BigInt.from(v).toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  /// Канонизирует одиночный JSON-текст. Публичная для unit-тестов.
  /// BOM (U+FEFF) в начале текста стрипается до парсинга.
  static String canonicalizeJson(String text) {
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    return jsonEncode(_normalize(jsonDecode(text)));
  }

  // --- internals ---

  static dynamic _normalize(dynamic v) {
    if (v == null) return null;
    if (v is String) return unorm.nfc(v);
    if (v is Map) {
      final keep = <String, dynamic>{};
      for (final entry in v.entries) {
        if (entry.value == null) continue;
        keep[unorm.nfc(entry.key.toString())] = _normalize(entry.value);
      }
      final sortedKeys = keep.keys.toList()..sort();
      final out = <String, dynamic>{};
      for (final k in sortedKeys) {
        out[k] = keep[k];
      }
      return out;
    }
    if (v is List) {
      return v.map(_normalize).toList();
    }
    return v;
  }

  static String _relPath(String rootPath, String filePath) {
    var rel = filePath;
    if (rel.startsWith(rootPath)) {
      rel = rel.substring(rootPath.length);
    }
    rel = rel.replaceAll(r'\', '/');
    if (rel.startsWith('/')) rel = rel.substring(1);
    return rel;
  }

  // FNV-1a-64. Dart VM int is 64-bit; * wraps mod 2^64 in bit pattern.
  static const int _fnv1aOffset = 0xcbf29ce484222325;
  static const int _fnv1aPrime = 0x100000001b3;

  static int _fnv1aByte(int h, int b) {
    h = h ^ b;
    h = h * _fnv1aPrime;
    return h;
  }

  static int _fnv1aBytes(int h, List<int> bytes) {
    for (final b in bytes) {
      h = _fnv1aByte(h, b);
    }
    return h;
  }
}

class _FileEntry {
  final String relPath;
  final File file;
  _FileEntry(this.relPath, this.file);
}
