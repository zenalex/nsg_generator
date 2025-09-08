import 'Misc.dart';
import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';

class NsgGenDataItemPredefinedObject {
  final String id;
  final String name;
  final String description;

  NsgGenDataItemPredefinedObject(
      {required this.id, required this.name, this.description = ''});

  factory NsgGenDataItemPredefinedObject.fromJson(
      Map<String, dynamic> parsedJson) {
    return NsgGenDataItemPredefinedObject(
        id: parsedJson['id'],
        name: parsedJson['name'],
        description: parsedJson.containsKey('description')
            ? parsedJson['description']
            : parsedJson['name']);
  }

  static Map<String, int> defaultMaxLength = <String, int>{
    'String': 10000,
    'String<FilePath>': 10000,
    'double': 2
  };

  void writeGetter(NsgGenController nsgGenController, NsgGenDataItem dataItem,
      List<String> codeList) {
    codeList
        .add('  static ${dataItem.typeName} get ${Misc.getDartName(name)} {');
    codeList.add('    var res = ${dataItem.typeName}();');
    codeList.add('    res.id = \'$id\';');
    codeList.add('    res.docState = NsgDataItemDocState.predefined;');
    codeList.add('    return res;');
    codeList.add('  }');
    codeList.add('');
  }
}
