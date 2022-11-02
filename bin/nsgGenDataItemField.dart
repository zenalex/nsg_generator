import 'misc.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenDataItemField {
  final String name;
  final String type;
  final String dbName;
  final String dbType;
  final int maxLength;
  final String description;
  final String apiPrefix;
  final bool isPrimary;
  final String referenceName;
  final String referenceType;
  final bool userVisibility;
  final String userName;
  final bool writeOnClient;
  final bool writeOnServer;
  final bool allowPost;
  final List<Map<String, dynamic>>? referenceTypes;

  NsgGenDataItemField(
      {required this.name,
      required this.type,
      this.dbName = '',
      this.dbType = '',
      this.maxLength = 0,
      this.description = '',
      this.apiPrefix = '',
      this.isPrimary = false,
      this.referenceName = '',
      this.referenceType = '',
      this.userVisibility = false,
      this.userName = '',
      this.writeOnClient = true,
      this.writeOnServer = true,
      this.allowPost = true,
      this.referenceTypes});

  factory NsgGenDataItemField.fromJson(Map<String, dynamic> parsedJson) {
    var ml = parsedJson['maxLength'];
    if (ml is String) ml = int.parse(ml); // as int ??
    // (defaultMaxLength.containsValue(parsedJson['type'])
    //     ? defaultMaxLength[parsedJson['type']]
    //     : 0);
    var userName = parsedJson['userName'] ??
        Misc.CamelCaseToNormal(parsedJson['databaseName'] ??
            parsedJson['description'] ??
            parsedJson['name']);

    var name = parsedJson['name'].toString();
    var referenceName = (parsedJson['referenceName'] ?? '').toString();
    var type = (parsedJson['type'] ?? '').toString();
    if (type == 'Date') type = 'DateTime';
    if (type == 'Reference') {
      if (referenceName.isEmpty) {
        if (name.endsWith('Id')) {
          referenceName = name.substring(0, name.length - 2);
        } else {
          referenceName = name;
          name += 'Id';
        }
      }
    }
    return NsgGenDataItemField(
        name: name,
        type: type,
        dbName: parsedJson['databaseName'] ?? '',
        dbType: parsedJson['databaseType'] ?? '',
        maxLength: ml ??
            (defaultMaxLength.containsKey(type) ? defaultMaxLength[type] : 0),
        description: parsedJson.containsKey('description')
            ? parsedJson['description'] ?? ''
            : parsedJson['databaseName'] ?? '',
        apiPrefix: parsedJson.containsKey('apiPrefix')
            ? parsedJson['apiPrefix']
            : parsedJson.containsKey('api_prefix')
                ? parsedJson['api_prefix']
                : name,
        isPrimary: parsedJson['isPrimary'] == 'true',
        referenceName: referenceName,
        referenceType: parsedJson.containsKey('defaultReferenceType')
            ? parsedJson['defaultReferenceType'] ?? ''
            : parsedJson['referenceType'] ?? '',
        userVisibility: parsedJson['userVisibility'] == 'true',
        userName: userName,
        writeOnClient: parsedJson.containsKey('writeOnClient')
            ? parsedJson['writeOnClient'] != 'false'
            : true,
        writeOnServer: parsedJson.containsKey('writeOnServer')
            ? parsedJson['writeOnServer'] != 'false'
            : true,
        allowPost: parsedJson.containsKey('allowPost')
            ? parsedJson['allowPost'] != 'false'
            : true,
        referenceTypes: (parsedJson.containsKey('referenceTypes')
                ? parsedJson['referenceTypes'] as List
                : List.empty())
            .map((e) => e as Map<String, dynamic>)
            .toList());
  }

  static Map<String, int> defaultMaxLength = <String, int>{
    'String': 10000,
    'double': 2
  };

  String get dartName => NsgGenerator.generator.getDartName(name);

  String get fieldNameVar => NsgGenerator.generator
      .getDartName('name' + name[0].toUpperCase() + name.substring(1));

  String get dartType {
    if (type == 'Guid') return 'String';
    return type;
  }

  String get nsgDataType {
    if (type == 'String' || type == 'Guid') {
      return 'NsgDataStringField';
    } else if (type == 'DateTime') {
      return 'NsgDataDateField';
    } else if (type == 'int') {
      return 'NsgDataIntField';
    } else if (type == 'double') {
      return 'NsgDataDoubleField';
    } else if (type == 'bool') {
      return 'NsgDataBoolField';
    } else if (type == 'Image') {
      return 'NsgDataImageField';
    } else if (type == 'Binary') {
      return 'NsgDataBinaryField';
    } else if (type == 'Enum') {
      return 'NsgDataEnumReferenceField<$referenceType>';
    } else if (type == 'Reference') {
      return 'NsgDataReferenceField<$referenceType>';
    } else if (type == 'List<Reference>') {
      return 'NsgDataReferenceListField<$referenceType>';
    } else if (type == 'List<Enum>') {
      return 'NsgDataListLield<$referenceType>';
    } else if (type == 'UntypedReference') {
      return 'NsgDataUntypedReferenceField';
    } else {
      print("get nsgDataType for field type $type couldn't be found");
      throw Exception();
    }
  }

  void writeGetter(NsgGenController nsgGenController, List<String> codeList) {
    if (['id', 'ownerid'].contains(name.toLowerCase())) {
      codeList.add('  @override');
    }
    if (type == 'String' || type == 'Guid') {
      codeList.add(
          '  $dartType get $dartName => getFieldValue($fieldNameVar).toString();');
    } else if (type == 'DateTime') {
      codeList.add(
          '  $dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'int') {
      codeList.add(
          '  $dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'bool') {
      codeList.add(
          '  $dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'double') {
      codeList.add(
          '  $dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (['Image', 'Binary'].contains(type)) {
      codeList.add('  List<int> get $dartName {');
      codeList.add('    return getFieldValue($fieldNameVar) as List<int>;');
      codeList.add('  }');
    } else if (type == 'List<Reference>') {
      codeList.add(
          '  NsgDataTable<$referenceType> get $dartName => NsgDataTable<$referenceType>(owner: this, fieldName: $fieldNameVar);');
    } else if (type == 'List<Enum>') {
      codeList.add(
          '  List<$referenceType> get $dartName => getFieldValue($fieldNameVar) as List<$referenceType>;');
    } else if (type == 'Enum') {
      codeList.add(
          '  $referenceType get $dartName => NsgEnum.fromValue($referenceType, getFieldValue($fieldNameVar)) as $referenceType;');
    } else if (type == 'Reference') {
      codeList.add(
          '  String get $dartName => getFieldValue($fieldNameVar).toString();');
      codeList.add(
          '  $referenceType get ${NsgGenerator.generator.getDartName(referenceName)} => getReferent<$referenceType>($fieldNameVar);');
      codeList.add(
          '  Future<$referenceType> ${NsgGenerator.generator.getDartName(referenceName)}Async() async {');
      codeList.add(
          '   return await getReferentAsync<$referenceType>($fieldNameVar);');
      codeList.add('  }');
    } else if (type == 'UntypedReference') {
      codeList.add(
          '  String get $dartName => getFieldValue($fieldNameVar).toString();');
      codeList.add(
          '  NsgDataItem get ${NsgGenerator.generator.getDartName(referenceName)} => getReferent<NsgDataItem>($fieldNameVar);');
      codeList.add(
          '  Future<NsgDataItem> ${NsgGenerator.generator.getDartName(referenceName)}Async() async {');
      codeList
          .add('   return await getReferentAsync<NsgDataItem>($fieldNameVar);');
      codeList.add('  }');
    } else {
      print("write getter for field type $type couldn't be found");
      throw Exception();
    }
    codeList.add('');
  }

  void writeSetter(NsgGenController nsgGenController, List<String> codeList) {
    if (['id', 'ownerid'].contains(name.toLowerCase())) {
      codeList.add('  @override');
    }
    if (type == 'Image') {
      codeList.add(
          '  set $dartName(List<int> value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Binary') {
      codeList.add(
          '  set $dartName(List<int> value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Reference') {
      codeList.add(
          '  set $dartName(String value) => setFieldValue($fieldNameVar, value);');
      codeList.add(
          '  set ${NsgGenerator.generator.getDartName(referenceName)}($referenceType value) =>');
      codeList.add('    setFieldValue($fieldNameVar, value.id);');
    } else if (type == 'UntypedReference') {
      codeList.add(
          '  set $dartName(String value) => setFieldValue($fieldNameVar, value);');
      codeList.add(
          '  set ${NsgGenerator.generator.getDartName(referenceName)}(NsgDataItem value) =>');
      codeList.add('    setFieldValue($fieldNameVar, value);');
    } else if (type == 'List<Reference>') {
      //Отменил запись setter из-за смены возвращаемого типа на NsgDataTable
      // codeList.add(
      //     '  set $dartName(List<$referenceType> value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Enum') {
      codeList.add(
          '  set $dartName($referenceType value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'List<Enum>') {
      codeList.add(
          '  set $dartName(List<$referenceType> value) => setFieldValue($fieldNameVar, value);');
    } else {
      codeList.add(
          '  set $dartName($dartType value) => setFieldValue($fieldNameVar, value);');
    }
    codeList.add('');
  }
}
