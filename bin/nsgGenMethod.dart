import 'dart:convert';
import 'dart:io';

import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenDataItemField.dart';
import 'nsgGenerator.dart';

class NsgGenMethod {
  final String name;
  final String description;
  final String apiPrefix;
  final String authorize;
  final String type;
  final String dataTypeFlie;
  final bool allowPost;

  NsgGenDataItem genDataItem;

  NsgGenMethod(
      {this.name,
      this.description,
      this.apiPrefix,
      this.authorize,
      this.type,
      this.dataTypeFlie,
      this.allowPost});

  factory NsgGenMethod.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenMethod(
      name: parsedJson['name'],
      description: parsedJson['description'],
      apiPrefix: parsedJson['api_prefix'],
      authorize: parsedJson['authorize'],
      type: parsedJson['type'],
      dataTypeFlie: parsedJson['dataTypeFile'],
      allowPost: parsedJson['allowPost'] == 'true',
    );
  }

  Future generateCode(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller, NsgGenMethod method) async {
    codeList.add('/// <summary>');
    codeList.add('/// $description');
    codeList.add('/// </summary>');
    if (nsgGenerator.targetFramework == 'net5.0') {
      codeList.add('[Route("$apiPrefix")]');

      //Authorization
      if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception('Wrong authorization type in method ${method.name}()');
      }
    } else {
      codeList.add('[Route("api/${controller.api_prefix}/$apiPrefix")]');
    }
    //POST or GET
    var apiType = '';
    if (type == 'get') apiType = 'HttpGet';
    if (type == 'post') apiType = 'HttpPost';
    codeList.add('[$apiType]');

    //Generation get gata method
    codeList.add(
        'public async Task<IEnumerable<${method.genDataItem.typeName}>> ${method.name}()');
    codeList.add('{');
    if (authorize != 'none') {
      codeList.add('var user = await authController.GetUserByToken(Request);');
      codeList.add('return await controller.${method.name}(user);');
    } else {
      codeList.add('return await controller.${method.name}(null);');
    }
    codeList.add('}');
    codeList.add('');

    //Generation post data method
    if (allowPost) {
      if (nsgGenerator.targetFramework == 'net5.0') {
        codeList.add('[Route("$apiPrefix/Post")]');
        //Authorization
        if (authorize == 'anonymous') {
          codeList.add('[Authorize]');
        } else if (authorize == 'user') {
          codeList.add('[Authorize(Roles = UserRoles.User)]');
        } else if (authorize != 'none') {
          throw Exception(
              'Wrong authorization type in method ${method.name}([FromBody] ${method.genDataItem.typeName} items)');
        }
      } else {
        codeList.add('[Route("api/${controller.api_prefix}/$apiPrefix/Post")]');
      }
      codeList.add('[HttpPost]');
      codeList.add(
          'public async Task<IEnumerable<${method.genDataItem.typeName}>> ${method.name}Post([FromBody] IEnumerable<${method.genDataItem.typeName}> items)');
      codeList.add('{');
      if (authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList
            .add('return await controller.${method.name}Post(user, items);');
      } else {
        codeList
            .add('return await controller.${method.name}Post(null, items);');
      }
      codeList.add('}');
      codeList.add('');
    }
    //Generation data class
    if (genDataItem != null) {
      genDataItem.writeCode(nsgGenerator, this);
    }
    //Generation image tranfer methods
    imageFieldList.forEach((element) {
      if (nsgGenerator.targetFramework == 'net5.0') {
        codeList.add('[Route("${element.apiPrefix}/{file}")]');
      } else {
        codeList
            .add('[Route("api/${controller.api_prefix}/$apiPrefix/{file}")]');
      }
      codeList.add('[HttpGet]');
      //for images authentification temporary??? disabled
      // if (authorize == 'anonymous') {
      //   codeList.add('    [Authorize]');
      // } else if (authorize == 'user') {
      //   codeList.add('    [Authorize(Roles = UserRoles.User)]');
      // }
      codeList.add(
          'public async Task<FileStreamResult> ${method.name}${element.apiPrefix}([FromRoute] string file)');
      codeList.add('{');
      if (authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.${method.name}${element.apiPrefix}(user, file);');
      } else {
        codeList.add(
            'return await controller.${method.name}${element.apiPrefix}(null, file);');
      }
      codeList.add('}');
      codeList.add('');
    });
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

  var imageFieldList = <NsgGenDataItemField>[];
  void addImageMethod(NsgGenDataItemField element) {
    imageFieldList.add(element);
  }
}
