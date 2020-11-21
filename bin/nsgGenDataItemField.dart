import 'nsgGenerator.dart';

class NsgGenDataItemField {
  final String name;
  final String type;
  final String apiPrefix;
  final bool isPrimary;

  NsgGenDataItemField({this.name, this.type, this.apiPrefix, this.isPrimary});

  factory NsgGenDataItemField.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenDataItemField(
        name: parsedJson['name'],
        type: parsedJson['type'],
        apiPrefix: parsedJson['api_prefix'],
        isPrimary: parsedJson['isPrimary'] == 'true');
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
    } else if (type == 'Int') {
      return 'NsgDataIntField';
    } else if (type == 'Image') {
      return 'NsgDataImageField';
    } else if (type == 'Reference') {
      return 'NsgDataReferencedField';
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
    } else if (type == 'Int') {
      codeList.add('$dartType get $dartName => getFieldValue($fieldNameVar);');
    } else if (type == 'Image') {
      codeList.add('String get $dartName {');
      codeList.add('  var s = getFieldValue($fieldNameVar).toString();');
      codeList.add("  if (!s.contains('http')){");
      codeList.add("    return remoteProvider.serverUri + '$apiPrefix' + s;}");
      codeList.add('  else {');
      codeList.add('    return s;}');
      codeList.add('}');
    } else {
      print("write getter for field tye $type doesn't found");
      throw Exception();
    }
  }

  void writeSetter(List<String> codeList) {
    if (type == 'Image') {
      codeList.add(
          'set $dartName(String value) => setFieldValue($fieldNameVar, value);');
    } else {
      codeList.add(
          'set $dartName($dartType value) => setFieldValue($fieldNameVar, value);');
    }
  }
}
