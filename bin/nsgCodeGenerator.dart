import 'dart:convert';
import 'dart:io';

import 'nsgGeneratorArgs.dart';
import 'nsgGenerator.dart';

void main(List<String> args) async {
  var nsgArgs = NsgGeneratorArgs();
  if (args.isNotEmpty) {
    nsgArgs.serviceConfigPath = args[0];
    var doCSharp = args.contains('-csharp');
    var doDart = args.contains('-dart');
    if (doCSharp != doDart) {
      nsgArgs.doCSharp = doCSharp;
      nsgArgs.doDart = doDart;
    }
    if (args.contains('-force') ||
        args.contains('-overwrite') ||
        args.contains('-forceoverwrite')) {
      print('Overwrite all files? (y/n/cancel)');
      var yn = stdin.readLineSync(encoding: utf8).toLowerCase();
      if (yn != 'y' && yn != 'n') return;
      nsgArgs.forceOverwrite = yn == 'y';
    }
    nsgArgs.copyCsproj = args.contains('-copyCsproj');
    nsgArgs.copyProgramCs = args.contains('-copyProgramCs');
    nsgArgs.copyStartupCs = args.contains('-copyStartupCs');
    for (var i in args) {
      if (i.startsWith('csharp:')) {
        nsgArgs.cSharpPath = i.substring(i.indexOf(':') + 1).trim();
      }
      if (i.startsWith('dart:')) {
        nsgArgs.dartPath = i.substring(i.indexOf(':') + 1).trim();
      }
    }
  } else {
    print('Enter path: ');
    nsgArgs.serviceConfigPath = stdin.readLineSync(encoding: utf8);
  }
  startGenerator(nsgArgs);
}

void startGenerator(NsgGeneratorArgs args) async {
  var text = await readFile(args.serviceConfigPath);
  var generator = NsgGenerator.fromJson(json.decode(text));
  generator.doCSharp = args.doCSharp;
  generator.doDart = args.doDart;
  generator.forceOverwrite = args.forceOverwrite;
  generator.copyCsproj = args.copyCsproj;
  generator.copyProgramCs = args.copyProgramCs;
  generator.copyStartupCs = args.copyStartupCs;
  if (args.cSharpPath.isNotEmpty) {
    generator.cSharpPath = args.cSharpPath;
  }
  if (args.dartPath.isNotEmpty) {
    generator.dartPath = args.dartPath;
  }
  print('controllers: ${generator.controllers.length}');
  await generator
      .writeCode(args.serviceConfigPath)
      .whenComplete(() => print('DONE\n'));
}

Future<String> readFile(String path) async {
  return await File('$path/generation_config.json').readAsString();
}
