import 'dart:io';

import 'nsgGenCSProject.dart';
import 'nsgGenDataItemField.dart';
import 'nsgGenDataItemMethod.dart';
import 'nsgGenMethod.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenDataItem {
  final String typeName;
  final String dbTypeName;
  final List<NsgGenDataItemField> fields;
  final List<NsgGenDataItemMethod> methods;

  NsgGenDataItem({this.typeName, this.dbTypeName, this.fields, this.methods});

  factory NsgGenDataItem.fromJson(Map<String, dynamic> parsedJson) {
    var methods = parsedJson['methods'] as List ?? List.empty();
    return NsgGenDataItem(
        typeName: parsedJson['typeName'],
        dbTypeName: parsedJson['databaseType'],
        fields: (parsedJson['fields'] as List)
            .map((i) => NsgGenDataItemField.fromJson(i))
            .toList(),
        methods: methods.map((i) => NsgGenDataItemMethod.fromJson(i)).toList());
  }

  void writeCode(NsgGenerator nsgGenerator, NsgGenMethod nsgMethod) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public class $typeName');
    codeList.add('{');

    if (dbTypeName != null && dbTypeName.isNotEmpty) {
      //FromData
      codeList.add('public $typeName() { }');
      codeList.add('');
      codeList.add('public $typeName($dbTypeName dataObject)');
      codeList.add('{');
      codeList.add('if (dataObject == null) return;');
      fields.forEach((el) {
        if (el.dartType == 'int') {
          codeList.add('${el.name} = (int)dataObject.${el.dbName};');
        } else if (el.dartType == 'double') {
          codeList.add('${el.name} = (double)dataObject.${el.dbName};');
        } else if (['String', 'string'].contains(el.dartType)) {
          codeList.add('${el.name} = dataObject.${el.dbName}.ToString();');
        } else if (el.dartType == 'Reference') {
          codeList.add(
              '${el.name} = new ${el.referenceType}(dataObject.${el.dbName} as ${el.dbType});');
        } else {
          codeList.add('${el.name} = dataObject.${el.dbName};');
        }
      });
      codeList.add('}');
      codeList.add('');
      //ToData
    }

    fields.forEach((element) {
      if (element.description != null && element.description.isNotEmpty) {
        codeList.add('/// <summary>');
        element.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
        codeList.add('/// </summary>');
      }
      if (element.dartType == 'int') {
        codeList.add('public int ${element.name} { get; set; }');
      } else if (element.dartType == 'double') {
        codeList.add('public double ${element.name} { get; set; }');
      } else if (element.dartType == 'bool') {
        codeList.add('public bool ${element.name} { get; set; }');
      } else if (element.dartType == 'DateTime') {
        codeList.add('public DateTime ${element.name} { get; set; }');
      } else if (element.dartType == 'Reference') {
        codeList.add(
            'public ${element.referenceType} ${element.name} { get; set; }');
      } else {
        codeList.add('public string ${element.name} { get; set; }');
      }
      if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });

    methods.forEach((element) {
      if (element.description != null && element.description.isNotEmpty) {
        codeList.add('/// <summary>');
        element.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
        codeList.add('/// </summary>');
      }
      if (element.dartType == null) {
        codeList.add('public void ${element.name}() { }');
      } else if (['int', 'double', 'bool', 'DateTime']
          .contains(element.dartType)) {
        codeList
            .add('public ${element.dartType} ${element.name}() => default;');
      } else if (element.dartType == 'Duration') {
        codeList.add('public TimeSpan ${element.name}() => default;');
      } else if (element.dartType == 'Reference') {
        codeList.add(
            'public ${element.referenceType} ${element.name}() => default;');
      } else {
        codeList.add('public string ${element.name}() => string.Empty;');
      }
      //if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });

    codeList.add('}');
    codeList.add('}');

    var fn = '${nsgGenerator.cSharpPath}/Models/${typeName}.cs';
    //if (!File(fn).existsSync()) {
    NsgGenCSProject.indentCode(codeList);
    await File(fn).writeAsString(codeList.join('\n'));
    //}
  }

  Future generateCodeDart(NsgGenerator nsgGenerator,
      NsgGenController nsgGenController, NsgGenMethod nsgGenMethod) async {
    //----------------------------------------------------------
    //generate service class for DataItem DataItem.g.dart
    //----------------------------------------------------------

    var codeList = <String>[];
    codeList.add(
        '//This is autogenerated file. All changes will be lost after code generation.');
    codeList.add("import 'package:nsg_data/nsg_data.dart';");
    codeList.add(
        "import '../${nsgGenerator.getDartName(nsgGenController.class_name)}Model.dart';");
    codeList.add('class ${typeName}Generated extends NsgDataItem {');
    fields.forEach((_) {
      codeList.add(
          " static const ${_.fieldNameVar} = '${nsgGenerator.getDartName(_.name)}';");
    });
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  void initialize() {');
    fields.forEach((_) {
      codeList.add(
          '   addfield(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
    });
    codeList.add('  }');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  NsgDataItem getNewObject() => ${typeName}();');
    codeList.add('');

    fields.forEach((_) {
      _.writeGetter(nsgGenController, codeList);
      _.writeSetter(nsgGenController, codeList);
    });
    methods.forEach((_) {
      _.writeMethod(nsgGenController, codeList);
    });
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  String get apiRequestItems {');
    codeList.add(
        "    return '/${nsgGenController.api_prefix}/${nsgGenMethod.apiPrefix}';");
    codeList.add('  }');

    codeList.add('}');

    await File('${nsgGenerator.dartPathGen}/${typeName}.g.dart')
        .writeAsString(codeList.join('\n'));
    //----------------------------------------------------------
    //generate main item class DataItem.dart
    //----------------------------------------------------------
    codeList = <String>[];
    codeList.add("import '${nsgGenerator.genPathName}/${typeName}.g.dart';");
    codeList.add('');
    codeList.add('class ${typeName} extends ${typeName}Generated {');
    codeList.add('}');

    var fn = '${nsgGenerator.dartPath}/${typeName}.dart';
    if (!File(fn).existsSync()) {
      await File(fn).writeAsString(codeList.join('\n'));
    }
  }
}
