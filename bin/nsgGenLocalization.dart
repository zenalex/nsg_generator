import 'dart:io';
import 'nsgGenerator.dart';
import 'misc.dart';

class NsgGenLocalization {
  static Future writeLocalization(NsgGenerator generator) async {
    var localizationDict = Map<String, String>();

    var l10n = Directory('${Directory(generator.dartPath).parent.path}/l10n');
    var arbFile = File('${l10n.path}/app_${generator.defaultLocale}.arb');
    var enums = generator.useLocalization
        ? generator.enums
        : generator.enums.where((en) => en.useLocalization);
    if (arbFile.existsSync()) {
      var str = arbFile.readAsStringSync();
      var regex = RegExp(r'"(\w+)"\s*:\s*"(((\\.)|[^"])*)"');

      final matches = regex.allMatches(str);

      matches.forEach((match) {
        final key = match.group(1);
        final value = match.group(2);
        if (key != null &&
            !localizationDict.containsKey(key) &&
            value != null) {
          localizationDict[key] = value;
        }
      });
    }

    enums.forEach((en) {
      en.values?.forEach((ev) {
        var key =
            '${Misc.getDartName(en.className)}_${Misc.getDartName(ev.codeName)}';
        // if (localizationDict.containsKey(key)) localizationDict.remove(key);
        localizationDict[key] = ev.name;
      });
    });

    var codeList = <String>[];
    codeList.add("{");
    var kvpList = <String>[];
    localizationDict.forEach((k, v) {
      kvpList.add("  \"$k\": \"$v\"");
    });
    codeList.add(kvpList.join(',\r\n'));
    codeList.add("}");

    if (localizationDict.isNotEmpty) {
      if (!l10n.existsSync()) {
        l10n.createSync();
      }

      await arbFile.writeAsString(codeList.join('\r\n'));
    }
  }
}
