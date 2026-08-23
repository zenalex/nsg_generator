import 'dart:io';

import 'misc.dart';
import 'nsgGenCSProject.dart';
import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenEnum.dart';
import 'nsgGenLocalization.dart';
import 'nsgGenSupportChat.dart';

class NsgGenerator {
  final String targetFramework;
  final bool isDotNetCore;
  String cSharpPath;
  final String cSharpNamespace;
  String dartPath;
  final String applicationName;
  final bool useStaticDatabaseNames;
  final bool useLocalization;
  final String defaultLocale;
  final bool newTableLogic;
  final List<NsgGenController> controllers;
  final List<NsgGenEnum> enums;

  /// Чат поддержки Chatista Connect (см. NsgGenSupportChat).
  /// По умолчанию выключен — на существующие конфиги не влияет.
  NsgGenSupportChat supportChat = NsgGenSupportChat(
      enabled: false,
      productExternalKey: '',
      typeName: NsgGenSupportChat.defaultTypeName);
  final Map<String, NsgGenDataItem> dataItems = Map();
  final Map<String, String> localizationDict = Map();
  bool doCSharp = true;
  bool doDart = true;
  bool forceOverwrite = false;
  bool copyCsproj = false;
  bool copyProgramCs = false;
  bool copyStartupCs = false;
  int dartLineLength = 160; // TODO: в json проектов

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
      this.doCSharp = true,
      this.doDart = true,
      this.useStaticDatabaseNames = false,
      this.controllers = const [],
      this.enums = const []});

  /// Ключи верхнего уровня, которые генератор умеет читать.
  static const knownProperties = <String>{
    'applicationName',
    'cSharpNamespace',
    'cSharpPath',
    'controller',
    'dartPath',
    'defaultLocale',
    'doCSharp',
    'doDart',
    'enums',
    'newTableLogic',
    'supportChat',
    'targetFramework',
    'useLocalization',
    'useStaticDatabaseNames',
  };

  /// Сказать вслух про ключи, которых генератор не знает.
  ///
  /// **Зачем.** Незнакомый ключ раньше пропускался совершенно молча, и это
  /// оборачивалось не пропущенной настройкой, а сломанным чужим
  /// репозиторием: 23.08.2026 конфиг titan_lk был переведён на `supportChat`,
  /// а генерация выполнена сборкой, где этого ключа ещё не было. Флаг
  /// проигнорировали, обвязка чата поддержки в вывод не попала, и приложение
  /// перестало компилироваться — притом что генерация отработала «успешно».
  ///
  /// **Почему предупреждение, а не отказ.** Отказ ломал бы конфиги, где
  /// лишние ключи лежат осознанно — комментарии, поля под будущие версии,
  /// настройки чужих инструментов. Расхождение версий надо показать, а не
  /// наказать за него.
  static void warnAboutUnknownProperties(Map<String, dynamic> parsedJson) {
    final unknown = parsedJson.keys
        .where((k) => !knownProperties.contains(k))
        .toList()
      ..sort();
    if (unknown.isEmpty) return;
    print('ВНИМАНИЕ: в generation_config.json есть ключи, которых этот '
        'генератор не знает: ${unknown.join(', ')}.');
    print('Они НЕ применены. Если ключ должен работать — обновите генератор: '
        'скорее всего, ваша сборка старее конфига.');
  }

  factory NsgGenerator.fromJson(Map<String, dynamic> parsedJson) {
    String currentProperty = 'targetFramework';
    try {
      warnAboutUnknownProperties(parsedJson);
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
      // Чат поддержки: разворачиваем флаг в обычные метаданные (тип + функция)
      // ДО разбора контроллеров, чтобы дальше работал штатный конвейер.
      currentProperty = 'supportChat';
      var supportChat = NsgGenSupportChat.fromJson(
          parsedJson['supportChat'], parsedJson['applicationName'] ?? '');
      supportChat.injectInto(parsedJson);

      currentProperty = 'controller';
      var controllers = (parsedJson['controller'] as List)
          .map((i) => NsgGenController.fromJson(i))
          .toList();
      currentProperty = '';
      return NsgGenerator(
          targetFramework: targetFramework,
          isDotNetCore: isDotNetCore,
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
          enums: enums)
        ..supportChat = supportChat;
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
    await Future.forEach<NsgGenController>(controllers, (element) async {
      print('generating ${element.className}');
      await element.generateCode(this);
    });
    if (doDart) {
      await NsgGenController.generateControllerOptions(this, controllers);
    }
    await NsgGenEnum.generateEnums(this, enums);
    await NsgGenLocalization.writeLocalization(this);
  }
}
