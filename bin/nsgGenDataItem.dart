import 'dart:io';

import 'misc.dart';
import 'nsgGenDataItemField.dart';
import 'nsgGenMethod.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenDataItem {
  final String typeName;
  final NsgGenDataItemEntityType entityType;
  final String description;
  final String databaseType;
  final String databaseTypeNamespace;
  final String presentation;
  final int maxHttpGetItems;
  final String periodFieldName;
  final String lastEditedFieldName;
  final bool useStaticDatabaseNames;
  final List<NsgGenDataItemField> fields;
  bool checkLastModifiedDate = false;
  bool allowCreate = false;
  bool isTableRow = false;
  String databaseTypeTable = '';

  NsgGenDataItem(
      {required this.typeName,
      this.entityType = NsgGenDataItemEntityType.dataItem,
      this.description = '',
      this.databaseType = '',
      this.databaseTypeNamespace = '',
      this.presentation = '',
      this.maxHttpGetItems = 100,
      this.periodFieldName = '',
      this.lastEditedFieldName = '',
      this.useStaticDatabaseNames = false,
      this.isTableRow = false,
      this.fields = const []}) {
    this.isTableRow |= this.databaseType.endsWith('.Строка');
    this.databaseTypeTable = this.databaseType;
    if (this.isTableRow)
      this.databaseTypeTable = Misc.cutTableRowTypeNameEnding(databaseType);
  }

  factory NsgGenDataItem.fromJson(Map<String, dynamic> parsedJson) {
    var tn = parsedJson['typeName'] ?? '';
    return NsgGenDataItem(
        typeName: tn,
        description: parsedJson.containsKey('description')
            ? parsedJson['description'] ?? ''
            : parsedJson['databaseType'] ?? '',
        databaseType: parsedJson['databaseType'] ?? '',
        databaseTypeNamespace: parsedJson['databaseTypeNamespace'] ?? '',
        presentation: parsedJson['presentation'] ?? '',
        maxHttpGetItems: parsedJson['maxHttpGetItems'] ?? 100,
        periodFieldName: parsedJson['periodFieldName'] ?? '',
        lastEditedFieldName: parsedJson['lastEditedFieldName'] ?? '',
        useStaticDatabaseNames: parsedJson['useStaticDatabaseNames'] == 'true',
        isTableRow: parsedJson['isTableRow'] == 'true',
        entityType:
            NsgGenDataItemEntityType.parse(parsedJson['entityType'] ?? '', tn),
        fields: (parsedJson['fields'] as List)
            .map((i) => NsgGenDataItemField.fromJson(i))
            .toList());
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

    if (databaseType.isNotEmpty) {
      if (databaseTypeNamespace.isNotEmpty) {
        namespaces.add(databaseTypeNamespace);
      }
    }
    var csTypes = <String, String>{};
    // var typedFields = fields.where((field) => field.isReference);
    // for (var i in typedFields) {
    //   if (!csTypes.containsKey(i.referenceType)) {
    //     csTypes[i.referenceType] = i.dbType;
    //   }
    // }
    var untypedFields = fields.where(
        (field) => field.writeOnServer && field.type == 'UntypedReference');
    for (var i in untypedFields) {
      assert(i.referenceTypes != null);
      for (var j in i.referenceTypes!) {
        if (j.containsKey('namespace')) {
          var ns = j['namespace'].toString();
          if (ns.isNotEmpty && !namespaces.contains(ns)) {
            namespaces.add(ns);
          }
        }
        var alias = j['alias'].toString();
        var databaseType = j['databaseType'].toString();
        if (!csTypes.containsKey(alias)) {
          csTypes[alias] = Misc.cutTableRowTypeNameEnding(databaseType);
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

    if (databaseType.isNotEmpty) {
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add(
          '// This file is autogenerated. Manual changes will be overwritten');
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      if (description.isNotEmpty) {
        Misc.writeDescription(codeList, description, true);
      }
      if (entityType == NsgGenDataItemEntityType.userSettings) {
        codeList.add('public partial class $typeName : NsgServerUserSettings');
      } else {
        codeList.add('public partial class $typeName : NsgServerMetadataItem');
      }
      codeList.add('{');

      codeList.add('public $typeName() : this(null, null) { }');
      codeList.add('');

      codeList.add(
          'public $typeName(IEnumerable<string> serializeFields, $databaseType dataObject)');
      codeList.add('    : base(serializeFields, dataObject)');
      codeList.add('{');
      codeList.add('MaxHttpGetItems = $maxHttpGetItems;');
      codeList.add('}');

      codeList.add('');
      if (presentation.isNotEmpty) {
        if (presentation.contains(Misc.csToStringRE))
          codeList
              .add('public override string ToString() => \$"$presentation";');
        else
          codeList.add('public override string ToString() => $presentation;');
        codeList.add('');
      } else if (fields.any((f) => f.writeOnServer)) {
        var nameField = fields.firstWhere(
            (f) => f.writeOnServer && f.name.toLowerCase() == 'name',
            orElse: () => NsgGenDataItemField(name: '', type: ''));
        if (nameField.name.isNotEmpty) {
          codeList
              .add('public override string ToString() => ${nameField.name};');
          codeList.add('');
        }
      }
      if (isTableRow)
        codeList.add(
            'private $databaseType nsgObject = $databaseTypeTable.Новый().NewRow();');
      else
        codeList
            .add('private $databaseType nsgObject = $databaseType.Новый();');
      codeList.add('');
      codeList.add('public override NsgMultipleObject NSGObject');
      codeList.add('{');
      codeList.add('get => nsgObject;');
      codeList.add('set');
      codeList.add('{');
      codeList.add('nsgObject = value as $databaseType;');
      codeList.add('if (nsgObject == null)');
      codeList.add('{');
      if (isTableRow)
        codeList.add('nsgObject = $databaseTypeTable.Новый().NewRow();');
      else
        codeList.add('nsgObject = $databaseType.Новый();');
      codeList.add('nsgObject.CopyFieldsFromObject(value);');
      codeList.add('}');
      codeList.add('if (value == null) return;');
      codeList.add('NsgToServerObject(nsgObject);');
      codeList.add('}');
      codeList.add('}');
      codeList.add('');
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
    //print(typeName);
    var pkField = fields.firstWhere(
        (f) =>
            f.writeOnServer &&
            (f.name.toLowerCase().contains('id') || f.isPrimary), orElse: () {
      throw Exception('There is no Primary key in $typeName');
    });

    if (entityType != NsgGenDataItemEntityType.userSettings) {
      codeList.add(
          'public override Guid GetId() => NsgSoft.Common.NsgService.StringToGuid(${pkField.name});');
      codeList.add(
          'public override void SetId(object value) => ${pkField.name} = value.ToString();');
      codeList.add('');
    }
    if (lastEditedFieldName.isNotEmpty) {
      codeList.add(
          'public override string LastEditedFieldName => Names.${lastEditedFieldName};');
      codeList.add('');
    }
    codeList.add(
        'public override Dictionary<string, string> GetClientServerNames() => ClientServerNames;');
    codeList.add(
        'public static Dictionary<string, string> ClientServerNames = new Dictionary<string, string>');
    codeList.add('{');
    fields.forEach((field) {
      if (field.writeOnServer && field.dbName.isNotEmpty) {
        if (databaseType.isEmpty ||
            field.dbName.contains('.') ||
            !nsgGenerator.useStaticDatabaseNames && !useStaticDatabaseNames) {
          codeList.add('[Names.${field.name}] = "${field.dbName}",');
        } else {
          codeList.add(
              '[Names.${field.name}] = ${databaseType}.Names.${field.dbName},');
        }
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
        field.writeOnServer &&
        field.isReference &&
        !field.type.startsWith('List'));
    if (refs.isNotEmpty) {
      codeList.add(
          'public override Dictionary<string, string> GetReferenceNames() => ReferenceNames;');
      codeList.add(
          'public static Dictionary<string, string> ReferenceNames = new Dictionary<string, string>');
      codeList.add('{');
      refs.forEach((field) {
        codeList.add('[Names.${field.name}] = "${field.referenceName}",');
      });
      codeList.add('};');
      codeList.add('');
    }
    var fieldsNotToPost = fields.where((f) => f.writeOnServer && !f.allowPost);
    if (fieldsNotToPost.isNotEmpty) {
      codeList.add(
          'public override IEnumerable<string> GetFieldsNotToPost() => FieldsNotToPost;');
      codeList.add('public static IEnumerable<string> FieldsNotToPost = new[]');
      codeList.add('{');
      fieldsNotToPost.forEach((field) {
        codeList.add('Names.${field.name},');
      });
      codeList.add('};');
      codeList.add('');
    }
    codeList.add('public override void SetDefaultValues()');
    codeList.add('{');
    if (entityType == NsgGenDataItemEntityType.userSettings)
      codeList.add('base.SetDefaultValues();');
    fields.forEach((field) {
      if (!field.writeOnServer) return;
      if (entityType == NsgGenDataItemEntityType.userSettings &&
          [pkField.name, 'Settings', 'UserId'].contains(field.name)) return;
      if (field.type == 'int') {
        codeList.add('ValueDictionary[Names.${field.name}] = 0;');
      } else if (field.type == 'double') {
        codeList.add('ValueDictionary[Names.${field.name}] = 0D;');
      } else if (field.type == 'String') {
        if (field.isPrimary) {
          codeList.add(
              'ValueDictionary[Names.${field.name}] = "00000000-0000-0000-0000-000000000000";');
        } else {
          codeList.add('ValueDictionary[Names.${field.name}] = string.Empty;');
        }
      } else if (field.type == 'Guid') {
        codeList.add('ValueDictionary[Names.${field.name}] = Guid.Empty;');
      } else if (field.type == 'UntypedReference') {
        codeList.add(
            'ValueDictionary[Names.${field.name}] = "00000000-0000-0000-0000-000000000000.NO";');
      } else if (field.type.startsWith('List')) {
        codeList.add(
            'ValueDictionary[Names.${field.name}] = new List<${field.referenceType}>();');
      } else if (field.isReference) {
        codeList.add(
            'ValueDictionary[Names.${field.name}] = "00000000-0000-0000-0000-000000000000";');
        codeList.add('ValueDictionary[Names.${field.referenceName}] = null;');
      } else if (field.type.startsWith('Enum')) {
        codeList.add('ValueDictionary[Names.${field.name}] = 0;');
      } else if (['Image', 'Binary'].contains(field.type)) {
        codeList.add('ValueDictionary[Names.${field.name}] = string.Empty;');
      } else {
        codeList.add(
            'ValueDictionary[Names.${field.name}] = default(${field.type});');
      }
    });
    codeList.add('}');
    codeList.add('');

    codeList.add('#region Names');
    if (entityType == NsgGenDataItemEntityType.userSettings) {
      codeList.add('public override string Names_Id => Names.${pkField.name};');
      codeList.add('');
      var usField = fields.firstWhere((f) => f.name == 'Settings',
          orElse: () => NsgGenDataItemField(name: 'null', type: 'null'));
      if (usField.name == 'null') {
        var errorMessage =
            'UserSettings - the required field "Settings" couldn\'t be found';
        print(errorMessage);
        throw Exception(errorMessage);
      }
      codeList.add(
          'public override string Names_Settings => Names.${usField.name};');
      codeList.add('');
      usField = fields.firstWhere((f) => f.name == 'UserId',
          orElse: () => NsgGenDataItemField(name: 'null', type: 'null'));
      if (usField.name == 'null') {
        var errorMessage =
            'UserSettings - the required field "UserId" couldn\'t be found';
        print(errorMessage);
        throw Exception(errorMessage);
      }
      codeList
          .add('public override string Names_UserId => Names.${usField.name};');
      codeList.add('');
    }
    codeList.add('public static class Names');
    codeList.add('{');
    fields.forEach((field) {
      if (!field.writeOnServer) return;
      if (field.description.isNotEmpty) {
        Misc.writeDescription(codeList, field.description, true);
      }
      codeList.add(
          'public static readonly string ${field.name} = "${field.dartName}";');
      if (field.referenceName.isNotEmpty) {
        codeList.add('');
        if (field.description.isNotEmpty) {
          Misc.writeDescription(
              codeList, field.description + ' - reference', true);
        }
        codeList.add(
            'public static readonly string ${field.referenceName} = "${Misc.getDartName(field.referenceName)}";');
      }
      codeList.add('');
    });
    codeList.add('}');
    codeList.add('');
    codeList.add('#endregion Names');

    codeList.add('#region Properties');
    fields.forEach((field) {
      if (!field.writeOnServer) return;
      if (entityType == NsgGenDataItemEntityType.userSettings &&
          [pkField.name, 'Settings', 'UserId'].contains(field.name)) return;
      if (field.description.isNotEmpty) {
        Misc.writeDescription(codeList, field.description, true);
      }
      if (field.type == 'int') {
        codeList.add('public int ${field.name}');
        codeList.add('{');
        codeList.add('get => Convert.ToInt32(this[Names.${field.name}]);');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else if (field.type == 'double') {
        codeList.add('public double ${field.name}');
        codeList.add('{');
        codeList.add('get => Convert.ToDouble(this[Names.${field.name}]);');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else if (field.type == 'bool') {
        codeList.add('public bool ${field.name}');
        codeList.add('{');
        codeList.add('get => (bool)this[Names.${field.name}];');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else if (field.type == 'DateTime') {
        codeList.add('public DateTime ${field.name}');
        codeList.add('{');
        codeList.add('get => (DateTime)this[Names.${field.name}];');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else if (field.type.startsWith('List')) {
        if (field.isReference) {
          codeList.add('public List<${field.referenceType}> ${field.name}');
          codeList.add('{');
          codeList.add(
              'get => this[Names.${field.name}] as List<${field.referenceType}>;');
          codeList.add('set => this[Names.${field.name}] = value;');
          codeList.add('}');
          codeList.add('public bool ShouldSerialize${field.name}()');
          codeList.add('{');
          codeList.add('return ${field.name} != null && ${field.name}.Any();');
          codeList.add('}');
        } else {
          codeList.add(
              'public IEnumerable<${field.referenceType}> ${field.name} { get; set; }');
          codeList.add('    = ${field.referenceType}.List();');
        }
      } else if (field.isReference) {
        codeList.add('/// <remarks> ');
        codeList.add('/// <see cref="${field.referenceType}"/> reference');
        codeList.add('/// </remarks> ');
        codeList.add(
            '[System.ComponentModel.DefaultValue("00000000-0000-0000-0000-000000000000")]');
        codeList.add('public string ${field.name}');
        codeList.add('{');
        codeList.add('get => this[Names.${field.name}].ToString();');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
        codeList.add('public ${field.referenceType} ${field.referenceName}');
        codeList.add('{');
        codeList.add(
            'get => this[Names.${field.referenceName}] as ${field.referenceType};');
        codeList.add('set => this[Names.${field.referenceName}] = value;');
        codeList.add('}');
        codeList.add('public bool ShouldSerialize${field.referenceName}()');
        codeList.add('{');
        codeList.add('return NestReferences() && (SerializeFields == null ||');
        codeList.add(
            '    SerializeFields.Find(s => s.StartsWith(Names.${field.name})) != default);');
        codeList.add('}');
      } else if (field.type.startsWith('Enum')) {
        codeList.add('/// <remarks>');
        codeList.add('/// <see cref="${field.referenceType}"/> enum type');
        codeList.add('/// </remarks>');
        codeList.add('public int ${field.name}');
        codeList.add('{');
        codeList.add('get => (int)this[Names.${field.name}];');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else if (field.type == 'UntypedReference') {
        codeList.add('/// <remarks> ');
        codeList.add(
            '/// Untyped reference (${field.referenceTypes!.map((e) => e['databaseType'].toString()).join(', ')})');
        codeList.add('/// </remarks> ');
        codeList.add(
            '[System.ComponentModel.DefaultValue("00000000-0000-0000-0000-000000000000.NO")]');
        codeList.add('public string ${field.name}');
        codeList.add('{');
        codeList.add('get => this[Names.${field.name}].ToString();');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else if (field.type == 'Guid') {
        codeList.add('public Guid ${field.name}');
        codeList.add('{');
        codeList.add('get => (Guid)this[Names.${field.name}];');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      } else {
        if (field.name.endsWith('Id')) {
          codeList.add(
              '[System.ComponentModel.DefaultValue("00000000-0000-0000-0000-000000000000")]');
        } else {
          if (field.maxLength > 0) {
            codeList.add('[StringLength(${field.maxLength})]');
          }
          codeList.add('[System.ComponentModel.DefaultValue("")]');
        }
        codeList.add('public string ${field.name}');
        codeList.add('{');
        codeList.add('get => this[Names.${field.name}].ToString();');
        codeList.add('set => this[Names.${field.name}] = value;');
        codeList.add('}');
      }
      //if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });
    if (checkLastModifiedDate) {
      codeList.add('public DateTime LastModified { get; set; }');
      codeList.add('');
    }
    codeList.add('#endregion Properties');

    codeList.add('}');
    codeList.add('}');

    var fn = '${nsgGenerator.cSharpPath}/Models/$typeName.Designer.cs';
    //if (!File(fn).existsSync()) {
    Misc.indentCSharpCode(codeList);
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
      if (nsgMethod.genDataItem.databaseType.isNotEmpty) {
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
      if (nsgMethod.genDataItem.databaseType.isNotEmpty) {
        if (isTableRow)
          codeList.add(
              'var obj = ${nsgMethod.genDataItem.databaseTypeTable}.Новый().NewRow();');
        else
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
          'public override async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Post(INsgTokenExtension user, NsgFindParams findParams, IEnumerable<NsgServerDataItem> items)');
      codeList.add('{');
      if (nsgMethod.genDataItem.databaseType.isNotEmpty) {
        if (nsgMethod.name == 'UserSettings') {
          codeList.add(
              'return await Post<${nsgMethod.genDataItem.typeName}>(user, findParams, items);');
        } else {
          codeList.add(
              'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
          codeList.add(
              'RES[RESULTS] = NsgServerMetadataItem.PostAll<${nsgMethod.genDataItem.typeName}>(user, findParams, items);');
          codeList.add('return RES;');
        }
      } else {
        codeList.add('throw new NotImplementedException();');
      }
      codeList.add('}');
      codeList.add('');
      codeList.add(
          'public override CheckRightsResult CheckRightsPost(INsgTokenExtension user, IEnumerable<NsgServerDataItem> nsgObjects)');
      codeList.add('{');
      codeList.add('return new CheckRightsResult() { AccessGranted = true };');
      codeList.add('}');
      codeList.add('');
    }
    if (nsgMethod.allowDelete) {
      codeList.add(
          'public override async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Delete(INsgTokenExtension user, IEnumerable<NsgServerDataItem> items)');
      codeList.add('{');
      if (nsgMethod.genDataItem.databaseType.isNotEmpty) {
        if (nsgMethod.name == 'UserSettings') {
          codeList.add(
              'return await Delete<${nsgMethod.genDataItem.typeName}>(user, items.Cast<${nsgMethod.genDataItem.typeName}>());');
        } else {
          codeList.add(
              'NsgServerMetadataItem.SetDeleteMarkAll<${nsgMethod.genDataItem.typeName}>(items);');
          codeList.add(
              'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
          codeList.add('RES[RESULTS] = items;');
          codeList.add('return RES;');
        }
      } else {
        codeList.add('throw new NotImplementedException();');
      }
      codeList.add('}');
      codeList.add('');
    }
    if (entityType == NsgGenDataItemEntityType.userSettings) {
      codeList.add(
          'public override Guid GetUserIdByToken(INsgTokenExtension user)');
      codeList.add('{');
      codeList.add('throw new NotImplementedException();');
      codeList.add('}');
    }
    // });
    codeList.add('}');
    codeList.add('}');
    fn = '${nsgGenerator.cSharpPath}/Models/$typeName.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      Misc.indentCSharpCode(codeList);
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
        "import '../${Misc.getDartUnderscoreName(nsgGenController.className)}_model.dart';");
    for (var field in fields) {
      if (!field.writeOnClient) continue;
      if (field.type.startsWith('Enum')) {
        if (nsgGenerator.enums.isNotEmpty) {
          codeList.add("import '../enums.dart';");
        }
        break;
      }
    }
    if (description.isNotEmpty) {
      codeList.add('');
      Misc.writeDescription(codeList, description, false);
    }
    if (entityType == NsgGenDataItemEntityType.userSettings) {
      codeList.add(
          'class ${typeName}Generated extends NsgDataItem with NsgUserSettings {');
    } else {
      codeList.add('class ${typeName}Generated extends NsgDataItem {');
    }
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      codeList.add(
          "  static const ${_.fieldNameVar} = '${Misc.getDartName(_.name)}';");
    });
    codeList.add('');
    codeList.add('  static final Map<String, String> fieldNameDict = {');
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.userVisibility) {
        codeList.add("    ${_.fieldNameVar}: '${_.userName}',");
      }
    });
    codeList.add('  };');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  String get typeName => \'$typeName\';');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  void initialize() {');
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.isPrimary) {
        codeList.add(
            '    addField(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
      } else {
        if (_.type == 'String' &&
            _.maxLength != NsgGenDataItemField.defaultMaxLength[_.type]) {
          codeList.add(
              '    addField(${_.nsgDataType}(${_.fieldNameVar}, maxLength: ${_.maxLength}), primaryKey: ${_.isPrimary});');
        } else if (_.type == 'double' &&
            _.maxLength != NsgGenDataItemField.defaultMaxLength[_.type]) {
          codeList.add(
              '    addField(${_.nsgDataType}(${_.fieldNameVar}, maxDecimalPlaces: ${_.maxLength}), primaryKey: ${_.isPrimary});');
        } else if (_.type == 'UntypedReference') {
          var defaultReferenceType = _.referenceType;
          if ((defaultReferenceType.isEmpty) &&
              _.referenceTypes != null &&
              _.referenceTypes!.isNotEmpty) {
            defaultReferenceType = _.referenceTypes!.first['alias'].toString();
            defaultReferenceType = defaultReferenceType[0].toUpperCase() +
                defaultReferenceType.substring(1);
          }
          if (defaultReferenceType.isNotEmpty) {
            codeList.add(
                '    addField(${_.nsgDataType}(${_.fieldNameVar}, defaultReferentType: $defaultReferenceType), primaryKey: ${_.isPrimary});');
          } else {
            codeList.add(
                '    addField(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
          }
        } else {
          codeList.add(
              '    addField(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
        }
      }
    });
    fields.forEach((_) {
      if (!_.writeOnClient) return;
      if (_.userVisibility) {
        codeList.add(
            "    fieldList.fields[${_.fieldNameVar}]?.presentation = '${_.userName}';");
      }
    });
    codeList.add('  }');
    codeList.add('');
    if (presentation.isNotEmpty) {
      codeList.add('  @override');
      codeList
          .add('  String toString() => ${Misc.getDartToString(presentation)};');
      codeList.add('');
    } else if (fields.isNotEmpty) {
      var nameField = fields.firstWhere((f) => f.name.toLowerCase() == 'name',
          orElse: () => NsgGenDataItemField(name: '', type: ''));
      if (nameField.name.isNotEmpty) {
        codeList.add('  @override');
        codeList
            .add('  String toString() => ${Misc.getDartName(nameField.name)};');
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
      if (_.description.isNotEmpty) {
        Misc.writeDescription(codeList, _.description, false, indent: 2);
      }
      _.writeGetter(nsgGenController, this, codeList);
      _.writeSetter(nsgGenController, this, codeList);
    });
    if (checkLastModifiedDate) {
      var lm = NsgGenDataItemField(name: 'LastModified', type: 'DateTime');
      lm.writeGetter(nsgGenController, this, codeList);
      lm.writeSetter(nsgGenController, this, codeList);
      codeList.add('');
    }
    if (periodFieldName.isNotEmpty) {
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
    codeList.add('');

    await File(
            '${nsgGenerator.dartPathGen}/${Misc.getDartUnderscoreName(typeName)}.g.dart')
        .writeAsString(codeList.join('\r\n'));
    //----------------------------------------------------------
    //generate main item class data_item.dart
    //----------------------------------------------------------
    codeList = <String>[];
    codeList.add(
        "import '${nsgGenerator.genPathName}/${Misc.getDartUnderscoreName(typeName)}.g.dart';");
    codeList.add('');
    codeList.add('class $typeName extends ${typeName}Generated {');
    codeList.add('}');

    var fn =
        '${nsgGenerator.dartPath}/${Misc.getDartUnderscoreName(typeName)}.dart';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }
}

enum NsgGenDataItemEntityType {
  dataItem,
  userSettings;

  static NsgGenDataItemEntityType parse(String v, String typeName) {
    if (typeName == 'UserSettings')
      return NsgGenDataItemEntityType.userSettings;
    switch (v) {
      case 'dataItem':
        return NsgGenDataItemEntityType.dataItem;
      case 'userSettings':
        return NsgGenDataItemEntityType.userSettings;
      default:
        return NsgGenDataItemEntityType.dataItem;
    }
  }
}
