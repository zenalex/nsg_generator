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

  NsgGenDataItemField(
      {this.name,
      this.type,
      this.dbName,
      this.dbType,
      this.maxLength,
      this.description,
      this.apiPrefix,
      this.isPrimary,
      this.referenceName,
      this.referenceType,
      this.userVisibility,
      this.userName});

  factory NsgGenDataItemField.fromJson(Map<String, dynamic> parsedJson) {
    var ml = parsedJson['maxLength'];
    if (ml is String) ml = int.parse(ml); // as int ??
    // (defaultMaxLength.containsValue(parsedJson['type'])
    //     ? defaultMaxLength[parsedJson['type']]
    //     : 0);
    return NsgGenDataItemField(
        name: parsedJson['name'],
        type: parsedJson['type'],
        dbName: parsedJson['databaseName'],
        dbType: parsedJson['databaseType'],
        maxLength: ml ??
            (defaultMaxLength.containsKey(parsedJson['type'])
                ? defaultMaxLength[parsedJson['type']]
                : 0),
        description: parsedJson['description'],
        apiPrefix: parsedJson['api_prefix'],
        isPrimary: parsedJson['isPrimary'] == 'true',
        referenceName: parsedJson['referenceName'],
        referenceType: parsedJson['referenceType'],
        userVisibility: parsedJson['userVisibility'] == 'true',
        userName: parsedJson['userName']);
  }

  static Map<String, int> defaultMaxLength = <String, int>{
    'String': 50,
    'double': 2
  };

  String get dartName => NsgGenerator.generator.getDartName(name);

  String get fieldNameVar =>
      'name' + dartName[0].toUpperCase() + dartName.substring(1);

  String get dartType {
    if (type == 'Date') return 'DateTime';
    return type;
  }

  String get nsgDataType {
    if (type == 'String') {
      return 'NsgDataStringField';
    } else if (type == 'Date' || type == 'DateTime') {
      return 'NsgDataDateField';
    } else if (type == 'int') {
      return 'NsgDataIntField';
    } else if (type == 'double') {
      return 'NsgDataDoubleField';
    } else if (type == 'bool') {
      return 'NsgDataBoolField';
    } else if (type == 'Image') {
      return 'NsgDataImageField';
    } else if (type == 'Enum') {
      return 'NsgDataEnumReferenceField<$referenceType>';
    } else if (type == 'Reference') {
      return 'NsgDataReferenceField<$referenceType>';
    } else if (type == 'List<Reference>') {
      return 'NsgDataReferenceListField<$referenceType>';
    } else if (type == 'List<Enum>') {
      return 'NsgDataListLield<$referenceType>';
    } else {
      print("get nsgDataType for field type $type couldn't be found");
      throw Exception();
    }
  }

  void writeGetter(NsgGenController nsgGenController, List<String> codeList) {
    if (type == 'String') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar).toString();');
    } else if (type == 'Date' || type == 'DateTime') {
      codeList.add(
          '$dartType get $dartName => $dartType.parse(getFieldValue($fieldNameVar));');
    } else if (type == 'int') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'bool') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'double') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'Image') {
      codeList.add('String get $dartName {');
      codeList.add('  var s = getFieldValue($fieldNameVar).toString();');
      codeList.add("  if (!s.contains('http')){");
      codeList.add(
          "    return remoteProvider.serverUri + '/${nsgGenController.api_prefix}/$apiPrefix/' + s;}");
      codeList.add('  else {');
      codeList.add('    return s;}');
      codeList.add('}');
    } else if (type == 'List<Reference>') {
      codeList.add(
          'List<${referenceType}> get $dartName => getFieldValue($fieldNameVar) as List<${referenceType}>;');
    } else if (type == 'List<Enum>') {
      codeList.add(
          'List<${referenceType}> get $dartName => getFieldValue($fieldNameVar) as List<${referenceType}>;');
    } else if (type == 'Enum') {
      codeList.add(
          '$referenceType get $dartName => NsgEnum.fromValue($referenceType, getFieldValue($fieldNameVar)) as $referenceType;');
    } else if (type == 'Reference') {
      codeList.add(
          'String get $dartName => getFieldValue($fieldNameVar).toString();');
      codeList.add(
          '$referenceType get ${NsgGenerator.generator.getDartName(referenceName)} => getReferent<$referenceType>($fieldNameVar);');
      codeList.add(
          'Future<$referenceType> ${NsgGenerator.generator.getDartName(referenceName)}Async() async {');
      codeList.add(
          ' return await getReferentAsync<$referenceType>($fieldNameVar);');
      codeList.add('}');
    } else {
      print("write getter for field type $type couldn't be found");
      throw Exception();
    }
    codeList.add('');
  }

  void writeSetter(NsgGenController nsgGenController, List<String> codeList) {
    if (type == 'Image') {
      codeList.add(
          'set $dartName(String value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Reference') {
      codeList.add(
          'set $dartName(String value) => setFieldValue($fieldNameVar, value);');
      codeList.add(
          'set ${NsgGenerator.generator.getDartName(referenceName)}($referenceType value) =>');
      codeList.add('    setFieldValue($fieldNameVar, value.id);');
    } else if (type == 'List<Reference>') {
      codeList.add(
          'set $dartName(List<$referenceType> value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Enum') {
      codeList.add(
          'set $dartName(${referenceType} value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'List<Enum>') {
      codeList.add(
          'set $dartName(List<$referenceType> value) => setFieldValue($fieldNameVar, value);');
    } else {
      codeList.add(
          'set $dartName($dartType value) => setFieldValue($fieldNameVar, value);');
    }
    codeList.add('');
  }
}
