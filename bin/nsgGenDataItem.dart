import 'dart:io';

import 'nsgGenCSProject.dart';
import 'nsgGenDataItemField.dart';
import 'nsgGenFunction.dart';
import 'nsgGenMethod.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenDataItem {
  final String typeName;
  final String databaseType;
  final String databaseTypeNamespace;
  final String presentation;
  final List<NsgGenDataItemField> fields;
  final List<NsgGenFunction> methods;

  NsgGenDataItem(
      {this.typeName,
      this.databaseType,
      this.databaseTypeNamespace,
      this.presentation,
      this.fields,
      this.methods});

  factory NsgGenDataItem.fromJson(Map<String, dynamic> parsedJson) {
    var methods = parsedJson['methods'] as List ?? List.empty();
    return NsgGenDataItem(
        typeName: parsedJson['typeName'],
        databaseType: parsedJson['databaseType'],
        databaseTypeNamespace: parsedJson['databaseTypeNamespace'],
        presentation: parsedJson['presentation'],
        fields: (parsedJson['fields'] as List)
            .map((i) => NsgGenDataItemField.fromJson(i))
            .toList(),
        methods: methods.map((i) => NsgGenFunction.fromJson(i)).toList());
  }

  static void generateNsgServerMetadataItem(NsgGenerator nsgGenerator) async {
    var fn = '${nsgGenerator.cSharpPath}/Models/NsgServerMetadataItem.cs';
    if (File(fn).existsSync() && !nsgGenerator.forceOverwrite) return;
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('using Newtonsoft.Json;');
    codeList.add('using NsgSoft.DataObjects;');
    codeList.add('using NsgServerClasses;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList
        .add('public abstract class NsgServerMetadataItem : NsgServerDataItem');
    codeList.add('{');
    codeList.add('public NsgServerMetadataItem(NsgMultipleObject obj)');
    codeList.add('{');
    codeList.add('NSGObject = obj;');
    codeList.add('}');
    codeList.add('');
    codeList.add('[JsonIgnore]');
    codeList.add('public virtual NsgMultipleObject NSGObject { get; set; }');
    codeList.add('public virtual void OnSetNsgObject() { }');
    codeList.add(
        'public virtual void OnBeforePostNsgObject<T>(T obj) where T : NsgMultipleObject { }');
    codeList.add(
        'public virtual void OnAfterPostNsgObject<T>(T obj, T oldObj, bool postSuccessful = true) where T : NsgMultipleObject');
    codeList.add('{');
    codeList.add('if (postSuccessful)');
    codeList.add('{');
    codeList.add('string changed = string.Empty;');
    codeList.add('if (oldObj != null)');
    codeList.add('{');
    codeList.add('oldObj.CopyNotPredefinedFieldsFromObject(obj);');
    codeList.add('changed += "Changed properties: ";');
    codeList.add('foreach (var name in obj.ObjectList.ObjectsNames)');
    codeList.add('{');
    codeList.add('if (oldObj.ObjectList[name].IsModify)');
    codeList.add('{');
    codeList.add('changed += name + ", ";');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    codeList.add(
        'NsgUserActionsRegistrator.RegisterObjectAction(NsgSettings.CurrentUser,');
    codeList.add('    NsgUserRegistrationActions.Post, changed, obj);');
    codeList.add('}');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public static List<T> FromTable<T>(NsgDataTable table) where T : NsgServerMetadataItem, new()');
    codeList.add('{');
    codeList.add('List<T> res = new List<T>();');
    codeList.add('foreach (var i in table.Rows)');
    codeList.add('{');
    codeList.add('res.Add(new T { NSGObject = i });');
    codeList.add('}');
    codeList.add('return res;');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public static IEnumerable<T> FindAll<T>(NsgMultipleObject obj, NsgCompare cmp, NsgSorting sorting, int count = 0)');
    codeList.add('    where T : NsgServerMetadataItem, new()');
    codeList.add('{');
    codeList.add('Func<NsgMultipleObject[]> findAll;');
    codeList.add('int _count = count;');
    codeList.add('var dataObj = obj;');
    codeList.add('if (_count == 0)');
    codeList.add('{');
    codeList.add(
        'if (sorting == null || sorting.Count == 0) findAll = () => dataObj.FindAll(cmp);');
    codeList.add('else findAll = () => dataObj.FindAll(cmp, sorting);');
    codeList.add('}');
    codeList.add(
        'else findAll = () => dataObj.FindAll(ref _count, 0, sorting, cmp);');
    codeList.add('foreach (var i in findAll())');
    codeList.add('{');
    codeList.add('yield return new T { NSGObject = i };');
    codeList.add('}');
    codeList.add('}');
    codeList.add('');

    codeList.add('public virtual bool PostNsgObject() => false;');
    codeList.add('');
    codeList.add(
        'public static IEnumerable<NsgServerDataItem> PostAll<T>(IEnumerable<NsgServerDataItem> objs) where T : NsgServerMetadataItem');
    codeList.add('{');
    codeList.add('foreach (T i in objs)');
    codeList.add('{');
    codeList.add('var o = i.PostNsgObject();');
    codeList.add('if (o) yield return i;');
    codeList.add('}');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public static void SetDeleteMarkAll<T>(IEnumerable<NsgServerDataItem> objs) where T : NsgServerMetadataItem');
    codeList.add('{');
    codeList.add('foreach (T i in objs)');
    codeList.add('{');
    codeList.add('i.NSGObject.SetDeleteMark();');
    codeList.add(
        'NsgUserActionsRegistrator.RegisterObjectAction(NsgSettings.CurrentUser,');
    codeList.add(
        '    NsgUserRegistrationActions.SetDeleteMark, \$"{NsgUserRegistrationActions.SetDeleteMark}: {i.NSGObject}", i.NSGObject);');
    codeList.add('}');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public virtual Dictionary<string, string> GetClientServerNames() => new Dictionary<string, string>();');
    codeList.add('');
    codeList.add('public NsgCompare GetNsgCompareFromXml(string xml)');
    codeList.add('{');
    codeList.add('NsgCompare cmp = NsgCompare.FromXml(xml);');
    codeList.add('ReplaceCompareParameterNames(cmp);');
    codeList.add('return cmp;');
    codeList.add('}');
    codeList.add('');
    codeList.add('public NsgSorting GetNsgSorting(string sortingString)');
    codeList.add('{');
    codeList.add('NsgSorting sorting = new NsgSorting();');
    codeList.add('if (!string.IsNullOrWhiteSpace(sortingString))');
    codeList.add('{');
    codeList.add('sortingString = PrepareFieldNames(sortingString);');
    codeList.add(
        'string[] sortFields = sortingString.Split(\',\').Select(s => s.Trim()).ToArray();');
    codeList.add('foreach (string field in sortFields)');
    codeList.add('{');
    codeList.add('sorting.Add(new NsgSortingParam(field));');
    codeList.add('}');
    codeList.add('}');
    codeList.add('return sorting;');
    codeList.add('}');
    codeList.add('');
    codeList.add('public void ReplaceCompareParameterNames(NsgCompare cmp)');
    codeList.add('{');
    codeList.add('var ps = cmp.Parameters;');
    codeList.add('foreach (var p in ps)');
    codeList.add('{');
    codeList.add('if (p.ParameterValue is NsgCompare)');
    codeList.add('{');
    codeList
        .add('ReplaceCompareParameterNames(p.ParameterValue as NsgCompare);');
    codeList.add('}');
    codeList
        .add('else if (GetClientServerNames().ContainsKey(p.ParameterName))');
    codeList.add('{');
    codeList.add('string newName = GetClientServerNames()[p.ParameterName];');
    codeList.add('cmp.ReplaceParametersNames(p.ParameterName, newName);');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    codeList.add('');
    codeList.add('public string PrepareFieldNames(string names)');
    codeList.add('{');
    codeList.add('if (string.IsNullOrWhiteSpace(names)) return string.Empty;');
    codeList.add(
        'string[] sortFields = names.Split(\',\').Select(s => s.Trim()).ToArray();');
    codeList.add('for (int i = 0; i < sortFields.Length; i++)');
    codeList.add('{');
    codeList.add('ref string field = ref sortFields[i];');
    codeList.add('char lastSymbol = field.Last();');
    codeList.add('string field_ = field;');
    codeList.add('if (lastSymbol == \'+\' || lastSymbol == \'-\')');
    codeList.add('{');
    codeList.add('field_ = field_.TrimEnd(\'+\', \'-\');');
    codeList.add('}');
    codeList.add('if (GetClientServerNames().ContainsKey(field_))');
    codeList.add('{');
    codeList.add('field = GetClientServerNames()[field_];');
    codeList.add('if (lastSymbol == \'+\' || lastSymbol == \'-\')');
    codeList.add('{');
    codeList.add('field += lastSymbol;');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    codeList.add('string res = string.Empty;');
    codeList.add('foreach (string s in sortFields)');
    codeList.add('    res += s + \',\';');
    codeList.add('names = res.TrimEnd(\',\');');
    codeList.add('return names;');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public NsgCompare ClientCompareToNsgCompare(NsgClientCompare clientCompare)');
    codeList.add('{');
    codeList.add(
        'var cmp = new NsgCompare((NsgSoft.Database.NsgLogicalOperator)clientCompare.LogicalOperator);');
    codeList.add('foreach (var i in clientCompare.ParamList)');
    codeList.add('{');
    codeList.add(
        'cmp.Add(i.Name, i.Value, (NsgSoft.Database.NsgComparison)i.ComparisonOperator);');
    codeList.add('}');
    codeList.add('ReplaceCompareParameterNames(cmp);');
    codeList.add('return cmp;');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public override void PrepareFindParams(NsgFindParams findParams)');
    codeList.add('{');
    codeList
        .add('var cmp = GetNsgCompareFromXml(findParams.SearchCriteriaXml);');
    codeList.add('if (findParams.Compare != null)');
    codeList.add('{');
    codeList.add('cmp.Add(ClientCompareToNsgCompare(findParams.Compare));');
    codeList.add('}');
    codeList.add('findParams.SearchCriteriaXml = cmp.ToXml();');
    codeList.add('findParams.Sorting = PrepareFieldNames(findParams.Sorting);');
    codeList.add(
        'findParams.ReadNestedField = PrepareFieldNames(findParams.ReadNestedField);');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public sealed override void ApplyServerFilter(INsgTokenExtension user, NsgFindParams findParams)');
    codeList.add('{');
    codeList
        .add('AddNsgCompare(findParams, GetObjectCompare(user, findParams));');
    codeList.add('base.ApplyServerFilter(user, findParams);');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public virtual NsgCompare GetObjectCompare(INsgTokenExtension user, NsgFindParams findParams) => new NsgCompare();');
    codeList.add('');
    codeList.add(
        'public static void AddNsgCompare(NsgFindParams findParams, NsgCompare cmp)');
    codeList.add('{');
    codeList.add(
        'var inCmp = NsgSoft.DataObjects.NsgCompare.FromXml(findParams.SearchCriteriaXml);');
    codeList.add('inCmp.Add(cmp);');
    codeList.add('findParams.SearchCriteriaXml = inCmp.ToXml();');
    codeList.add('}');
    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    await File(fn).writeAsString(codeList.join('\r\n'));
  }

  void writeCode(NsgGenerator nsgGenerator, NsgGenMethod nsgMethod) async {
    // ${typeName}.Designer.cs
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.ComponentModel.DataAnnotations;');
    if (databaseType != null && databaseType.isNotEmpty) {
      NsgGenDataItem.generateNsgServerMetadataItem(nsgGenerator);
      codeList.add('using NsgSoft.DataObjects;');
      if (databaseTypeNamespace != null && databaseTypeNamespace.isNotEmpty) {
        codeList.add('using $databaseTypeNamespace;');
      }
      codeList.add('');
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add(
          '// This file is autogenerated. Manual changes will be overwritten');
      codeList.add(
          '// --------------------------------------------------------------');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public partial class $typeName : NsgServerMetadataItem');
      codeList.add('{');

      //FromData
      codeList.add('public $typeName() : this(null) { }');
      codeList.add('');
      codeList.add(
          'public $typeName($databaseType dataObject) : base(dataObject) { }');
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
      codeList.add('private $databaseType nsgObject;');
      codeList.add('');
      codeList.add('public override NsgMultipleObject NSGObject');
      codeList.add('{');
      codeList.add('get => nsgObject;');
      codeList.add('set');
      codeList.add('{');
      codeList.add('nsgObject = value as $databaseType;');
      codeList.add('if (value == null) return;');
      fields.forEach((el) {
        if (el.dartType == 'List<Enum>') {
          codeList.add('${el.name} = ${el.referenceType}.List();');
        } else if (el.dbName == null || el.dbName.isEmpty) {
          //codeList.add('${el.name} = default;');
        } else if (el.dartType == 'int') {
          codeList.add('${el.name} = (int)nsgObject.${el.dbName};');
        } else if (el.dartType == 'double') {
          codeList.add('${el.name} = (double)nsgObject.${el.dbName};');
        } else if (['String', 'string'].contains(el.dartType)) {
          codeList.add('${el.name} = nsgObject.${el.dbName}.ToString();');
        } else if (el.dartType == 'Reference' || el.dartType == 'Image') {
          codeList
              .add('${el.name} = nsgObject.${el.dbName}?.Value.ToString();');
        } else if (el.dartType == 'Enum') {
          codeList.add('${el.name} = (int)nsgObject.${el.dbName}.Value;');
        } else if (el.dartType == 'List<Reference>') {
          codeList.add(
              '${el.name} = FromTable<${el.referenceType}>(nsgObject.${el.dbName});');
        } else {
          codeList.add('${el.name} = nsgObject.${el.dbName};');
        }
      });
      codeList.add('OnSetNsgObject();');
      codeList.add('}');
      codeList.add('}');
      codeList.add('');

      codeList.add('public override bool PostNsgObject()');
      codeList.add('{');
      codeList.add('var nsgObject = $databaseType.Новый();');
      codeList.add('NsgMultipleObject clone = null;');
      var pkField = fields.firstWhere(
          (f) => f.name.toLowerCase().contains('id') && f.isPrimary);
      codeList.add(
          'Guid g = Guid.TryParse(${pkField.name}, out Guid ${pkField.name}Guid) ? ${pkField.name}Guid : Guid.Empty;');
      codeList.add('try');
      codeList.add('{');
      codeList.add('if (Guid.Empty.Equals(g))');
      codeList.add('{');
      codeList.add('nsgObject.New();');
      codeList.add('}');
      codeList.add('else');
      codeList.add('{');
      codeList.add(
          'if (!nsgObject.Find(NsgSoft.Common.NsgDataFixedFields._ID, g))');
      codeList.add('{');
      codeList.add('throw new Exception("ERROR: WOI45");');
      codeList.add('}');
      codeList.add('clone = nsgObject.CloneObject as NsgMultipleObject;');
      codeList.add('nsgObject.Edit();');
      codeList.add('}');
      fields.where((f) => f != pkField).forEach((el) {
        if (el.dbName == null || el.dbName.isEmpty) {
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
        } else if (el.dartType == 'Reference' || el.dartType == 'Image') {
          codeList.add(
              'nsgObject.${el.dbName}.Value = Guid.TryParse(${el.name}, out Guid ${el.name}Guid) ? ${el.name}Guid : Guid.Empty;');
        } else if (el.dartType == 'Enum') {
          codeList.add('nsgObject.${el.dbName}.Value = ${el.name};');
        } else if (el.dartType == 'List<Reference>') {
          codeList.add('foreach (var t in ${el.name})');
          codeList.add('{');
          codeList.add('t.PostNsgObject();');
          codeList.add(
              'nsgObject.${el.dbName}.NewRow(t.NSGObject as NsgDataTableRow);');
          codeList.add('}');
        } else {
          codeList.add('nsgObject.${el.dbName} = ${el.name};');
        }
      });
      codeList.add('OnBeforePostNsgObject(nsgObject);');
      codeList.add('bool posted = nsgObject.Post();');
      codeList.add('if (posted) this.NSGObject = nsgObject;');
      codeList.add('OnAfterPostNsgObject(nsgObject, clone, posted);');
      codeList.add('return posted;');
      codeList.add('}');
      codeList.add('finally');
      codeList.add('{');
      codeList.add(
          'if (nsgObject.ObjectState == NsgObjectStates.Edit) nsgObject.Cancel();');
      codeList.add('}');
      codeList.add('}');
      codeList.add('');
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
      //ToData
    } else {
      codeList.add('using NsgServerClasses;');
      codeList.add('');
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
      } else if (element.dartType == 'List<Reference>') {
        codeList.add(
            'public List<${element.referenceType}> ${element.name} { get; set; }');
        codeList.add('    = new List<${element.referenceType}>();');
      } else if (element.dartType == 'List<Enum>') {
        codeList.add(
            'public IEnumerable<${element.referenceType}> ${element.name} { get; set; }');
        codeList.add('    = ${element.referenceType}.List();');
      } else if (element.dartType == 'Enum') {
        codeList.add('/// <remarks>');
        codeList.add('/// <see cref="${element.referenceType}"/> enum type');
        codeList.add('/// </remarks>');
        codeList.add('public int ${element.name} { get; set; }');
      } else if (element.dartType == 'Reference') {
        codeList.add('/// <remarks> ');
        codeList.add('/// <see cref="${element.referenceType}"/> reference');
        codeList.add('/// </remarks> ');
        codeList.add('public string ${element.name} { get; set; }');
      } else {
        if (!element.name.endsWith('Id')) {
          codeList.add('[StringLength(${element.maxLength})]');
        }
        codeList.add('public string ${element.name} { get; set; }');
      }
      if (element.type == 'Image') nsgMethod.addImageMethod(element);
      codeList.add('');
    });

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

    var fn = '${nsgGenerator.cSharpPath}/Models/${typeName}.Designer.cs';
    //if (!File(fn).existsSync()) {
    NsgGenCSProject.indentCode(codeList);
    await File(fn).writeAsString(codeList.join('\r\n'));
    //}

    // ${typeName}.cs
    codeList.clear();
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public partial class $typeName');
    codeList.add('{');
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
    fn = '${nsgGenerator.cSharpPath}/Models/${typeName}.cs';
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

    var codeList = <String>[];
    codeList.add(
        '//This is autogenerated file. All changes will be lost after code generation.');
    codeList.add("import 'package:nsg_data/nsg_data.dart';");
    codeList.add(
        "import '../${nsgGenerator.getDartUnderscoreName(nsgGenController.class_name)}_model.dart';");
    var hasEnums = false;
    fields.forEach((field) {
      if (field.type == 'Enum') {
        if (hasEnums) return;
        if (nsgGenerator.enums.isNotEmpty) {
          codeList.add("import '../enums.dart';");
        }
        hasEnums = true;
      }
    });
    codeList.add('class ${typeName}Generated extends NsgDataItem {');
    fields.forEach((_) {
      codeList.add(
          " static const ${_.fieldNameVar} = '${nsgGenerator.getDartName(_.name)}';");
    });
    codeList.add('');
    codeList.add(' static final Map fieldNameDict = {');
    fields.forEach((_) {
      if (_.userVisibility) {
        codeList.add("   ${_.fieldNameVar}: '${_.userName}',");
      }
    });
    codeList.add(' };');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  void initialize() {');
    fields.forEach((_) {
      if (_.isPrimary) {
        codeList.add(
            '   addfield(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
      } else {
        if (_.type == 'String' &&
            _.maxLength != NsgGenDataItemField.defaultMaxLength[_.type]) {
          codeList.add(
              '   addfield(${_.nsgDataType}(${_.fieldNameVar}, maxLength: ${_.maxLength}), primaryKey: ${_.isPrimary});');
        } else if (_.type == 'double' &&
            _.maxLength != NsgGenDataItemField.defaultMaxLength[_.type]) {
          codeList.add(
              '   addfield(${_.nsgDataType}(${_.fieldNameVar}, maxDecimalPlaces: ${_.maxLength}), primaryKey: ${_.isPrimary});');
        } else {
          codeList.add(
              '   addfield(${_.nsgDataType}(${_.fieldNameVar}), primaryKey: ${_.isPrimary});');
        }
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
    codeList.add('  @override');
    codeList.add('  NsgDataItem getNewObject() => ${typeName}();');
    codeList.add('');

    fields.forEach((_) {
      if (_.description != null && _.description.isNotEmpty) {
        _.description.split('\n').forEach((descLine) {
          codeList.add('/// $descLine');
        });
      }
      _.writeGetter(nsgGenController, codeList);
      _.writeSetter(nsgGenController, codeList);
    });
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  String get apiRequestItems {');
    codeList.add(
        "    return '/${nsgGenController.api_prefix}/${nsgGenMethod.apiPrefix}';");
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
    codeList.add('class ${typeName} extends ${typeName}Generated {');
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
