import 'dart:io';
import 'dart:convert';
import 'misc.dart';
import 'nsgGenerator.dart';

class NsgGenLocalization {
  static Future writeLocalization(NsgGenerator generator) async {
    Map<String, Object?> localizationDict;

    var l10n = Directory('${Directory(generator.dartPath).parent.path}/l10n');
    var arbFile = File('${l10n.path}/app_${generator.defaultLocale}.arb');
    String? arbFileContent = null;
    if (arbFile.existsSync()) {
      arbFileContent = arbFile.readAsStringSync();
      localizationDict = jsonDecode(arbFileContent) as Map<String, Object?>;
    } else {
      localizationDict = Map<String, Object?>();
    }

    generator.localizationDict.forEach((key, value) {
      localizationDict[key] = value;
    });
    var encoder = JsonEncoder.withIndent('  ');
    var locJson = encoder.convert(localizationDict);
    if ((arbFileContent?.contains('\r\n') ?? false) ||
        Platform.lineTerminator != '\n') {
      locJson = locJson
          .replaceAll('\r', '')
          .replaceAll('\n', Platform.lineTerminator);
    }
    locJson += Platform.lineTerminator;

    if (localizationDict.isNotEmpty) {
      if (!l10n.existsSync()) {
        l10n.createSync();
      }

      await Misc.writeFileIfChanged(arbFile.path, locJson);
    }
  }
}
