import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'nsgGenCSProject.dart';
import 'nsgGenerator.dart';

class NsgGenEnum {
  final String class_name;
  final String dataTypeFile;
  String description;
  List<NsgGenEnumItem> values;

  NsgGenEnum({this.class_name, this.dataTypeFile, this.description = ''});

  factory NsgGenEnum.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenEnum(
        class_name: parsedJson['class_name'],
        dataTypeFile: parsedJson['dataTypeFile'],
        description: parsedJson['description']);
  }

  Future load(NsgGenerator nsgGenerator) async {
    print('$class_name Enum initializing');
    var text =
        await File('${nsgGenerator.jsonPath}/${dataTypeFile}').readAsString();
    var parsedEnumJson = json.decode(text);
    values = (parsedEnumJson['values'] as List)
        .map((i) => NsgGenEnumItem(
            codeName: i['codeName'], name: i['name'], value: i['value']))
        .toList();
    print('$class_name Enum initialized');
  }

  void generateCode(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using NsgServerClasses;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    if (description != null && description.isNotEmpty) {
      codeList.add('/// <summary>');
      codeList.add('/// ${description}');
      codeList.add('/// </summary>');
    }
    codeList.add('public class ${class_name} : NsgServerEnum');
    codeList.add('{');
    values.forEach((i) {
      codeList.add(
          'public static ${class_name} ${i.codeName} { get; } = new ${class_name}(${i.value}, "${i.name}");');
    });
    codeList.add('');
    codeList.add(
        'private ${class_name}(int val, string name) : base(val, name) { }');
    codeList.add('');
    codeList.add('public static IEnumerable<${class_name}> List()');
    codeList.add('{');
    codeList
        .add('return new[] { ${values.map((e) => e.codeName).join(', ')} };');
    codeList.add('}');
    codeList.add('');
    codeList.add('public static explicit operator ${class_name}(string name)');
    codeList.add('{');
    codeList.add('foreach (${class_name} i in List())');
    codeList.add('{');
    codeList.add(
        'if (string.Equals(i.Name, name, StringComparison.OrdinalIgnoreCase))');
    codeList.add('    return i;');
    codeList.add('}');
    codeList.add('return null;');
    codeList.add('}');
    codeList.add('');
    codeList.add('public static explicit operator ${class_name}(int value)');
    codeList.add('{');
    codeList.add('foreach (${class_name} i in List())');
    codeList.add('{');
    codeList.add('if (i.Value == value)');
    codeList.add('    return i;');
    codeList.add('}');
    codeList.add('return null;');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);

    var fn = '${nsgGenerator.cSharpPath}/Enums/${class_name}.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\n'));
    //}
    await generateCodeDart(nsgGenerator);
  }

  void generateCodeDart(NsgGenerator nsgGenerator) async {
    await generateEnumDart(nsgGenerator);
  }

  static Future generateEnums(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    if (enums == null || enums.isEmpty) return;
    await Future.forEach<NsgGenEnum>(enums, (element) async {
      print('loading ${element.class_name}');
      await element.load(nsgGenerator);
    });
    await Future.forEach<NsgGenEnum>(enums, (element) async {
      print('generating ${element.class_name}');
      await element.generateCode(nsgGenerator);
    });
    await generateExportFile(nsgGenerator, enums);
  }

  static Future generateExportFile(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    var codeList = <String>[];
    enums.forEach((_) {
      codeList.add(
          "export 'enums/${nsgGenerator.getDartName(_.class_name)}.dart';");
    });

    await File('${nsgGenerator.dartPath}/enums.dart')
        .writeAsString(codeList.join('\n'));
  }

  Future generateEnumDart(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('import \'package:nsg_data/nsg_data.dart\';');
    codeList.add('class $class_name extends NsgEnum {');
    values.forEach((i) {
      codeList.add(
          '  static $class_name ${i.codeName} = $class_name(${i.value}, \'${i.name}\');');
    });
    codeList.add('');
    codeList.add(
        '  $class_name(dynamic value, String name) : super(value: value, name: name);');
    codeList.add('');
    codeList.add('  static List<$class_name> ListAll() {');
    codeList.add('    return List<$class_name>.from(');
    codeList.add('        {${values.map((e) => e.codeName).join(', ')}},');
    codeList.add('        growable: false);');
    codeList.add('  }');
    codeList.add('');
    codeList.add('  static $class_name FromValue(dynamic v) {');
    codeList.add('    return ListAll()');
    codeList.add('        .firstWhere((element) => element.value == v);');
    codeList.add('  }');
    codeList.add('');
    codeList.add('  static $class_name FromString(String v) {');
    codeList.add('    return ListAll()');
    codeList.add('        .firstWhere((element) => element.name == v);');
    codeList.add('  }');
    codeList.add('}');
    await File(
            '${nsgGenerator.dartPath}/enums/${nsgGenerator.getDartName(class_name)}.dart')
        .writeAsString(codeList.join('\n'));
  }
}

class NsgGenEnumItem {
  final String codeName;
  final String name;
  final dynamic value;

  NsgGenEnumItem({this.codeName, this.name, this.value});
}
