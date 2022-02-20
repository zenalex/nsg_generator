import 'dart:convert';
import 'dart:io';

import 'nsgGenerator.dart';

void main(List<String> args) async {
  var scPath = '';
  var doCSharp = false, doDart = false, forceOverwrite = false;
  if (args.isNotEmpty) {
    scPath = args[0];
    if (args.contains('-csharp')) {
      doCSharp = true;
    } else if (args.contains('-dart')) {
      doDart = true;
    } else {
      doCSharp = doDart = true;
    }
    if (args.contains('-force') ||
        args.contains('-overwrite') ||
        args.contains('-forceoverwrite')) {
      print('All files will be overwritten. Proceed? (y/n)');
      var yn = stdin.readLineSync(encoding: utf8);
      forceOverwrite = yn.toLowerCase() == 'y';
    }
  } else {
    print('Enter path: ');
    scPath = stdin.readLineSync(encoding: utf8);
    doCSharp = doDart = true;
  }
  startGenerator(scPath, doCSharp, doDart, forceOverwrite);
}

void startGenerator(String serviceConfigPath, bool doCSharp, bool doDart,
    bool forceOverwrite) async {
  var text = await readFile(serviceConfigPath);
  var generator = NsgGenerator.fromJson(json.decode(text));
  generator.doCSharp = doCSharp;
  generator.doDart = doDart;
  generator.forceOverwrite = forceOverwrite;
  print('controllers: ${generator.controllers.length}');
  await generator
      .writeCode(serviceConfigPath)
      .whenComplete(() => print('DONE\n'));
}

Future<String> readFile(String path) async {
  return await File('${path}/generation_config.json').readAsString();
}
