import 'dart:convert';
import 'dart:io';

import 'misc.dart';
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
      if (args.contains('-dontAsk')) {
        nsgArgs.forceOverwrite = true;
      } else {
        print('Overwrite all files? (y/n/cancel)');
        var yn = stdin.readLineSync(encoding: utf8)?.toLowerCase() ?? 'n';
        if (yn != 'y' && yn != 'n') return;
        nsgArgs.forceOverwrite = yn == 'y';
      }
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
    nsgArgs.serviceConfigPath =
        stdin.readLineSync(encoding: utf8) ?? nsgArgs.serviceConfigPath;
  }
  startGenerator(nsgArgs);
}

Future startGenerator(NsgGeneratorArgs args) async {
  Directory.current = args.serviceConfigPath;
  NsgGenerator generator;
  try {
    var text = await readFile(args.serviceConfigPath);
    generator = NsgGenerator.fromJson(json.decode(text));
  } catch (e) {
    print('--- ERROR parsing generator_config.json ---');
    rethrow;
  }
  generator.doCSharp &= args.doCSharp;
  generator.doDart &= args.doDart;
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
  print('STARTING ${DateTime.now()}');
  print('controllers: ${generator.controllers.length}');
  try {
    await generator.writeCode(args.serviceConfigPath);
  } finally {
    if (Misc.warnings.length > 0) print(Misc.warnings.join('\n'));
    print('FINISHED ${DateTime.now()}\n');
  }
}

Future<String> readFile(String path) async {
  return await File('$path/generation_config.json').readAsString();
}
