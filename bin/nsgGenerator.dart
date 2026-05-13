import 'dart:io';

import 'misc.dart';
import 'nsgGenCSProject.dart';
import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenEnum.dart';
import 'nsgGenLocalization.dart';
import 'schema_hash.dart';

/// Тип серверного эмита. Ортогонален `targetFramework` (тот — версия runtime).
/// - `nsgframework` (default): текущий эмит C# поверх NsgSoft framework.
///   `pg*`-поля в JSON игнорируются (additive, не ломают конфиги).
/// - `netcore`: новый эмит EF Core + Postgres. Шаблоны — TASK04 §2.1.4+.
///   Требует `pgTableName` на каждой сущности и `pgColumnName` на каждом
///   поле с непустым `databaseName`.
class NsgServerEmitKind {
  static const String nsgframework = 'nsgframework';
  static const String netcore = 'netcore';
  static const List<String> values = [nsgframework, netcore];
}

class NsgGenerator {
  final String targetFramework;
  final bool isDotNetCore;
  final String serverEmitKind;
  String cSharpPath;
  final String cSharpNamespace;

  /// Путь вывода для netcore-эмита (EF Core + Postgres). Изолирует netcore-вывод
  /// от `cSharpPath`, чтобы on-first-run netcore-эмит не уничтожал ручные
  /// бизнес-партиалы NsgFramework-проекта (TASK04 §2.1.3, ремарка №3 ревью).
  /// В режиме `serverEmitKind: "netcore"` обязателен; в `nsgframework` —
  /// игнорируется (без warning).
  String netcoreOutputPath;
  String dartPath;
  final String applicationName;
  final bool useStaticDatabaseNames;
  final bool useLocalization;
  final String defaultLocale;
  final bool newTableLogic;
  final List<NsgGenController> controllers;
  final List<NsgGenEnum> enums;
  final Map<String, NsgGenDataItem> dataItems = Map();
  final Map<String, String> localizationDict = Map();
  bool doCSharp = true;
  bool doDart = true;
  bool forceOverwrite = false;
  bool copyCsproj = false;
  bool copyProgramCs = false;
  bool copyStartupCs = false;

  String? jsonPath;

  NsgGenerator(
      {required this.targetFramework,
      required this.isDotNetCore,
      required this.cSharpPath,
      required this.cSharpNamespace,
      required this.dartPath,
      required this.applicationName,
      required this.useLocalization,
      required this.defaultLocale,
      required this.newTableLogic,
      this.serverEmitKind = NsgServerEmitKind.nsgframework,
      this.netcoreOutputPath = '',
      this.doCSharp = true,
      this.doDart = true,
      this.useStaticDatabaseNames = false,
      this.controllers = const [],
      this.enums = const []});

  factory NsgGenerator.fromJson(Map<String, dynamic> parsedJson) {
    String currentProperty = 'targetFramework';
    try {
      var targetFramework = parsedJson['targetFramework'] ?? 'net10.0';
      if (targetFramework.isEmpty) targetFramework = 'net10.0';
      var isDotNetCore = [
        'netcoreapp1.0',
        'netcoreapp1.1',
        'netcoreapp2.0',
        'netcoreapp2.1',
        'netcoreapp2.2',
        'netcoreapp3.0',
        'netcoreapp3.1',
        'net5.0',
        'net6.0',
        'net7.0',
        'net8.0',
        'net9.0',
        'net10.0'
      ].contains(targetFramework);
      currentProperty = 'cSharpNamespace';
      var doCSharp = Misc.parseBoolOrTrue(parsedJson['doCSharp']);
      var cSharpNamespace = parsedJson['cSharpNamespace'] ?? '';
      if (doCSharp && cSharpNamespace.toString().isEmpty) {
        throw Exception(
            'Missing property $currentProperty while doCSharp == true');
      }
      var enums = <NsgGenEnum>[];
      if (parsedJson.containsKey('enums')) {
        currentProperty = 'enums';
        enums = (parsedJson['enums'] as List)
            .map((i) => NsgGenEnum.fromJson(i))
            .toList();
      }
      currentProperty = 'serverEmitKind';
      var serverEmitKind =
          (parsedJson['serverEmitKind'] ?? NsgServerEmitKind.nsgframework)
              .toString();
      if (!NsgServerEmitKind.values.contains(serverEmitKind)) {
        throw Exception(
            'serverEmitKind="$serverEmitKind" is not valid. '
            'Allowed: ${NsgServerEmitKind.values.join(", ")}.');
      }
      currentProperty = 'netcoreOutputPath';
      var netcoreOutputPath =
          (parsedJson['netcoreOutputPath'] ?? '').toString();
      // Ранняя статическая валидация: netcore требует netcoreOutputPath.
      // Семантическая валидация pg*-полей (`validateForNetcoreEmit`) идёт
      // позже — после загрузки controllers и dataItems.
      if (serverEmitKind == NsgServerEmitKind.netcore &&
          netcoreOutputPath.isEmpty) {
        throw Exception(
            'netcoreOutputPath is required when serverEmitKind="netcore".');
      }
      currentProperty = 'controller';
      var controllers = (parsedJson['controller'] as List)
          .map((i) => NsgGenController.fromJson(i))
          .toList();
      currentProperty = '';
      return NsgGenerator(
          targetFramework: targetFramework,
          isDotNetCore: isDotNetCore,
          serverEmitKind: serverEmitKind,
          netcoreOutputPath: netcoreOutputPath,
          cSharpPath: parsedJson['cSharpPath'] ?? '',
          cSharpNamespace: parsedJson['cSharpNamespace'] ?? '',
          dartPath: parsedJson['dartPath'] ?? '',
          doCSharp: doCSharp,
          doDart: Misc.parseBoolOrTrue(parsedJson['doDart']),
          applicationName: parsedJson['applicationName'] ?? 'application',
          useLocalization: Misc.parseBool(parsedJson['useLocalization']),
          defaultLocale: parsedJson['defaultLocale'] ?? 'ru',
          newTableLogic: Misc.parseBool(parsedJson['newTableLogic']),
          useStaticDatabaseNames:
              Misc.parseBool(parsedJson['useStaticDatabaseNames']),
          controllers: controllers,
          enums: enums);
    } catch (e) {
      print(
          '--- ERROR parsing${currentProperty.isEmpty ? '' : ' property \'$currentProperty\' from'} generation_config.json ---');
      rethrow;
    }
  }

