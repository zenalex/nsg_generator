import 'dart:io';

import 'nsgGenCSProject.dart';
import 'nsgGenDataItemField.dart';
import 'nsgGenFunction.dart';
import 'nsgGenMethod.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenDataItem {
  final String typeName;
  final String description;
  final String databaseType;
  final String databaseTypeNamespace;
  final String presentation;
  final int maxHttpGetItems;
  final String periodFieldName;
  final List<NsgGenDataItemField> fields;
  final List<NsgGenFunction> methods;
  bool checkLastModifiedDate = false;
  bool allowCreate = false;

  NsgGenDataItem(
      {this.typeName,
      this.description,
      this.databaseType,
      this.databaseTypeNamespace,
      this.presentation,
      this.maxHttpGetItems,
      this.periodFieldName,
      this.fields,
      this.methods});

  factory NsgGenDataItem.fromJson(Map<String, dynamic> parsedJson) {
    var methods = parsedJson['methods'] as List ?? List.empty();
    return NsgGenDataItem(
        typeName: parsedJson['typeName'],
        description: parsedJson.containsKey('description')
            ? parsedJson['description']
            : parsedJson['databaseType'],
        databaseType: parsedJson['databaseType'],
        databaseTypeNamespace: parsedJson['databaseTypeNamespace'],
        presentation: parsedJson['presentation'],
        maxHttpGetItems: parsedJson['maxHttpGetItems'],
        periodFieldName: parsedJson['periodFieldName'],
        fields: (parsedJson['fields'] as List)
            .map((i) => NsgGenDataItemField.fromJson(i))
            .toList(),
        methods: methods.map((i) => NsgGenFunction.fromJson(i)).toList());
  }

  void writeCode(NsgGenerator nsgGenerator, NsgGenMethod nsgMethod) async {
    // ${typeName}.Designer.cs
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.ComponentModel.DataAnnotations;');
    codeList.add('using System.Linq;');
    codeList.add('using NsgServerClasses;');
    var namespaces = <String>[];

    if (databaseType != null && databaseType.isNotEmpty) {
      if (databaseTypeNamespace != null && databaseTypeNamespace.isNotEmpty) {
        namespaces.add(databaseTypeNamespace);
      }
    }
    var csTypes = <String, String>{};
    // var typedFields = fields.where((field) => field.type == 'Reference');
    // for (var i in typedFields) {
    //   if (!csTypes.containsKey(i.referenceType)) {
    //     csTypes[i.referenceType] = i.dbType;
    //   }
    // }
    var untypedFields =
        fields.where((field) => field.type == 'UntypedReference');
    for (var i in untypedFields) {
      for (var j in i.referenceTypes) {
        if (j.containsKey('namespace')) {
          var ns = j['namespace'].toString();
          if (ns.isNotEmpty && !namespaces.contains(ns)) {
            namespaces.add(ns);
          }
        }
        var alias = j['alias'].toString();
        var databaseType = j['databaseType'].toString();
        if (!csTypes.containsKey(alias)) {
          csTypes[alias] = databaseType;
        }
      }
    }
    if (namespaces.isNotEmpty) {
      codeList.add('using NsgSoft.DataObjects;');
      for (var i in namespaces) {
        codeList.add('using ' + i + ';');
      }
    }
    codeList.add('');

    if (databaseType != null && databaseType.isNotEmpty) {
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add(
          '// This file is autogenerated. Manual changes will be overwritten');
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      if (description != null && description.isNotEmpty) {
        codeList.add('/// <summary>');
        description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
        codeList.add('/// </summary>');
      }
      codeList.add('public partial class $typeName : NsgServerMetadataItem');
      codeList.add('{');

      //FromData
      codeList.add('public $typeName() : this(null, null) { }');
      codeList.add('');
      if (maxHttpGetItems == null) {
        codeList.add(
            'public $typeName(IEnumerable<string> serializeFields, $databaseType dataObject)');
        codeList.add('    : base(serializeFields, dataObject) { }');
      } else {
        codeList.add(
            'public $typeName(IEnumerable<string> serializeFields, $databaseType dataObject)');
        codeList.add('    : base(serializeFields, dataObject)');
        codeList.add('{');
        codeList.add('MaxHttpGetItems = $maxHttpGetItems;');
        codeList.add('}');
      }
      codeList.add('');
      if (presentation != null && presentation.isNotEmpty) {
        codeList.add('public override string ToString() => $presentation;');
        codeList.add('');
      } else if (fields != null && fields.isNotEmpty) {
        var nameField = fields.firstWhere((f) => f.name.toLowerCase() == 'name',
            orElse: () => null);
        if (nameField != null) {
          codeList
              .add('public override string ToString() => ${nameField.name};');
          codeList.add('');
        }
      }
      codeList.add('private $databaseType nsgObject = $databaseType.Новый();');
      codeList.add('');
      codeList.add('public override NsgMultipleObject NSGObject');
      codeList.add('{');
      codeList.add('get => nsgObject;');
      codeList.add('set');
      codeList.add('{');
      codeList.add('nsgObject = value as $databaseType;');
      codeList.add('if (value == null) return;');
      codeList.add('NsgToServerObject(nsgObject);');
      codeList.add('}');
      codeList.add('}');
      codeList.add('');

      var pkField = fields.firstWhere(
          (f) => f.name.toLowerCase().contains('id') && f.isPrimary);

      codeList.add(
          'public override Guid GetId() => NsgService.StringToGuid(${pkField.name});');
      codeList.add('');
      codeList.add(
          'public override void ServerToNsgObject(INsgTokenExtension user, NsgMultipleObject obj)');
      codeList.add('{');
      codeList.add('var nsgObject = obj as $databaseType;');
      fields.where((f) => f != pkField).forEach((el) {
        if (el.dbName == null ||
            el.dbName.isEmpty ||
            el.dbName.contains('.') ||
            el.name.toLowerCase().contains('ownerid')) {
          //Поле Владелец сериализовать не нужно для табличных частей
          //Для справочников, его сериализация может иметь смысл, но тогда нужно
          //Предусмотреть сериализацию неопределенных ссылок как таковых
          //codeList.add('${el.name} = default;');
        } else if (el.dartType == 'int') {
          codeList.add('nsgObject.${el.dbName} = (int)${el.name};');
        } else if (el.dartType == 'double') {
          codeList.add('nsgObject.${el.dbName} = (decimal)${el.name};');
        } else if (['String', 'string'].contains(el.dartType)) {
          if (el.dbType != null && el.dbType.isNotEmpty) {
            codeList.add(
                'nsgObject.${el.dbName}.Value = Guid.TryParse(${el.name}, out Guid ${el.name}Guid) ? ${el.name}Guid : Guid.Empty;');
          } else if (el.isPrimary) {
            codeList.add(
                'nsgObject.${el.dbName} = Guid.TryParse(${el.name}, out Guid ${el.name}Guid) ? ${el.name}Guid : Guid.Empty;');
          } else {
            codeList.add('nsgObject.${el.dbName} = ${el.name};');
          }
        } else if (el.dartType == 'Reference') {
          codeList.add(
              'nsgObject["${el.dbName}"].Value = Guid.TryParse(${el.name}, out Guid ${el.name}Guid) ? ${el.name}Guid : Guid.Empty;');
        } else if (el.dartType == 'UntypedReference') {
          codeList.add('var ${el.name}Splitted = ${el.name}.Split(\'.\');');
          codeList.add(
              'if (${el.name}Splitted.Length != 2) throw new Exception("$typeName, ${el.name} is not untyped reference id");');
          codeList.add(
              'nsgObject["${el.dbName}"].Value = (Guid.TryParse(${el.name}Splitted[0], out Guid ${el.name}Guid) ? ${el.name}Guid : Guid.Empty).ToString()');
          codeList.add(
              '    + "." + GetClientServerTypes()[${el.name}Splitted[1]];');
        } else if (el.dartType == 'Image') {
          codeList.add(
              'nsgObject.${el.dbName} = System.Drawing.Image.FromStream(new System.IO.MemoryStream(Convert.FromBase64String(${el.name})));');
        } else if (el.dartType == 'Enum') {
          codeList.add('nsgObject.${el.dbName}.Value = ${el.name};');
        } else if (el.dartType == 'List<Reference>') {
          codeList.add(
              'var ids${el.name} = ${el.name}.Select(i => i.GetId()).ToArray();');
          codeList.add('nsgObject.${el.dbName}.DeleteRows(new NsgCompare()');
          codeList.add(
              '    .Add(NsgSoft.Common.NsgDataFixedFields._ID, ids${el.name}, NsgSoft.Database.NsgComparison.NotIn));');
          codeList.add('foreach (var t in ${el.name})');
          codeList.add('{');
          codeList.add(
              'var row = nsgObject.${el.dbName}.FindRow(NsgSoft.Common.NsgDataFixedFields._ID, t.GetId())');
          codeList.add('    ?? nsgObject.${el.dbName}.NewRow();');
          codeList.add('t.ServerToNsgObject(user, row);');
          codeList.add('}');
        } else {
          codeList.add('nsgObject.${el.dbName} = ${el.name};');
        }
      });
      if (checkLastModifiedDate) {
        codeList.add('nsgObject["_lastModified"].Value = LastModified;');
      }
      //Вызывается в Post в базовом классе
      //codeList.add('OnServerToNsgObject(user, nsgObject);');
      codeList.add('}');
      codeList.add('');
      // codeList.add('public static Dictionary<Guid, $typeName> ItemCache =');
      // codeList.add('    new Dictionary<Guid, $typeName>();');
      // codeList.add('');
      codeList.add(
          'public override Dictionary<string, string> GetClientServerNames() => ClientServerNames;');
      codeList.add(
          'public static Dictionary<string, string> ClientServerNames = new Dictionary<string, string>');
      codeList.add('{');
      fields.forEach((field) {
        if (field.dbName != null && field.dbName.isNotEmpty) {
          codeList.add('["${field.dartName}"] = "${field.dbName}",');
        }
      });
      codeList.add('};');
      codeList.add('');

      if (csTypes.isNotEmpty) {
        codeList.add(
            'public override Dictionary<string, string> GetClientServerTypes() => ClientServerTypes;');
        codeList.add(
            'public static Dictionary<string, string> ClientServerTypes = new Dictionary<string, string>');
        codeList.add('{');
        for (var i in csTypes.entries) {
          codeList.add('["${i.key}"] = ${i.value}.Новый().TableName,');
        }
        codeList.add('};');
        codeList.add('');
      }

      var refs = fields.where((field) =>
          ['Reference' /*, 'UntypedReference'*/].contains(field.type));
      if (refs.isNotEmpty) {
        codeList.add(
            'public override Dictionary<string, string> GetReferenceNames() => ReferenceNames;');
        codeList.add(
            'public static Dictionary<string, string> ReferenceNames = new Dictionary<string, string>');
        codeList.add('{');
        refs.forEach((field) {
          codeList.add('["${field.dartName}"] = "${field.referenceName}",');
        });
        codeList.add('};');
        codeList.add('');
      }
      //ToData
    } else {
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add(
          '// This file is autogenerated. Manual changes will be overwritten');
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public partial class $typeName : NsgServerDataItem');
      codeList.add('{');
    }

    codeList.add('public override void SetDefaultValues()');
    codeList.add('{');
    fields.forEach((field) {
      if (field.type == 'int') {
        codeList.add('ValueDictionary["${field.dartName}"] = 0;');
      } else if (field.type == 'double') {
        codeList.add('ValueDictionary["${field.dartName}"] = 0D;');
      } else if (field.type == 'String') {
        if (field.isPrimary) {
          codeList.add(
              'ValueDictionary["${field.dartName}"] = "00000000-0000-0000-0000-000000000000";');
        } else {
          codeList.add('ValueDictionary["${field.dartName}"] = string.Empty;');
        }
      } else if (field.type == 'Guid') {
        codeList.add('ValueDictionary["${field.dartName}"] = Guid.Empty;');
      } else if (field.type == 'Reference') {
        codeList.add(
            'ValueDictionary["${field.dartName}"] = "00000000-0000-0000-0000-000000000000";');
        codeList.add(
            'ValueDictionary["${nsgGenerator.getDartName(field.referenceName)}"] = null;');
      } else if (field.type == 'UntypedReference') {
        codeList.add(
            'ValueDictionary["${field.dartName}"] = "00000000-0000-0000-0000-000000000000.NO";');
      } else if (field.type == 'List<Reference>') {
        codeList.add(
            'ValueDictionary["${field.dartName}"] = new List<${field.referenceType}>();');
      } else if (field.type == 'Enum') {
        codeList.add('ValueDictionary["${field.dartName}"] = 0;');
      } else if (field.type == 'Image') {
        codeList.add('ValueDictionary["${field.dartName}"] = string.Empty;');
      } else {
        codeList.add(
            'ValueDictionary["${field.dartName}"] = default(${field.dartType});');
      }
    });
    codeList.add('}');
    codeList.add('');

    codeList.add('#region Properties');
    fields.forEach((element) {
      if (element.description != null && element.description.isNotEmpty) {
        codeList.add('/// <summary>');
        element.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
        codeList.add('/// </summary>');
      }
      if (element.dartType == 'int') {
        codeList.add('public int ${element.name}');
        codeList.add('{');
        codeList.add('get => Convert.ToInt32(this["${element.dartName}"]);');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
      } else if (element.dartType == 'double') {
        codeList.add('public double ${element.name}');
        codeList.add('{');
        codeList.add('get => Convert.ToDouble(this["${element.dartName}"]);');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
      } else if (element.dartType == 'bool') {
        codeList.add('public bool ${element.name}');
        codeList.add('{');
        codeList.add('get => (bool)this["${element.dartName}"];');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
      } else if (element.dartType == 'DateTime') {
        codeList.add('public DateTime ${element.name}');
        codeList.add('{');
        codeList.add('get => (DateTime)this["${element.dartName}"];');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
      } else if (element.dartType == 'List<Reference>') {
        codeList.add('public List<${element.referenceType}> ${element.name}');
        codeList.add('{');
        codeList.add(
            'get => this["${element.dartName}"] as List<${element.referenceType}>;');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
        if (element.alwaysReturnNested) {
          codeList.add('public bool ShouldSerialize${element.name}()');
          codeList.add('{');
          codeList
              .add('return ${element.name} != null && ${element.name}.Any();');
          codeList.add('}');
        } else {
          codeList.add('public bool ShouldSerialize${element.name}()');
          codeList.add('{');
          codeList
              .add('return NestReferences() && (SerializeFields == null ||');
          codeList.add(
              '    SerializeFields.Find(s => s.StartsWith("${element.dartName}")) != default);');
          codeList.add('}');
        }
      } else if (element.dartType == 'List<Enum>') {
        codeList.add(
            'public IEnumerable<${element.referenceType}> ${element.name} { get; set; }');
        codeList.add('    = ${element.referenceType}.List();');
      } else if (element.dartType == 'Enum') {
        codeList.add('/// <remarks>');
        codeList.add('/// <see cref="${element.referenceType}"/> enum type');
        codeList.add('/// </remarks>');
        codeList.add('public int ${element.name}');
        codeList.add('{');
        codeList.add('get => (int)this["${element.dartName}"];');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
      } else if (element.dartType == 'Reference') {
        codeList.add('/// <remarks> ');
        codeList.add('/// <see cref="${element.referenceType}"/> reference');
        codeList.add('/// </remarks> ');
        codeList.add(
            '[System.ComponentModel.DefaultValue("00000000-0000-0000-0000-000000000000")]');
        codeList.add('public string ${element.name}');
        codeList.add('{');
        codeList.add('get => this["${element.dartName}"].ToString();');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
        codeList
            .add('public ${element.referenceType} ${element.referenceName}');
        codeList.add('{');
        codeList.add(
            'get => this["${nsgGenerator.getDartName(element.referenceName)}"] as ${element.referenceType};');
        codeList.add(
            'set => this["${nsgGenerator.getDartName(element.referenceName)}"] = value;');
        codeList.add('}');
        if (!element.alwaysReturnNested) {
          //   codeList.add('public bool ShouldSerialize${element.referenceName}()');
          //   codeList.add('{');
          //   codeList.add(
          //       'return ${element.referenceName} != null && ${element.referenceName}.GetId() != Guid.Empty;');
          //   codeList.add('}');
          // } else {
          codeList.add('public bool ShouldSerialize${element.referenceName}()');
          codeList.add('{');
          codeList
              .add('return NestReferences() && (SerializeFields == null ||');
          codeList.add(
              '    SerializeFields.Find(s => s.StartsWith("${element.dartName}")) != default);');
          codeList.add('}');
        }
      } else if (element.dartType == 'UntypedReference') {
        codeList.add('/// <remarks> ');
        codeList.add(
            '/// Untyped reference (${element.referenceTypes.map((e) => e['databaseType'].toString()).join(', ')})');
        codeList.add('/// </remarks> ');
        codeList.add(
            '[System.ComponentModel.DefaultValue("00000000-0000-0000-0000-000000000000.NO")]');
        codeList.add('public string ${element.name}');
        codeList.add('{');
        codeList.add('get => this["${element.dartName}"].ToString();');
        codeList.add('set => this["${element.dartName}"] = value;');
        codeList.add('}');
        // codeList.add(
        //     'public NsgServerMetadataItem ${element.referenceName} { get; set; }');
        // if (!element.alwaysReturnNested) {
        //   codeList.add('public bool ShouldSerialize${element.referenceName}()');
        //   codeList.add('{');
        //   codeList
        //       .add('return NestReferences() && (SerializeFields == null ||');
        //   codeList.add(
        //       '    SerializeFields.Find(s => s.StartsWith("${element.dartName}")) != default);');
        //   codeList.add('}');
        // }
      } else {
        if (element.type == 'Guid') {
          codeList.add('public Guid ${element.name}');
          codeList.add('{');
          codeList.add('get => (Guid)this["${element.dartName}"];');
          codeList.add('set => this["${element.dartName}"] = value;');
          codeList.add('}');
        } else {
          if (element.name.endsWith('Id')) {
            codeList.add(
                '[System.ComponentModel.DefaultValue("00000000-0000-0000-0000-000000000000")]');
          } else {
            if (element.maxLength > 0) {
              codeList.add('[StringLength(${element.maxLength})]');
            }
            codeList.add('[System.ComponentModel.DefaultValue("")]');
          }
          codeList.add('public string ${element.name}');
          codeList.add('{');
          codeList.add('get => this["${element.dartName}"].ToString();');
          codeList.add('set => this["${element.dartName}"] = value;');
          codeList.add('}');
        }
      }
      //if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });
    if (checkLastModifiedDate) {
      codeList.add('public DateTime LastModified { get; set; }');
      codeList.add('');
    }
    codeList.add('#endregion Properties');

    methods.forEach((element) {
      var paramTNString = '';
      var paramNString = '';
      if (element.params != null && element.params.isNotEmpty) {
        element.params.forEach((p) {
          paramTNString += p.returnType + ' ' + p.name + ', ';
          paramNString += p.name + ', ';
        });
      }
      if (paramTNString.isNotEmpty) {
        paramTNString = paramTNString.substring(0, paramTNString.length - 2);
        paramNString = paramNString.substring(0, paramNString.length - 2);
      }
      if (element.description != null && element.description.isNotEmpty) {
        codeList.add('/// <summary>');
        element.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
        codeList.add('/// </summary>');
      }
      if (element.dartType == null) {
        codeList.add(
            'public void ${element.name}($paramTNString) => On${element.name}($paramNString);');
      } else if (['int', 'double', 'bool', 'DateTime']
          .contains(element.dartType)) {
        codeList.add(
            'public ${element.dartType} ${element.name}($paramTNString) => On${element.name}($paramNString);');
      } else if (element.dartType == 'Duration') {
        codeList.add(
            'public TimeSpan ${element.name}($paramTNString) => On${element.name}($paramNString);');
      } else {
        codeList.add(
            'public string ${element.name}($paramTNString) => On${element.name}($paramNString);');
      }
      //if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });

    codeList.add('}');
    codeList.add('}');

    var fn = '${nsgGenerator.cSharpPath}/Models/$typeName.Designer.cs';
    //if (!File(fn).existsSync()) {
    NsgGenCSProject.indentCode(codeList);
    await File(fn).writeAsString(codeList.join('\r\n'));
    //}

    // ${typeName}.cs
    codeList.clear();
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('using NsgServerClasses;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public partial class $typeName');
    codeList.add('{');

    //methods.forEach((m) {
    // if (m.authorize != 'none') {
    if (nsgMethod.allowGetter) {
      codeList.add(
          'public override async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Get(INsgTokenExtension user, NsgFindParams findParams)');
      codeList.add('{');
      if (nsgMethod.genDataItem.databaseType != null &&
          nsgMethod.genDataItem.databaseType.isNotEmpty) {
        NsgGenController.generateImplMetadataGetMethodBody(
            nsgGenerator, codeList, nsgMethod);
      } else {
        codeList.add('throw new NotImplementedException();');
      }
      codeList.add('}');
      codeList.add('');
    }
    if (nsgMethod.allowCreate) {
      codeList.add(
          'public override async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Create(INsgTokenExtension user, NsgFindParams findParams)');
      codeList.add('{');
      if (nsgMethod.genDataItem.databaseType != null &&
          nsgMethod.genDataItem.databaseType.isNotEmpty) {
        codeList
            .add('var obj = ${nsgMethod.genDataItem.databaseType}.Новый();');
        codeList.add('obj.New();');
        codeList.add(
            'var res = new ${nsgMethod.genDataItem.typeName}(GetSerializeFields(findParams?.ReadNestedField), obj);');
        codeList
            .add('return GetDictWithNestedFields(new[] { res }, findParams);');
      } else {
        codeList.add('throw new NotImplementedException();');
      }
      codeList.add('}');
      codeList.add('');
    }
    if (nsgMethod.allowPost) {
      codeList.add(
          'public override async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Post(INsgTokenExtension user, IEnumerable<NsgServerDataItem> items)');
      codeList.add('{');
      if (nsgMethod.genDataItem.databaseType != null &&
          nsgMethod.genDataItem.databaseType.isNotEmpty) {
        codeList.add(
            'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
        codeList.add(
            'RES["results"] = NsgServerMetadataItem.PostAll<${nsgMethod.genDataItem.typeName}>(user, items);');
        codeList.add('return RES;');
      } else {
        codeList.add('throw new NotImplementedException();');
      }
      codeList.add('}');
      codeList.add('');
    }
    if (nsgMethod.allowDelete) {
      codeList.add(
          'public override async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Delete(INsgTokenExtension user, IEnumerable<NsgServerDataItem> items)');
      codeList.add('{');
      if (nsgMethod.genDataItem.databaseType != null &&
          nsgMethod.genDataItem.databaseType.isNotEmpty) {
        codeList.add(
            'NsgServerMetadataItem.SetDeleteMarkAll<${nsgMethod.genDataItem.typeName}>(items);');
        codeList.add(
            'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
        codeList.add('RES["results"] = items;');
        codeList.add('return RES;');
      } else {
        codeList.add('throw new NotImplementedException();');
      }
      codeList.add('}');
      codeList.add('');
    }
    // });
    methods.forEach((element) {
      var paramTNString = '';
      if (element.params != null && element.params.isNotEmpty) {
        element.params.forEach((p) {
          paramTNString += p.returnType + ' ' + p.name + ', ';
        });
      }
      if (paramTNString.isNotEmpty) {
        paramTNString = paramTNString.substring(0, paramTNString.length - 2);
      }
      if (element.description != null && element.description.isNotEmpty) {
        codeList.add('/// <summary>');
        element.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
        codeList.add('/// </summary>');
      }
      if (element.dartType == null) {
        codeList.add('public void On${element.name}($paramTNString) { }');
      } else if (['int', 'double', 'bool', 'DateTime']
          .contains(element.dartType)) {
        codeList.add(
            'public ${element.dartType} On${element.name}($paramTNString) => default;');
      } else if (element.dartType == 'Duration') {
        codeList.add(
            'public TimeSpan On${element.name}($paramTNString) => default;');
      } else {
        codeList.add(
            'public string On${element.name}($paramTNString) => string.Empty;');
      }
      //if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });
    codeList.add('}');
    codeList.add('}');
    fn = '${nsgGenerator.cSharpPath}/Models/$typeName.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      NsgGenCSProject.indentCode(codeList);
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  Future generateCodeDart(NsgGenerator nsgGenerator,
      NsgGenController nsgGenController, NsgGenMethod nsgGenMethod) async {
    //----------------------------------------------------------
    //generate service class for DataItem data_item.g.dart
    //----------------------------------------------------------
    print(
        'Generate controller = ${nsgGenController.className}, method = ${nsgGenMethod.name}');

    var codeList = <String>[];
    codeList.add(
        '//This is autogenerated file. All changes will be lost after code generation.');
    codeList.add("import 'package:nsg_data/nsg_data.dart';");

    codeList.add('// ignore: unused_import');
    codeList.add("import 'dart:typed_data';");
    codeList.add(
        "import '../${nsgGenerator.getDartUnderscoreName(nsgGenController.className)}_model.dart';");
    for (var field in fields) {
      if (!field.writeOnClient) continue;
      if (field.type == 'Enum') {
        if (nsgGenerator.enums.isNotEmpty) {
          codeList.add("import '../enums.dart';");
        }
        break;
      }
    }
    if (description != null && description.isNotEmpty) {
      codeList.add('');
      description.split('\n').forEach((descLine) {
        codeList.add('/// $descLine');
      });
    }
    codeList.add('class ${typeName}Generated extends NsgDataItem {');
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      codeList.add(
          " static const ${_.fieldNameVar} = '${nsgGenerator.getDartName(_.name)}';");
    });
    codeList.add('');
    codeList.add(' static final Map<String, String> fieldNameDict = {');
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.userVisibility) {
        codeList.add("   ${_.fieldNameVar}: '${_.userName}',");
      }
    });
    codeList.add(' };');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  void initialize() {');
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.isPrimary) {
        codeList.add(
            '   addField(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
      } else {
        if (_.type == 'String' &&
            _.maxLength != NsgGenDataItemField.defaultMaxLength[_.type]) {
          codeList.add(
              '   addField(${_.nsgDataType}(${_.fieldNameVar}, maxLength: ${_.maxLength}), primaryKey: ${_.isPrimary});');
        } else if (_.type == 'double' &&
            _.maxLength != NsgGenDataItemField.defaultMaxLength[_.type]) {
          codeList.add(
              '   addField(${_.nsgDataType}(${_.fieldNameVar}, maxDecimalPlaces: ${_.maxLength}), primaryKey: ${_.isPrimary});');
        } else {
          codeList.add(
              '   addField(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
        }
      }
    });
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.userVisibility) {
        codeList.add(
            "   fieldList.fields[${_.fieldNameVar}]?.presentation = '${_.userName}';");
      }
    });
    codeList.add('  }');
    codeList.add('');
    if (presentation != null && presentation.isNotEmpty) {
      codeList.add('  @override');
      codeList.add(
          '  String toString() => ${nsgGenerator.getDartName(presentation.replaceAll('\"', '\''))};');
      codeList.add('');
    } else if (fields != null && fields.isNotEmpty) {
      var nameField = fields.firstWhere((f) => f.name.toLowerCase() == 'name',
          orElse: () => null);
      if (nameField != null) {
        codeList.add('  @override');
        codeList.add(
            '  String toString() => ${nsgGenerator.getDartName(nameField.name)};');
        codeList.add('');
      }
    }
    if (allowCreate) {
      codeList.add('  @override');
      codeList.add('  bool get createOnServer => true;');
      codeList.add('');
    }
    codeList.add('  @override');
    codeList.add('  NsgDataItem getNewObject() => $typeName();');
    codeList.add('');

    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.description != null && _.description.isNotEmpty) {
        _.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
      }
      _.writeGetter(nsgGenController, codeList);
      _.writeSetter(nsgGenController, codeList);
    });
    codeList.add('');
    if (checkLastModifiedDate) {
      var lm = NsgGenDataItemField(name: 'LastModified', type: 'DateTime');
      lm.writeGetter(nsgGenController, codeList);
      lm.writeSetter(nsgGenController, codeList);
      codeList.add('');
    }
    if (periodFieldName != null && periodFieldName.isNotEmpty) {
      codeList.add('  @override');
      codeList.add('  String get periodFieldName => name$periodFieldName;');
      codeList.add('');
    }
    codeList.add('  @override');
    codeList.add('  String get apiRequestItems {');
    codeList.add(
        "    return '/${nsgGenController.apiPrefix}/${nsgGenMethod.apiPrefix}';");
    codeList.add('  }');

    codeList.add('}');

    await File(
            '${nsgGenerator.dartPathGen}/${nsgGenerator.getDartUnderscoreName(typeName)}.g.dart')
        .writeAsString(codeList.join('\r\n'));
    //----------------------------------------------------------
    //generate main item class data_item.dart
    //----------------------------------------------------------
    codeList = <String>[];
    codeList.add(
        "import '${nsgGenerator.genPathName}/${nsgGenerator.getDartUnderscoreName(typeName)}.g.dart';");
    codeList.add('');
    codeList.add('class $typeName extends ${typeName}Generated {');
    methods.forEach((_) {
      _.writeMethod(nsgGenController, codeList);
    });
    codeList.add('}');

    var fn =
        '${nsgGenerator.dartPath}/${nsgGenerator.getDartUnderscoreName(typeName)}.dart';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }
}
