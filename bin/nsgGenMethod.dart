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
  final String authorizeGet;
  final String authorizeCreate;
  final String authorizePost;
  final String authorizeDelete;
  final String getterType;
  final String dataTypeFlie;
  final bool allowGetter;
  final bool allowCreate;
  final bool allowPost;
  final bool allowDelete;

  late NsgGenDataItem genDataItem;

  NsgGenMethod(
      {required this.name,
      this.description = '',
      required this.apiPrefix,
      required this.authorize,
      required this.authorizeGet,
      required this.authorizeCreate,
      required this.authorizePost,
      required this.authorizeDelete,
      this.getterType = 'POST',
      required this.dataTypeFlie,
      this.allowGetter = true,
      this.allowCreate = false,
      this.allowPost = false,
      this.allowDelete = false});

  static Map<String, String> obsoleteKeys = {
    'api_prefix': 'apiPrefix',
  };

  factory NsgGenMethod.fromJson(Map<String, dynamic> parsedJson) {
    Misc.checkObsoleteKeysInJSON('method', parsedJson, obsoleteKeys,
        throwIfAny: true);
    var name = (parsedJson['name'] ?? '').toString();
    try {
      var needsAllCRUD = name == 'UserSettings' || name == 'ExchangeRules';
      return NsgGenMethod(
          name: name,
          description: parsedJson['description'] ?? '',
          apiPrefix: parsedJson.containsKey('apiPrefix')
              ? parsedJson['apiPrefix']
              : name,
          authorize: parsedJson['authorize'] ?? 'none',
          authorizeGet: parsedJson['authorize.get'] ?? '',
          authorizeCreate: parsedJson['authorize.create'] ?? '',
          authorizePost: parsedJson['authorize.post'] ?? '',
          authorizeDelete: parsedJson['authorize.delete'] ?? '',
          getterType: (parsedJson.containsKey('getterType')
                  ? parsedJson['getterType']
                  : parsedJson['type'] ?? 'POST')
              .toString()
              .toUpperCase(),
          dataTypeFlie: parsedJson['dataTypeFile'] ?? '',
          allowGetter:
              Misc.parseBoolOrTrue(parsedJson['allowGetter']) || needsAllCRUD,
          allowCreate: Misc.parseBool(parsedJson['allowCreate']),
          allowPost: Misc.parseBool(parsedJson['allowPost']) || needsAllCRUD,
          allowDelete:
              Misc.parseBool(parsedJson['allowDelete']) || needsAllCRUD);
    } catch (e) {
      print('--- ERROR parsing method \'$name\' ---');
      rethrow;
    }
  }

  String? getAuthAttr(String authLevel) {
    if (authLevel == 'anonymous') {
      return '[Authorize]';
    } else if (authLevel == 'user') {
      return '[Authorize(Roles = UserRoles.User)]';
    } else if (authLevel == 'admin') {
      return '[Authorize(Roles = UserRoles.Admin)]';
    } else if (authLevel == 'none') {
      return '';
    }
    return null;
  }

  Future generateCode(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller) async {
    // Приоритет: authorize из data item (user_item.json), иначе из метода (generation_config).
    final effectiveAuthorize =
        genDataItem.authorize != 'none' ? genDataItem.authorize : authorize;
    final effectiveAuthorizeGet =
        authorizeGet.isNotEmpty ? authorizeGet : effectiveAuthorize;
    final effectiveAuthorizeCreate =
        authorizeCreate.isNotEmpty ? authorizeCreate : effectiveAuthorize;
    final effectiveAuthorizePost =
        authorizePost.isNotEmpty ? authorizePost : effectiveAuthorize;
    final effectiveAuthorizeDelete =
        authorizeDelete.isNotEmpty ? authorizeDelete : effectiveAuthorize;

    String authorizeAttr,
        authorizeAttrGet,
        authorizeAttrCreate,
        authorizeAttrPost,
        authorizeAttrDelete;

    if (allowGetter || allowPost || allowDelete) {
      Misc.writeDescription(codeList, description, true);

      //Authorization
      if (!controller.useAuthorization) {
        authorizeAttr = '';
      } else {
        var _authorizeAttr = getAuthAttr(effectiveAuthorize);
        if (_authorizeAttr == null) {
          throw Exception('Wrong authorization type in method $name');
        }
        authorizeAttr = _authorizeAttr;
      }

      //get
      if (authorizeGet.isEmpty || !controller.useAuthorization) {
        authorizeAttrGet = authorizeAttr;
      } else {
        authorizeAttrGet = getAuthAttr(authorizeGet) ?? authorizeAttr;
      }

      //create
      if (authorizeCreate.isEmpty || !controller.useAuthorization) {
        authorizeAttrCreate = authorizeAttr;
      } else {
        authorizeAttrCreate = getAuthAttr(authorizeCreate) ?? authorizeAttr;
      }

      //post
      if (authorizePost.isEmpty || !controller.useAuthorization) {
        authorizeAttrPost = authorizeAttr;
      } else {
        authorizeAttrPost = getAuthAttr(authorizePost) ?? authorizeAttr;
      }

      //delete
      if (authorizeDelete.isEmpty || !controller.useAuthorization) {
        authorizeAttrDelete = authorizeAttr;
      } else {
        authorizeAttrDelete = getAuthAttr(authorizeDelete) ?? authorizeAttr;
      }
    } else {
      authorizeAttr = '';
      authorizeAttrGet = '';
      authorizeAttrCreate = '';
      authorizeAttrPost = '';
      authorizeAttrDelete = '';
    }
    if (allowGetter) {
      codeList.add('[Route("$apiPrefix")]');
      //Authorization
      if (authorizeAttrGet.isNotEmpty) {
        codeList.add(authorizeAttrGet);
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

      final needUser =
          controller.useAuthorization && effectiveAuthorizeGet != 'none';
      if (needUser) {
        codeList.add('var user = ${controller.callGetUserByToken};');
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
      if (authorizeAttrCreate.isNotEmpty) {
        codeList.add(authorizeAttrCreate);
      }
      codeList.add('[HttpPost]');
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${name}Create([FromBody] NsgFindParams findParams)');
      codeList.add('{');

      final needUser =
          controller.useAuthorization && effectiveAuthorizeCreate != 'none';
      if (needUser) {
        codeList.add('var user = ${controller.callGetUserByToken};');
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
      codeList.add('[Route("$apiPrefix/Post")]');
      //Authorization
      if (authorizeAttrPost.isNotEmpty) {
        codeList.add(authorizeAttrPost);
      }
      codeList.add('[HttpPost]');
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add('{');

      final needUser =
          controller.useAuthorization && effectiveAuthorizePost != 'none';
      if (needUser) {
        codeList.add('var user = ${controller.callGetUserByToken};');
        codeList.add(
            'return await controller.Post<${genDataItem.typeName}>(user, NsgFindParams.From(Request.GetQueryNameValuePairs(), threadId), items);');
      } else {
        codeList.add(
            'return await controller.Post<${genDataItem.typeName}>(null, NsgFindParams.From(Request.GetQueryNameValuePairs(), threadId), items);');
      }
      codeList.add('}');
      codeList.add('');
    }

    //Generate delete data method
    if (allowDelete) {
      codeList.add('[Route("$apiPrefix/Delete")]');
      //Authorization
      if (authorizeAttrDelete.isNotEmpty) {
        codeList.add(authorizeAttrDelete);
      }
      codeList.add('[HttpPost]');
      // codeList.add(
      //     'public async Task<IEnumerable<${genDataItem.typeName}>> ${name}Post([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${name}Delete([FromBody] IEnumerable<${genDataItem.typeName}> items)');
      codeList.add('{');

      final needUser =
          controller.useAuthorization && effectiveAuthorizeDelete != 'none';
      if (needUser) {
        codeList.add('var user = ${controller.callGetUserByToken};');
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

    //   if (nsgGenerator.isDotNetCore) {
    //     codeList.add(
    //         'public async Task<FileStreamResult> ${name}${element.apiPrefix}([FromRoute] string file)');
    //   } else {
    //     codeList.add(
    //         'public async Task<FileStreamResult> ${name}${element.apiPrefix}(string file)');
    //   }
    //   codeList.add('{');
    //   if (authorize != 'none') {
    //     codeList
    //         .add('var user = ${controller.callGetUserByToken};');
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
