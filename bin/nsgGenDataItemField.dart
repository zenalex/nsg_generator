import 'misc.dart';
import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';

class NsgGenDataItemField {
  final String name;
  final String type;
  final String databaseName;
  final int maxLength;
  final bool useDate;
  final bool useTime;
  final String description;
  final String apiPrefix;
  final bool isPrimary;
  final String referenceName;
  final String referenceType;
  final bool isReference;
  final bool isString;
  final bool userVisibility;
  final String userName;
  final bool writeOnClient;
  final bool writeOnServer;
  final bool allowPost;
  final List<String>? referenceTypes;

  NsgGenDataItemField(
      {required this.name,
      required this.type,
      this.databaseName = '',
      this.maxLength = 0,
      this.useDate = true,
      this.useTime = true,
      this.description = '',
      this.apiPrefix = '',
      this.isPrimary = false,
      this.referenceName = '',
      this.referenceType = '',
      this.isReference = false,
      this.isString = false,
      this.userVisibility = false,
      this.userName = '',
      this.writeOnClient = true,
      this.writeOnServer = true,
      this.allowPost = true,
      this.referenceTypes});

  factory NsgGenDataItemField.fromJson(Map<String, dynamic> parsedJson) {
    Misc.checkObsoleteKeysInJSON('field', parsedJson, {'api_prefix': ''},
        throwIfAny: true);
    String name = '';
    String currentProperty = 'name';
    try {
      name = parsedJson['name'].toString();

      var ml = parsedJson['maxLength'];
      if (ml is String) ml = int.parse(ml); // as int ??
      // (defaultMaxLength.containsValue(parsedJson['type'])
      //     ? defaultMaxLength[parsedJson['type']]
      //     : 0);
      var userName = parsedJson['userName'] ??
          Misc.CamelCaseToNormal(parsedJson['databaseName'] ??
              parsedJson['description'] ??
              parsedJson['name']);

      currentProperty = 'type, referenceType';
      var referenceName = (parsedJson['referenceName'] ?? '').toString();
      String referenceType = parsedJson.containsKey('defaultReferenceType')
          ? parsedJson['defaultReferenceType'] ?? ''
          : parsedJson['referenceType'] ?? '';
      var type = (parsedJson['type'] ?? '').toString();
      bool isReference = Misc.needToSpecifyType(type);
      bool isString = false;
      if (type == 'String' || type.startsWith('String<')) {
        isString = true;
      } else if (type == 'Date') type = 'DateTime';
      if (type.startsWith('Reference') || type.startsWith('UntypedReference')) {
        if (referenceName.isEmpty) {
          if (name.endsWith('Id')) {
            referenceName = name.substring(0, name.length - 2);
          } else {
            referenceName = name;
            name += 'Id';
          }
        }
      }
      currentProperty = 'referenceTypes';
      var untTypes = (parsedJson.containsKey('referenceTypes')
              ? parsedJson['referenceTypes'] as List
              : List.empty())
          .cast<String>()
          .toList();
      currentProperty = 'type, referenceType';
      // if (type.startsWith('UntypedReference') && type != 'UntypedReference') {
      // } else
      if (referenceType.isEmpty &&
          type != 'List<Reference>' &&
          type != 'List<Enum>' &&
          (type.startsWith('List<') ||
              type.startsWith('Enum<') ||
              type.startsWith('Reference<') ||
              type.startsWith('UntypedReference<')) &&
          type.endsWith('>')) {
        referenceType =
            type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
        if (referenceType.contains('<') && referenceType.endsWith('>')) {
          referenceType = referenceType.substring(
              referenceType.indexOf('<') + 1, referenceType.lastIndexOf('>'));
        }
        var split = referenceType.split(',');
        referenceType = split[0].trim();
        var referenceTypes = split.map((e) => e.trim()).toList();
        untTypes.addAll(referenceTypes);
      }
      currentProperty = '';
      isReference = !Misc.isPrimitiveType(type);
      return NsgGenDataItemField(
          name: name,
          type: type,
          databaseName: parsedJson['databaseName'] ?? '',
          maxLength: ml ??
              (defaultMaxLength.containsKey(type) ? defaultMaxLength[type] : 0),
          useDate: Misc.parseBoolOrTrue(parsedJson['useDate']),
          useTime: Misc.parseBoolOrTrue(parsedJson['useTime']),
          description: parsedJson.containsKey('description')
              ? parsedJson['description'] ?? ''
              : parsedJson['databaseName'] ?? '',
          apiPrefix: parsedJson.containsKey('apiPrefix')
              ? parsedJson['apiPrefix']
              : name,
          isPrimary: Misc.parseBool(parsedJson['isPrimary']),
          referenceName: referenceName,
          referenceType: referenceType,
          isReference: isReference,
          isString: isString,
          userVisibility: Misc.parseBool(parsedJson['userVisibility']),
          userName: userName,
          writeOnClient: Misc.parseBoolOrTrue(parsedJson['writeOnClient']),
          writeOnServer: Misc.parseBoolOrTrue(parsedJson['writeOnServer']),
          allowPost: Misc.parseBoolOrTrue(parsedJson['allowPost']),
          referenceTypes: untTypes);
    } catch (e) {
      print(
          '--- ERROR parsing${currentProperty.isEmpty ? '' : ' property \'$currentProperty\' of'} field \'$name\' ---');
      rethrow;
    }
  }

  static Map<String, int> defaultMaxLength = <String, int>{
    'String': 10000,
    'String<FilePath>': 10000,
    'double': 2
  };

  String get dartName => Misc.getDartName(name);

  String get fieldNameVar =>
      Misc.getDartName('name' + name[0].toUpperCase() + name.substring(1));

  String get dartType {
    if (isString || type == 'Guid') return 'String';
    return type;
  }

  String get nsgDataType {
    if (isString || type == 'Guid') {
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
    } else if (type.startsWith('Enum')) {
      return 'NsgDataEnumReferenceField<$referenceType>';
    } else if (type.startsWith('List')) {
      if (isReference) {
        return 'NsgDataReferenceListField<$referenceType>';
      } else {
        return 'NsgDataListField<$referenceType>';
      }
    } else if (isReference) {
      return 'NsgDataReferenceField<$referenceType>';
    } else if (type.startsWith('UntypedReference')) {
      return 'NsgDataUntypedReferenceField';
    } else {
      var message = "get nsgDataType for field type $type couldn't be found";
      print(message);
      throw Exception(message);
    }
  }

  void writeGetter(NsgGenController nsgGenController, NsgGenDataItem dataItem,
      List<String> codeList) {
    if (['id', 'ownerid'].contains(name.toLowerCase())) {
      codeList.add('  @override');
    }
    if (dataItem.entityType != NsgGenDataItemEntityType.dataItem &&
        NsgGenDataItemEntityType.typeFields[dataItem.entityType]!
            .contains(name)) {
      codeList.add('  @override');
    }
    if (type == 'String<FilePath>') {
      if (nsgGenController.hasGetStreamFunction) {
        codeList.add('  $dartType get $dartName => '
            '\'\${NsgServerOptions.serverUri${nsgGenController.className}}/${nsgGenController.apiPrefix}'
            '/GetStream?path=\${getFieldValue($fieldNameVar)}\';');
      } else {
        codeList.add(
            '  $dartType get $dartName => getFieldValue($fieldNameVar).toString();');
      }
    } else if (type == 'String' || type == 'Guid') {
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
    } else if (type.startsWith('List')) {
      if (isReference) {
        codeList.add(
            '  NsgDataTable<$referenceType> get $dartName => NsgDataTable<$referenceType>(owner: this, fieldName: $fieldNameVar);');
      } else {
        codeList.add(
            '  List<$referenceType> get $dartName => getFieldValue($fieldNameVar) as List<$referenceType>;');
      }
    } else if (isReference) {
      codeList.add(
          '  String get $dartName => getFieldValue($fieldNameVar).toString();');
      codeList.add(
          '  $referenceType get ${Misc.getDartName(referenceName)} => getReferent<$referenceType>($fieldNameVar);');
      codeList.add(
          '  Future<$referenceType> ${Misc.getDartName(referenceName)}Async() async {');
      codeList.add(
          '   return await getReferentAsync<$referenceType>($fieldNameVar);');
      codeList.add('  }');
    } else if (type.startsWith('Enum')) {
      codeList.add(
          '  $referenceType get $dartName => NsgEnum.fromValue($referenceType, getFieldValue($fieldNameVar)) as $referenceType;');
    } else if (type.startsWith('UntypedReference')) {
      codeList.add(
          '  String get $dartName => getFieldValue($fieldNameVar).toString();');
      codeList.add(
          '  NsgDataItem get ${Misc.getDartName(referenceName)} => getReferent<NsgDataItem>($fieldNameVar);');
      codeList.add(
          '  Future<NsgDataItem> ${Misc.getDartName(referenceName)}Async() async {');
      codeList
          .add('   return await getReferentAsync<NsgDataItem>($fieldNameVar);');
      codeList.add('  }');
    } else {
      var message = "write getter for field type $type couldn't be found";
      print(message);
      throw Exception(message);
    }
    codeList.add('');
  }

  void writeSetter(NsgGenController nsgGenController, NsgGenDataItem dataItem,
      List<String> codeList) {
    if (['id', 'ownerid'].contains(name.toLowerCase())) {
      codeList.add('  @override');
    }
    if (dataItem.entityType != NsgGenDataItemEntityType.dataItem &&
        !type.startsWith('List') &&
        allowPost &&
        NsgGenDataItemEntityType.typeFields[dataItem.entityType]!
            .contains(name)) {
      codeList.add('  @override');
    }
    if (type == 'Image') {
      codeList.add(
          '  set $dartName(List<int> value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Binary') {
      codeList.add(
          '  set $dartName(List<int> value) => setFieldValue($fieldNameVar, value);');
    } else if (type.startsWith('UntypedReference')) {
      codeList.add(
          '  set $dartName(String value) => setFieldValue($fieldNameVar, value);');
      codeList.add(
          '  set ${Misc.getDartName(referenceName)}(NsgDataItem value) =>');
      codeList.add('    setFieldValue($fieldNameVar, value);');
    } else if (type.startsWith('List')) {
      if (isReference) {
        return; // не вводить лишний перенос строки
        //Отменил запись setter из-за смены возвращаемого типа на NsgDataTable
        // codeList.add(
        //     '  set $dartName(List<$referenceType> value) => setFieldValue($fieldNameVar, value);');
      } else {
        codeList.add(
            '  set $dartName(List<$referenceType> value) => setFieldValue($fieldNameVar, value);');
      }
    } else if (isReference) {
      codeList.add(
          '  set $dartName(String value) => setFieldValue($fieldNameVar, value);');
      codeList.add(
          '  set ${Misc.getDartName(referenceName)}($referenceType value) =>');
      codeList.add('    setFieldValue($fieldNameVar, value.id);');
    } else if (type.startsWith('Enum')) {
      codeList.add(
          '  set $dartName($referenceType value) => setFieldValue($fieldNameVar, value);');
    } else {
      codeList.add(
          '  set $dartName($dartType value) => setFieldValue($fieldNameVar, value);');
    }
    codeList.add('');
  }
}
