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
  final String getterType;
  final String dataTypeFlie;
  final bool allowGetter;
  final bool allowPost;
  final bool checkLastModifiedDate;
  final bool allowDelete;

  NsgGenDataItem genDataItem;

  NsgGenMethod(
      {this.name,
      this.description,
      this.apiPrefix,
      this.authorize,
      this.getterType,
      this.dataTypeFlie,
      this.allowGetter,
      this.allowPost,
      this.checkLastModifiedDate,
      this.allowDelete});

  factory NsgGenMethod.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenMethod(
        name: parsedJson['name'],
        description: parsedJson['description'],
        apiPrefix: parsedJson['api_prefix'],
        authorize: parsedJson['authorize'] ?? 'none',
        getterType: parsedJson.containsKey('getterType')
            ? parsedJson['getterType']
            : parsedJson['type'],
        dataTypeFlie: parsedJson['dataTypeFile'],
        allowGetter: parsedJson['allowGetter'] != 'false',
        allowPost: parsedJson['allowPost'] == 'true',
        checkLastModifiedDate: parsedJson['checkLastModifiedDate'] == 'true',
        allowDelete: parsedJson['allowDelete'] == 'true');
  }

  Future generateCode(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller, NsgGenMethod method) async {
    if (allowGetter || allowPost || allowDelete) {
      codeList.add('/// <summary>');
      codeList.add('/// $description');
      codeList.add('/// </summary>');
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
        throw Exception('Wrong authorization type in method ${method.name}()');
      }
      //POST or GET
      var apiType = 'HttpGet';
      if (getterType == 'post') apiType = 'HttpPost';
      codeList.add('[$apiType]');
      codeList.add(
          'public async Task<IEnumerable<NsgServerDataItem>> ${method.name}([FromBody] NsgFindParams findParams)');
      codeList.add('{');
      codeList.add(
          'return await Task.Run(() => ${method.name}References(findParams).Result["results"]);');
      codeList.add('}');
      codeList.add('');
      codeList.add('[Route("$apiPrefix/References")]');

      //Authorization
      if (!controller.useAuthorization) {
      } else if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception(
            'Wrong authorization type in method ${method.name}References()');
      }
      //POST or GET
      // var apiType = '';
      // if (type == 'get') apiType = 'HttpGet';
      // if (type == 'post') apiType = 'HttpPost';
      codeList.add('[$apiType]');

      //Generate get gata method
      // codeList.add(
      //     'public async Task<IEnumerable<${method.genDataItem.typeName}>> ${method.name}([FromBody] NsgFindParams findParams)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${method.name}References([FromBody] NsgFindParams findParams)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Get<${method.genDataItem.typeName}>(user, findParams);');
      } else {
        codeList.add(
            'return await controller.Get<${method.genDataItem.typeName}>(null, findParams);');
      }
      codeList.add('}');
      codeList.add('');
    }
    //Generate post data method
    if (allowPost) {
      method.genDataItem.checkLastModifiedDate = checkLastModifiedDate;
      codeList.add('[Route("$apiPrefix/Post")]');
      //Authorization
      if (!controller.useAuthorization) {
      } else if (authorize == 'anonymous') {
        codeList.add('[Authorize]');
      } else if (authorize == 'user') {
        codeList.add('[Authorize(Roles = UserRoles.User)]');
      } else if (authorize != 'none') {
        throw Exception(
            'Wrong authorization type in method ${method.name}([FromBody] ${method.genDataItem.typeName} items)');
      }
      codeList.add('[HttpPost]');
      // codeList.add(
      //     'public async Task<IEnumerable<${method.genDataItem.typeName}>> ${method.name}Post([FromBody] IEnumerable<${method.genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${method.name}Post([FromBody] IEnumerable<${method.genDataItem.typeName}> items)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Post<${method.genDataItem.typeName}>(user, items);');
      } else {
        codeList.add(
            'return await controller.Post<${method.genDataItem.typeName}>(null, items);');
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
            'Wrong authorization type in method ${method.name}([FromBody] ${method.genDataItem.typeName} items)');
      }
      codeList.add('[HttpDelete]');
      // codeList.add(
      //     'public async Task<IEnumerable<${method.genDataItem.typeName}>> ${method.name}Post([FromBody] IEnumerable<${method.genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${method.name}Delete([FromBody] IEnumerable<${method.genDataItem.typeName}> items)');
      codeList.add('{');
      if (controller.useAuthorization && authorize != 'none') {
        codeList
            .add('var user = await authController.GetUserByToken(Request);');
        codeList.add(
            'return await controller.Delete<${method.genDataItem.typeName}>(user, items);');
      } else {
        codeList.add(
            'return await controller.Delete<${method.genDataItem.typeName}>(null, items);');
      }
      codeList.add('}');
      codeList.add('');
    }
    //Generate data class
    if (genDataItem != null) {
      genDataItem.writeCode(nsgGenerator, this);
    }
    //Generate image tranfer methods
    imageFieldList.forEach((element) {
      codeList.add('[Route("${element.apiPrefix}/{file}")]');
      codeList.add('[HttpGet]');
      //for images authentification temporary??? disabled
      // if (authorize == 'anonymous') {
      //   codeList.add('    [Authorize]');
      // } else if (authorize == 'user') {
      //   codeList.add('    [Authorize(Roles = UserRoles.User)]');
      // }
      if (nsgGenerator.targetFramework == 'net5.0') {
        codeList.add(
            'public async Task<FileStreamResult> ${method.name}${element.apiPrefix}([FromRoute] string file)');
      } else {
        codeList.add(
            'public async Task<FileStreamResult> ${method.name}${element.apiPrefix}(string file)');
      }
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
        await File('${nsgGenerator.jsonPath}/$dataTypeFlie').readAsString();
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
