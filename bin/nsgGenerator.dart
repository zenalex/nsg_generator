import 'dart:io';

import 'nsgGenCSProject.dart';
import 'nsgGenController.dart';
import 'nsgGenEnum.dart';

class NsgGenerator {
  final String targetFramework;
  final String cSharpPath;
  final String cSharpNamespace;
  final String dartPath;
  final List<NsgGenController> controllers;
  final List<NsgGenEnum> enums;

  String jsonPath;
  static NsgGenerator generator;

  NsgGenerator(
      {this.targetFramework,
      this.cSharpPath,
      this.cSharpNamespace,
      this.dartPath,
      this.controllers,
      this.enums});

  factory NsgGenerator.fromJson(Map<String, dynamic> parsedJson) {
    var targetFramework = parsedJson['targetFramework'] ?? 'net5.0';
    if (targetFramework.isEmpty) targetFramework = 'net5.0';
    var enums;
    if (parsedJson.containsKey('enums')) {
      enums = (parsedJson['enums'] as List)
          .map((i) => NsgGenEnum.fromJson(i))
          .toList();
    }
    generator = NsgGenerator(
        targetFramework: targetFramework,
        cSharpPath: parsedJson['cSharpPath'],
        cSharpNamespace: parsedJson['cSharpNamespace'],
        dartPath: parsedJson['dartPath'],
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
    var dir = Directory(cSharpPath);
    await dir.create();
    NsgGenCSProject.generateProject(this);
    dir = Directory(cSharpPath + '/Controllers/');
    await dir.create();
    dir = Directory(cSharpPath + '/Models/');
    await dir.create();
    dir = Directory(dartPath);
    await dir.create();
    dir = Directory(dartPathGen);
    await dir.create();
    if (enums != null && enums.isNotEmpty) {
      dir = Directory(cSharpPath + '/Enums/');
      await dir.create();
      dir = Directory(dartPath + '/enums/');
      await dir.create();
    }

    await generateCode();
  }

  Future generateCode() async {
    await Future.forEach<NsgGenController>(controllers, (element) async {
      print('loading ${element.class_name}');
      await element.load(this);
    });
    await Future.forEach<NsgGenController>(controllers, (element) async {
      print('generating ${element.class_name}');
      await element.generateCode(this);
    });
    await NsgGenEnum.generateEnums(this, enums);
  }

  String getDartName(String dn) {
    if (dn == null || dn.isEmpty) return dn;
    var fc = dn.substring(0, 1);
    if (fc.toLowerCase() != fc) {
      dn = fc.toLowerCase() + dn.substring(1);
    }
    return dn;
  }

  String getDartUnderscoreName(String dn) {
    if (dn == null || dn.isEmpty) return dn;
    var exp = RegExp(r'(?<=[a-z])[A-Z]');
    dn =
        dn.replaceAllMapped(exp, (Match m) => ('_' + m.group(0))).toLowerCase();
    return dn;
  }
}