  String get genPathName => 'generated';
  String get dartPathGen => dartPath + '/' + genPathName;

  Future writeCode(String path) async {
    jsonPath = path;
    // В режиме `netcore` текущий NsgFramework C#-эмит пропускается; шаблоны
    // нового EF Core эмита реализуются отдельно — см. TASK04 §2.1.4+.
    // Dart-эмит выполняется как обычно.
    if (serverEmitKind == NsgServerEmitKind.netcore && doCSharp) {
      print('netcore: NsgFramework C# emit skipped. '
          'EF Core templates not yet implemented (see TASK04 §2.1.4+).');
      doCSharp = false;
    }
    Directory dir;
    if (doCSharp) {
      dir = Directory(cSharpPath);
      await dir.create();
      NsgGenCSProject.generateProject(this);
      dir = Directory(cSharpPath + '/Controllers/');
      await dir.create();
      dir = Directory(cSharpPath + '/Models/');
      await dir.create();
      if (enums.isNotEmpty) {
        dir = Directory(cSharpPath + '/Enums/');
        await dir.create();
      }
    }
    if (doDart) {
      dir = Directory(dartPath);
      await dir.create();
      dir = Directory(dartPathGen);
      await dir.create();
      dir = Directory(dartPath + '/options/');
      await dir.create();
      if (enums.isNotEmpty) {
        dir = Directory(dartPath + '/enums/');
        await dir.create();
      }
    }

    await generateCode();
  }

  Future generateCode() async {
    await Future.forEach<NsgGenController>(controllers, (element) async {
      print('loading ${element.className}');
      await element.load(this);
    });
    // В режиме netcore валидация наличия pgTableName/pgColumnName на всех
    // сущностях/полях — до начала эмита.
    if (serverEmitKind == NsgServerEmitKind.netcore) {
      validateForNetcoreEmit();
    }
    await Future.forEach<NsgGenController>(controllers, (element) async {
      print('generating ${element.className}');
      await element.generateCode(this);
    });
    if (doDart) {
      await NsgGenController.generateControllerOptions(this, controllers);
      await _writeSchemaMeta();
    }
    await NsgGenEnum.generateEnums(this, enums);
    await NsgGenLocalization.writeLocalization(this);
  }

  /// Проверяет, что все сущности и поля размечены `pgTableName`/`pgColumnName`,
  /// требуемыми для netcore-эмита (TASK02 §«Архитектурные решения» №2).
  /// Поля без `databaseName` (write-only/derived) пропускаются — у них нет
  /// SQL-маппинга и в БД они не попадают.
  void validateForNetcoreEmit() {
    final errors = <String>[];
    for (final di in dataItems.values) {
      if (di.pgTableName.isEmpty) {
        errors.add(
            'pgTableName is required on type "${di.typeName}".');
      }
      for (final f in di.fields) {
        if (f.databaseName.isEmpty) continue;
        if (f.pgColumnName.isEmpty) {
          errors.add(
              'pgColumnName is required on field "${f.name}" of "${di.typeName}" '
              '(databaseName="${f.databaseName}").');
        }
      }
    }
    if (errors.isNotEmpty) {
      throw Exception(
          'netcore validation failed:\n  - ${errors.join("\n  - ")}');
    }
  }

  /// Эмитит `<dartPathGen>/_schema_meta.dart` с константой `kNsgSchemaHash`.
  /// Хеш — fnv1a-64 по канонизации ВСЕХ `*.json` в корне GeneratorConfig.
  /// Семантика и правила канонизации — см. TASK01.md (этап 0).
  Future<void> _writeSchemaMeta() async {
    final root = jsonPath;
    if (root == null || root.isEmpty) {
      print('schema_meta: jsonPath is empty, skipping');
      return;
    }
    final hash = await SchemaHash.compute(root);
    final content = '// GENERATED BY nsg_generator. DO NOT EDIT.\n'
        '// Hash of GeneratorConfig (see TASK01.md for canonicalization rules).\n'
        '// Semantics: informational only — server logs mismatch but does not reject.\n'
        '\n'
        "const String kNsgSchemaHash = '$hash';\n";
    final path = '$dartPathGen/_schema_meta.dart';
    await Misc.writeFileIfChanged(path, content);
    print('schema_meta: $hash → $path');
  }
}
