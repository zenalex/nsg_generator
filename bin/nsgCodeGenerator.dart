import 'dart:convert';
import 'dart:io';

import 'nsgGenerator.dart';

void main() async {
  print('Enter path: ');
  var scPath = stdin.readLineSync(encoding: utf8);
  //'C:/Users/pro5/source/repos/scif_wms/lib/serviceConfig';
  //'bin/serviceConfig/'

  startGenerator(scPath);
}

void startGenerator(String serviceConfigPath) async {
  var text = await readFile(serviceConfigPath);
  var generator = NsgGenerator.fromJson(json.decode(text));
  print('controllers: ${generator.controllers.length}');
  await generator
      .writeCode(serviceConfigPath)
      .whenComplete(() => print('DONE\n'));
}

Future<String> readFile(String path) async {
  return await File('${path}/generation_config.json').readAsString();
}
