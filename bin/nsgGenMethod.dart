import 'dart:convert';
import 'dart:io';

import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenerator.dart';

class NsgGenMethod {
  final String name;
  final String description;
  final String apiPrefix;
  final String authorize;
  final String type;
  final String dataTypeFlie;

  NsgGenDataItem genDataItem;

  NsgGenMethod(
      {this.name,
      this.description,
      this.apiPrefix,
      this.authorize,
      this.type,
      this.dataTypeFlie});

  factory NsgGenMethod.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenMethod(
      name: parsedJson['name'],
      description: parsedJson['description'],
      apiPrefix: parsedJson['api_prefix'],
      authorize: parsedJson['authorize'],
      type: parsedJson['type'],
      dataTypeFlie: parsedJson['dataTypeFile'],
    );
  }

  Future generateCode(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller, NsgGenMethod method) async {
    codeList.add('    /// <summary>');
    codeList.add('    /// $description');
    codeList.add('    /// </summary>');
    codeList.add('    [Route("$apiPrefix")]');
    //Authorization
    if (authorize == 'anonymous') {
      codeList.add('    [Authorize]');
    } else if (authorize == 'user') {
      codeList.add('    [Authorize(Roles = UserRoles.User)]');
    } else if (authorize != 'none') {
      throw Exception('Wrong authorization type in method ${method.name}()');
    }
    //POST or GET
    var apiType = '';
    if (type == 'get') apiType = 'HttpGet';
    if (type == 'post') apiType = 'HttpPost';
    codeList.add('    [$apiType]');

    codeList.add(
        '    public IEnumerable<${method.genDataItem.typeName}> ${method.name}()');
    codeList.add('    {');
    if (authorize != 'none') {
      codeList.add('      var user = authController.GetUserByToken(Request);');
      codeList.add('      return controller.${method.name}(user);');
    } else {
      codeList.add('      return controller.${method.name}();');
    }
    codeList.add('    }');
    codeList.add('');

    if (genDataItem != null) {
      genDataItem.writeCode(nsgGenerator);
    }
  }

  Future loadGenDataItem(NsgGenerator nsgGenerator) async {
    print('$name genDataItem initializing');
    var text =
        await File('${nsgGenerator.jsonPath}/${dataTypeFlie}').readAsString();
    genDataItem = NsgGenDataItem.fromJson(json.decode(text));
    print('$name genDataItem initialized');
  }

  Future generateCodeDart(
      NsgGenerator nsgGenerator, NsgGenController nsgGenController) async {
    if (genDataItem != null) {
      await genDataItem.generateCodeDart(nsgGenerator, nsgGenController, this);
    }
  }
}
