import 'dart:io';

import 'misc.dart';
import 'nsgGenCSProject.dart';
import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenEnum.dart';
import 'nsgGenLocalization.dart';

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
  final Map<String, NsgGenDataItem> dataItems = Map();
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
