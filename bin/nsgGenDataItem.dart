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

  static void generateDataObject(NsgGenerator nsgGenerator) async {
    var fn = '${nsgGenerator.cSharpPath}/Models/DataObject.cs';
    if (File(fn).existsSync()) return;
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('using Newtonsoft.Json;');
    codeList.add('using NsgSoft.DataObjects;');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public abstract class DataObject');
    codeList.add('{');
    codeList.add('public DataObject(NsgMultipleObject obj)');
    codeList.add('{');
    codeList.add('NSGObject = obj;');
    codeList.add('}');
    codeList.add('');
    codeList.add('[JsonIgnore]');
    codeList.add('public virtual NsgMultipleObject NSGObject { get; set; }');
    codeList.add('');
    codeList.add(
        'public static IEnumerable<T> FindAll<T>(NsgMultipleObject obj, NsgCompare cmp, NsgSorting sorting, int count = 0)');
    codeList.add('    where T : DataObject, new()');
    codeList.add('{');
    codeList.add('Func<NsgMultipleObject[]> findAll;');
    codeList.add('int _count = count;');
    codeList.add('var dataObj = obj;');
    codeList.add('if (_count == 0)');
    codeList.add('{');
    codeList.add('if (sorting == null) findAll = () => dataObj.FindAll(cmp);');
    codeList.add('else findAll = () => dataObj.FindAll(cmp, sorting);');
    codeList.add('}');
    codeList.add(
        'else findAll = () => dataObj.FindAll(ref _count, 0, sorting, cmp);');
    codeList.add('foreach (var i in findAll())');
    codeList.add('{');
    codeList.add('yield return new T { NSGObject = i };');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    await File(fn).writeAsString(codeList.join('\n'));
  }

  void writeCode(NsgGenerator nsgGenerator, NsgGenMethod nsgMethod) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    if (dbTypeName != null && dbTypeName.isNotEmpty) {
      await NsgGenDataItem.generateDataObject(nsgGenerator);
      codeList.add('using NsgSoft.DataObjects;');
      codeList.add('');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public class $typeName : DataObject');
      codeList.add('{');

      //FromData
      codeList.add('public $typeName() : this(null) { }');
      codeList.add('');
      codeList.add(
          'public $typeName($dbTypeName dataObject) : base(dataObject) { }');
      codeList.add('');
      codeList.add('private $dbTypeName nsgObject;');
      codeList.add('');
      codeList.add('public override NsgMultipleObject NSGObject');
      codeList.add('{');
      codeList.add('get => nsgObject;');
      codeList.add('set');
      codeList.add('{');
      codeList.add('nsgObject = value as $dbTypeName;');
      codeList.add('if (value == null) return;');
      fields.forEach((el) {
        if (el.dartType == 'int') {
          codeList.add('${el.name} = (int)nsgObject.${el.dbName};');
        } else if (el.dartType == 'double') {
          codeList.add('${el.name} = (double)nsgObject.${el.dbName};');
        } else if (['String', 'string'].contains(el.dartType)) {
          codeList.add('${el.name} = nsgObject.${el.dbName}.ToString();');
        } else if (el.dartType == 'Reference') {
          codeList
              .add('${el.name} = nsgObject.${el.dbName}?.Value.ToString();');
        } else {
          codeList.add('${el.name} = nsgObject.${el.dbName};');
        }
      });
      codeList.add('}');
      codeList.add('}');
      codeList.add('');
      //ToData
    } else {
      codeList.add('');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public class $typeName');
      codeList.add('{');
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
    //generate service class for DataItem dataItem.g.dart
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

    await File(
            '${nsgGenerator.dartPathGen}/${nsgGenerator.getDartName(typeName)}.g.dart')
        .writeAsString(codeList.join('\n'));
    //----------------------------------------------------------
    //generate main item class DataItem.dart
    //----------------------------------------------------------
    codeList = <String>[];
    codeList.add(
        "import '${nsgGenerator.genPathName}/${nsgGenerator.getDartName(typeName)}.g.dart';");
    codeList.add('');
    codeList.add('class ${typeName} extends ${typeName}Generated {');
    codeList.add('}');

    var fn =
        '${nsgGenerator.dartPath}/${nsgGenerator.getDartName(typeName)}.dart';
    if (!File(fn).existsSync()) {
      await File(fn).writeAsString(codeList.join('\n'));
    }
  }
}
