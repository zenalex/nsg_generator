import 'dart:io';

import 'nsgGenCSProject.dart';
import 'nsgGenController.dart';
import 'nsgGenEnum.dart';

class NsgGenerator {
  final String targetFramework;
  String cSharpPath;
  final String cSharpNamespace;
  String dartPath;
  final String applicationName;
  final List<NsgGenController> controllers;
  final List<NsgGenEnum> enums;
  bool doCSharp = true;
  bool doDart = true;
  bool forceOverwrite = false;
  bool copyCsproj = false;
  bool copyProgramCs = false;
  bool copyStartupCs = false;

  String? jsonPath;
  static late NsgGenerator generator;

  NsgGenerator(
      {this.targetFramework = 'net5.0',
      required this.cSharpPath,
      required this.cSharpNamespace,
      required this.dartPath,
      required this.applicationName,
      this.controllers = const [],
      this.enums = const []});

  factory NsgGenerator.fromJson(Map<String, dynamic> parsedJson) {
    var targetFramework = parsedJson['targetFramework'] ?? 'net5.0';
    if (targetFramework.isEmpty) targetFramework = 'net5.0';
    var enums = <NsgGenEnum>[];
    if (parsedJson.containsKey('enums')) {
      enums = (parsedJson['enums'] as List)
          .map((i) => NsgGenEnum.fromJson(i))
          .toList();
    }
    generator = NsgGenerator(
        targetFramework: targetFramework,
        cSharpPath: parsedJson['cSharpPath'] ?? '',
        cSharpNamespace: parsedJson['cSharpNamespace'] ?? '',
        dartPath: parsedJson['dartPath'] ?? '',
        applicationName: parsedJson['applicationName'] ?? 'application',
        controllers: (parsedJson['controller'] as List)
            .map((i) => NsgGenController.fromJson(i))
            .toList(),
        enums: enums);
    return generator;
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
  }
}
