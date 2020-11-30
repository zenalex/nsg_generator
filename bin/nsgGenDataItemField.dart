import 'nsgGenerator.dart';

class NsgGenDataItemField {
  final String name;
  final String type;
  final String apiPrefix;
  final bool isPrimary;
  final String referenceName;
  final String referenceType;

  NsgGenDataItemField(
      {this.name,
      this.type,
      this.apiPrefix,
      this.isPrimary,
      this.referenceName,
      this.referenceType});

  factory NsgGenDataItemField.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenDataItemField(
        name: parsedJson['name'],
        type: parsedJson['type'],
        apiPrefix: parsedJson['api_prefix'],
        isPrimary: parsedJson['isPrimary'] == 'true',
        referenceName: parsedJson['referenceName'],
        referenceType: parsedJson['referenceType']);
  }

  String get dartName => NsgGenerator.generator.getDartName(name);

  String get fieldNameVar => 'name_' + dartName;

  String get dartType {
    if (type == 'Date') return 'DateTime';
    return type;
  }

  String get nsgDataType {
    if (type == 'String') {
      return 'NsgDataStringField';
    } else if (type == 'Date') {
      return 'NsgDataDateField';
    } else if (type == 'int') {
      return 'NsgDataIntField';
    } else if (type == 'double') {
      return 'NsgDataDoubleField';
    } else if (type == 'Image') {
      return 'NsgDataImageField';
    } else if (type == 'Reference') {
      return 'NsgDataReferenceField';
    } else {
      print("get nsgDataType for field tye $type doesn't found");
      throw Exception();
    }
  }

  void writeGetter(List<String> codeList) {
    if (type == 'String') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar).toString();');
    } else if (type == 'Date') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'int') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'double') {
      codeList.add(
          '$dartType get $dartName => getFieldValue($fieldNameVar) as $dartType;');
    } else if (type == 'Image') {
      codeList.add('String get $dartName {');
      codeList.add('  var s = getFieldValue($fieldNameVar).toString();');
      codeList.add("  if (!s.contains('http')){");
      codeList.add("    return remoteProvider.serverUri + '$apiPrefix' + s;}");
      codeList.add('  else {');
      codeList.add('    return s;}');
      codeList.add('}');
    } else if (type == 'Reference') {
      codeList.add(
          'String get $dartName => getFieldValue($fieldNameVar).toString();');
      codeList.add(
          '$referenceType get $referenceName => getReferent<$referenceType>($fieldNameVar);');
      codeList.add('Future<$referenceType> ${referenceName}Async() async {');
      codeList.add(
          ' return await getReferentAsync<$referenceType>($fieldNameVar);');
      codeList.add('}');
    } else {
      print("write getter for field type $type doesn't found");
      throw Exception();
    }
  }

  void writeSetter(List<String> codeList) {
    if (type == 'Image') {
      codeList.add(
          'set $dartName(String value) => setFieldValue($fieldNameVar, value);');
    } else if (type == 'Reference') {
      codeList.add(
          'set $dartName(String value) => setFieldValue($fieldNameVar, value);');
    } else {
      codeList.add(
          'set $dartName($dartType value) => setFieldValue($fieldNameVar, value);');
    }
  }
}
