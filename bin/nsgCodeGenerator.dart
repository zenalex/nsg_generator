import 'dart:convert';
import 'dart:io';

import 'nsgGenerator.dart';

void main(List<String> args) async {
  var scPath = '';
  if (args.length == 1) {
    scPath = args[0];
  } else {
    print('Enter path: ');
    scPath =
        'X:\\Projects2\\flutter2\\scif_app_server_net\\scif_app_server\\model_config'; //stdin.readLineSync(encoding: utf8);
  }
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
