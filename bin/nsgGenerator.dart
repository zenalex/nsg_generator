import 'dart:io';

import 'nsgGenController.dart';

class NsgGenerator {
  final String cSharpPath;
  final String cSharpNamespace;
  final String dartPath;
  final List<NsgGenController> controllers;

  String jsonPath;
  static NsgGenerator generator;

  NsgGenerator(
      {this.cSharpPath, this.cSharpNamespace, this.dartPath, this.controllers});

  factory NsgGenerator.fromJson(Map<String, dynamic> parsedJson) {
    generator = NsgGenerator(
        cSharpPath: parsedJson['cSharpPath'],
        cSharpNamespace: parsedJson['cSharpNamespace'],
        dartPath: parsedJson['dartPath'],
        controllers: (parsedJson['controller'] as List)
            .map((i) => NsgGenController.fromJson(i))
            .toList());
    return generator;
  }

  String get genPathName => 'generated';
  String get dartPathGen => dartPath + '/' + genPathName;

  void writeCode(String path) async {
    jsonPath = path;
    var dir = Directory(cSharpPath);
    await dir.create();
    dir = Directory(dartPath);
    await dir.create();
    dir = Directory(dartPathGen);
    await dir.create();

    await generateCode();
  }

  void generateCode() async {
    controllers.forEach((element) {
      element.load(this);
      element.generateCode(this);
    });
  }

  String getDartName(String dn) {
    if (dn == null || dn.isEmpty) return dn;
    var fc = dn.substring(0, 1);
    if (fc.toLowerCase() != fc) {
      dn = fc.toLowerCase() + dn.substring(1);
    }
    return dn;
  }
}
