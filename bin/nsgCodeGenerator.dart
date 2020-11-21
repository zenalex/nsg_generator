import 'dart:convert';
import 'dart:io';

import 'nsgGenerator.dart';

void main() async {
  startGenerator();
}

void startGenerator() async {
  var path = 'bin/serviceConfig/';
  var text = await readFile(path);
  var generator = NsgGenerator.fromJson(json.decode(text));
  print('controllers: ${generator.controllers.length}');
  generator.writeCode(path);
}

Future<String> readFile(String path) async {
  return await File('${path}/generation_config.json').readAsString();
}
