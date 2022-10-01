import 'dart:convert';
import 'dart:io';

import 'misc.dart';
import 'nsgGenController.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenerator.dart';

class NsgGenMethod {
  final String name;
  final String description;
  final String apiPrefix;
  final String authorize;
  final String getterType;
  final String dataTypeFlie;
  final bool allowGetter;
  final bool allowCreate;
  final bool allowPost;
  final bool checkLastModifiedDate;
  final bool allowDelete;

  late NsgGenDataItem genDataItem;

  NsgGenMethod(
      {required this.name,
      this.description = '',
      required this.apiPrefix,
      required this.authorize,
      this.getterType = 'POST',
      required this.dataTypeFlie,
      this.allowGetter = true,
      this.allowCreate = false,
      this.allowPost = false,
      this.checkLastModifiedDate = false,
      this.allowDelete = false});

  factory NsgGenMethod.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenMethod(
        name: parsedJson['name'] ?? '',
        description: parsedJson['description'] ?? '',
        apiPrefix: parsedJson.containsKey('apiPrefix')
            ? parsedJson['apiPrefix']
            : parsedJson.containsKey('api_prefix')
                ? parsedJson['api_prefix']
                : parsedJson['name'],
        authorize: parsedJson['authorize'] ?? 'none',
        getterType: (parsedJson.containsKey('getterType')
                ? parsedJson['getterType']
                : parsedJson['type'] ?? 'POST')
            .toString()
            .toUpperCase(),
        dataTypeFlie: parsedJson['dataTypeFile'] ?? '',
        allowGetter: parsedJson.containsKey('allowGetter')
            ? parsedJson['allowGetter'] != 'false'
            : true,
        allowCreate: parsedJson['allowCreate'] == 'true',
        allowPost: parsedJson['allowPost'] == 'true',
        checkLastModifiedDate: parsedJson['checkLastModifiedDate'] == 'true',
        allowDelete: parsedJson['allowDelete'] == 'true');
  }

  Future generateCode(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller) async {
    if (allowGetter || allowPost || allowDelete) {
      Misc.writeDescription(codeList, description, true);
    }
    if (allowGetter) {
      codeList.add('[Route("$apiPrefix")]');

      //Authorization
      if (!controller.useAuthorization) {
      } else if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception('Wrong authorization type in method $name()');
      }
      //POST or GET
      var apiType = 'HttpGet';
      if (getterType == 'POST') apiType = 'HttpPost';
      // var apiType = '';
      // if (type == 'get') apiType = 'HttpGet';
      // if (type == 'post') apiType = 'HttpPost';
      codeList.add('[$apiType]');

      //Generate get gata method
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}([FromBody] NsgFindParams findParams)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> $name([FromBody] NsgFindParams findParams)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Get<${genDataItem.typeName}>(user, findParams);');
      } else {
        codeList.add(
            'return await controller.Get<${genDataItem.typeName}>(null, findParams);');
      }
      codeList.add('}');
      codeList.add('');
    }
    //Generate create data method
    if (allowCreate) {
      genDataItem.allowCreate = allowCreate;
      codeList.add('[Route("$apiPrefix/Create")]');
      //Authorization
      if (!controller.useAuthorization) {
      } else if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception(
            'Wrong authorization type in method $name([FromBody] ${genDataItem.typeName} items)');
      }
      codeList.add('[HttpPost]');
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${name}Create([FromBody] NsgFindParams findParams)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Create<${genDataItem.typeName}>(user, findParams);');
      } else {
        codeList.add(
            'return await controller.Create<${genDataItem.typeName}>(null, findParams);');
      }
      codeList.add('}');
      codeList.add('');
    }
    //Generate post data method
    if (allowPost) {
      genDataItem.checkLastModifiedDate = checkLastModifiedDate;
      codeList.add('[Route("$apiPrefix/Post")]');
      //Authorization
      if (!controller.useAuthorization) {
      } else if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception(
            'Wrong authorization type in method $name([FromBody] ${genDataItem.typeName} items)');
      }
      codeList.add('[HttpPost]');
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Post<${genDataItem.typeName}>(user, items);');
      } else {
        codeList.add(
            'return await controller.Post<${genDataItem.typeName}>(null, items);');
      }
      codeList.add('}');
      codeList.add('');
    }

    //Generate delete data method
    if (allowDelete) {
      codeList.add('[Route("$apiPrefix/Delete")]');
      //Authorization
      if (!controller.useAuthorization) {
      } else if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception(
            'Wrong authorization type in method $name([FromBody] ${genDataItem.typeName} items)');
      }
      codeList.add('[HttpDelete]');
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${name}Delete([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Delete<${genDataItem.typeName}>(user, items);');
      } else {
        codeList.add(
            'return await controller.Delete<${genDataItem.typeName}>(null, items);');
      }
      codeList.add('}');
      codeList.add('');
    }
    //Generate data class
    genDataItem.writeCode(nsgGenerator, this);
    //Generate image tranfer methods
    // imageFieldList.forEach((element) {
    //   codeList.add('[Route("${element.apiPrefix}/{file}")]');
    //   codeList.add('[HttpGet]');

    //   if (nsgGenerator.targetFramework == 'net5.0') {
    //     codeList.add(
    //         'public async Task<FileStreamResult> ${name}${element.apiPrefix}([FromRoute] string file)');
    //   } else {
    //     codeList.add(
    //         'public async Task<FileStreamResult> ${name}${element.apiPrefix}(string file)');
    //   }
    //   codeList.add('{');
    //   if (authorize != 'none') {
    //     codeList
    //         .add('var user = await authController.GetUserByToken(Request);');
    //     codeList.add(
    //         'return await controller.${name}${element.apiPrefix}(user, file);');
    //   } else {
    //     codeList.add(
    //         'return await controller.${name}${element.apiPrefix}(null, file);');
    //   }
    //   codeList.add('}');
    //   codeList.add('');
    //}
  }

  Future loadGenDataItem(NsgGenerator nsgGenerator) async {
    print('$name genDataItem initializing');
    var text =
        await File('${nsgGenerator.jsonPath}/$dataTypeFlie').readAsString();
    genDataItem = NsgGenDataItem.fromJson(json.decode(text));
    print('$name genDataItem initialized');
  }

  Future generateCodeDart(
      NsgGenerator nsgGenerator, NsgGenController nsgGenController) async {
    await genDataItem.generateCodeDart(nsgGenerator, nsgGenController, this);
  }

//   var imageFieldList = <NsgGenDataItemField>[];
//   void addImageMethod(NsgGenDataItemField element) {
//     imageFieldList.add(element);
//   }
}
