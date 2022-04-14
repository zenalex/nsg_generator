import 'dart:convert';
import 'dart:io';

import 'nsgGenerator.dart';

void main(List<String> args) async {
  var scPath = '', cSharpPath = '', dartPath = '';
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
      print('Overwrite all files? (y/n/cancel)');
      var yn = stdin.readLineSync(encoding: utf8).toLowerCase();
      if (yn != 'y' && yn != 'n') return;
      forceOverwrite = yn == 'y';
    }
    for (var i in args) {
      if (i.startsWith('csharp:')) {
        cSharpPath = i.substring(i.indexOf(':') + 1).trim();
      }
      if (i.startsWith('dart:')) {
        dartPath = i.substring(i.indexOf(':') + 1).trim();
      }
    }
  } else {
    print('Enter path: ');
    scPath = stdin.readLineSync(encoding: utf8);
    doCSharp = doDart = true;
  }
  startGenerator(scPath, doCSharp, doDart, forceOverwrite,
      cSharpPath: cSharpPath, dartPath: dartPath);
}

void startGenerator(
    String serviceConfigPath, bool doCSharp, bool doDart, bool forceOverwrite,
    {String cSharpPath = '', String dartPath = ''}) async {
  var text = await readFile(serviceConfigPath);
  var generator = NsgGenerator.fromJson(json.decode(text));
  generator.doCSharp = doCSharp;
  generator.doDart = doDart;
  generator.forceOverwrite = forceOverwrite;
  if (cSharpPath.isNotEmpty) {
    generator.cSharpPath = cSharpPath;
  }
  if (dartPath.isNotEmpty) {
    generator.dartPath = dartPath;
  }
  print('controllers: ${generator.controllers.length}');
  await generator
      .writeCode(serviceConfigPath)
      .whenComplete(() => print('DONE\n'));
}

Future<String> readFile(String path) async {
  return await File('$path/generation_config.json').readAsString();
}
