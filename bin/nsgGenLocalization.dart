import 'dart:io';
import 'dart:convert';
import 'misc.dart';
import 'nsgGenerator.dart';

class NsgGenLocalization {
  static Future writeLocalization(NsgGenerator generator) async {
    Map<String, Object?> localizationDict;

    var l10n = Directory('${Directory(generator.dartPath).parent.path}/l10n');
    var arbFile = File('${l10n.path}/app_${generator.defaultLocale}.arb');
    if (arbFile.existsSync()) {
      var str = arbFile.readAsStringSync();
      localizationDict = jsonDecode(str) as Map<String, Object?>;
    } else {
      localizationDict = Map<String, Object?>();
    }

    generator.localizationDict.forEach((key, value) {
      localizationDict[key] = value;
    });

    var locJson = jsonEncode(localizationDict);

    if (localizationDict.isNotEmpty) {
      if (!l10n.existsSync()) {
        l10n.createSync();
      }

      await Misc.writeFileIfChanged(arbFile.path, locJson);
    }
  }
}
