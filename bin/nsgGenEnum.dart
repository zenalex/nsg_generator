import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'misc.dart';
import 'nsgGenerator.dart';

class NsgGenEnum {
  final String className;
  final String dataTypeFile;
  final bool useLocalization;
  String description;
  List<NsgGenEnumItem>? values;

  NsgGenEnum(
      {required this.className,
      required this.dataTypeFile,
      required this.useLocalization,
      this.description = ''});

  factory NsgGenEnum.fromJson(Map<String, dynamic> parsedJson) {
    Misc.checkObsoleteKeysInJSON(
        'enum', parsedJson, {'class_name': 'className'});
    return NsgGenEnum(
        className: parsedJson['className'],
        dataTypeFile: parsedJson['dataTypeFile'] ?? '',
        useLocalization: Misc.parseBool(parsedJson['useLocalization']),
        description: parsedJson['description'] ?? '');
  }

  Future load(NsgGenerator nsgGenerator) async {
    //print('$class_name Enum initializing');
    var text =
        await File('${nsgGenerator.jsonPath}/$dataTypeFile').readAsString();
    var parsedEnumJson = json.decode(text);
    values = (parsedEnumJson['values'] as List)
        .map((i) => NsgGenEnumItem(
            codeName: i['codeName'],
            name: i['name'] ?? i['codeName'],
            value: i['value']))
        .toList();
    //print('$class_name Enum initialized');
  }

  Future generateCode(NsgGenerator nsgGenerator) async {
    var currentStage = 'C#';
    try {
      if (nsgGenerator.doCSharp) {
        var codeList = <String>[];
        codeList.add('using System;');
        codeList.add('using System.Collections.Generic;');
        codeList.add('using System.Linq;');
        codeList.add('using NsgServerClasses;');
        codeList.add('');
        codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
        codeList.add('{');
        if (description.isNotEmpty) {
          Misc.writeDescription(codeList, description, true);
        }
        codeList.add('public class $className : NsgServerEnum');
        codeList.add('{');
        assert(values != null);
        values!.forEach((i) {
          codeList.add(
              'public static $className ${i.codeName} { get; } = new $className(${i.value}, "${i.name}");');
        });
        codeList.add('');
        codeList.add(
            'private $className(int val, string name) : base(val, name) { }');
        codeList.add('');
        codeList.add('public static IEnumerable<$className> List()');
        codeList.add('{');
        codeList.add(
            'return new[] { ${values!.map((e) => e.codeName).join(', ')} };');
        codeList.add('}');
        codeList.add('');
        codeList.add('public static explicit operator $className(string name)');
        codeList.add('{');
        codeList.add('foreach ($className i in List())');
        codeList.add('{');
        codeList.add(
            'if (string.Equals(i.Name, name, StringComparison.OrdinalIgnoreCase))');
        codeList.add('    return i;');
        codeList.add('}');
        codeList.add('return null;');
        codeList.add('}');
        codeList.add('');
        codeList.add('public static explicit operator $className(int value)');
        codeList.add('{');
        codeList.add('foreach ($className i in List())');
        codeList.add('{');
        codeList.add('if (i.Value == value)');
        codeList.add('    return i;');
        codeList.add('}');
        codeList.add('return null;');
        codeList.add('}');
        codeList.add('}');
        codeList.add('}');
        Misc.indentCSharpCode(codeList);

        var fn = '${nsgGenerator.cSharpPath}/Enums/$className.cs';
        //if (!File(fn).existsSync()) {
        await File(fn).writeAsString(codeList.join('\r\n'));
        //}
      }
      if (nsgGenerator.doDart) {
        currentStage = 'Dart';
        await generateCodeDart(nsgGenerator);
      }
    } catch (e) {
      print('--- ERROR generating $currentStage enum $className ---');
      rethrow;
    }
  }

  Future generateCodeDart(NsgGenerator nsgGenerator) async {
    await generateEnumDart(nsgGenerator);
  }

  static Future generateEnums(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    if (enums.isEmpty) return;
    await Future.forEach<NsgGenEnum>(enums, (element) async {
      print('loading ${element.className}');
      await element.load(nsgGenerator);
    });
    await Future.forEach<NsgGenEnum>(enums, (element) async {
      print('generating ${element.className}');
      await element.generateCode(nsgGenerator);
    });
    if (nsgGenerator.doDart) {
      await generateExportFile(nsgGenerator, enums);
    }
  }

  static Future generateExportFile(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    var codeList = <String>[];
    enums.forEach((_) {
      codeList.add(
          "export 'enums/${Misc.getDartUnderscoreName(_.className)}.dart';");
    });

    await File('${nsgGenerator.dartPath}/enums.dart')
        .writeAsString(codeList.join('\r\n'));
  }

  Future generateEnumDart(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('import \'package:nsg_data/nsg_data.dart\';');
    if (useLocalization) {
      codeList.add(
          'import \'package:flutter_gen/gen_l10n/app_localizations.dart\';');
    }
    codeList.add('');
    if (description.isNotEmpty) {
      Misc.writeDescription(codeList, description, false);
    }
    codeList.add('class $className extends NsgEnum {');
    values!.forEach((i) {
      codeList.add(
          '  static $className ${Misc.getDartName(i.codeName)} = $className(${i.value}, \'${i.name}\');');
    });
    codeList.add('');
    codeList.add(
        '  $className(dynamic value, String name) : super(value: value, name: name);');
    codeList.add('');
    if (useLocalization) {
      codeList.add(
          '  static final Map<int, String Function(AppLocalizations)> names = {');
      var lowerCaseClassName = Misc.getDartName(className);
      values!.forEach((i) {
        var iCodeName = Misc.getDartName(i.codeName);
        codeList.add(
            '    $iCodeName.value: (AppLocalizations loc) => loc.${lowerCaseClassName}_$iCodeName,');
      });
      codeList.add('  };');
      codeList.add('');
    }
    codeList.add('  @override');
    codeList.add('  void initialize() {');
    codeList.add('    NsgEnum.listAllValues[runtimeType] = <int, $className>{');
    values!.forEach((v) {
      codeList.add('      ${v.value}: ${Misc.getDartName(v.codeName)},');
    });
    codeList.add('    };');
    codeList.add('  }');
    codeList.add('}');
    codeList.add('');
    await File(
            '${nsgGenerator.dartPath}/enums/${Misc.getDartUnderscoreName(className)}.dart')
        .writeAsString(codeList.join('\r\n'));
  }
}

class NsgGenEnumItem {
  final String codeName;
  final String name;
  final dynamic value;

  NsgGenEnumItem(
      {required this.codeName, required this.name, required this.value});
}
