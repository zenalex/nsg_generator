import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenDataItemMethod {
  final String name;
  final String type;
  final String description;
  final String apiPrefix;
  final String referenceName;
  final String referenceType;

  NsgGenDataItemMethod(
      {this.name,
      this.type,
      this.description,
      this.apiPrefix,
      this.referenceName,
      this.referenceType});

  factory NsgGenDataItemMethod.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenDataItemMethod(
        name: parsedJson['name'],
        type: parsedJson['type'],
        description: parsedJson['description'],
        apiPrefix: parsedJson['api_prefix'],
        referenceName: parsedJson['referenceName'],
        referenceType: parsedJson['referenceType']);
  }

  String get dartName => NsgGenerator.generator.getDartName(name);

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
    } else if (type == 'bool') {
      return 'NsgDataBoolField';
    } else if (type == 'Image') {
      return 'NsgDataImageField';
    } else if (type == 'Reference') {
      return 'NsgDataReferenceField<${referenceType}>';
    } else {
      print("get nsgDataType for field type $type couldn't be found");
      throw Exception();
    }
  }

  Duration getd() {
    return Duration();
  }

  void writeMethod(NsgGenController nsgGenController, List<String> codeList) {
    if (description != null && description.isNotEmpty) {
      description.split('\n').forEach((descLine) {
        codeList.add('/// $descLine');
      });
    }
    if (type == null) {
      codeList.add('void $dartName() { }');
    } else if (type == 'String') {
      codeList.add('$dartType $dartName() { }');
    } else if (type == 'Date') {
      codeList.add('$dartType $dartName() { }');
    } else if (type == 'Duration') {
      codeList.add('$dartType $dartName() { }');
    } else if (type == 'int') {
      codeList.add('$dartType $dartName() { }');
    } else if (type == 'bool') {
      codeList.add('$dartType $dartName() { }');
    } else if (type == 'double') {
      codeList.add('$dartType $dartName() { }');
    } else if (type == 'Image') {
      codeList.add('String $dartName() { }');
    } else if (type == 'Reference') {
      codeList.add('String $dartName() { }');
    } else {
      print("write getter for method type $type couldn't be found");
      throw Exception();
    }
    codeList.add('');
  }
}
