import 'misc.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenFunction {
  final String name;
  final String apiType;
  final bool httpGet;
  final bool httpPost;
  final String description;
  final String apiPrefix;
  final String authorize;
  final String type;
  final String referenceType;
  final bool isReference;
  final bool isNullable;
  final bool useProgressDialog;
  final int retryCount;
  final String dialogText;
  final List<String> readReferences;
  final List<NsgGenMethodParam> params;

  NsgGenFunction(
      {required this.name,
      required this.apiType,
      required this.httpGet,
      required this.httpPost,
      this.description = '',
      this.apiPrefix = '',
      required this.authorize,
      required this.type,
      this.referenceType = '',
      this.isReference = false,
      this.isNullable = true,
      this.useProgressDialog = false,
      this.retryCount = 3,
      this.dialogText = '',
      this.readReferences = const [],
      this.params = const []});

  static Map<String, String> obsoleteKeys = {
    'api_prefix': 'apiPrefix',
    'referenceName': '',
    'httpGet': 'apiType = \'get, post\'',
    'httpPost': 'apiType = \'get, post\'',
  };

  factory NsgGenFunction.fromJson(Map<String, dynamic> parsedJson) {
    Misc.checkObsoleteKeysInJSON('function', parsedJson, obsoleteKeys,
        throwIfAny: true);
    var name = parsedJson['name'] ?? '';
    try {
      var httpGet = Misc.parseBool(parsedJson['httpGet']);
      var httpPost = Misc.parseBool(parsedJson['httpPost']);
      var apiType = parsedJson['apiType'];
      if (apiType != null) {
        apiType = apiType.toString().toLowerCase();
        httpGet |= apiType.toString().contains('get');
        httpPost |= apiType.toString().contains('post');
      }
      if (!httpGet && !httpPost) {
        httpPost = true;
        apiType = 'post';
      }
      if (apiType == null || apiType == '') {
        if (httpGet && httpPost)
          apiType = 'get, post';
        else if (httpGet)
          apiType = 'get';
        else if (httpPost) apiType = 'post';
      }
      var type = (parsedJson['type'] ?? '').toString();
      if (type.startsWith('String<')) {
        type = 'String';
      }
      bool isReference = Misc.needToSpecifyType(type);
      var referenceType = (parsedJson['referenceType'] ?? '').toString();
      if (referenceType.isEmpty &&
          type != 'List<Reference>' &&
          type != 'List<Enum>' &&
          (type.startsWith('List<') ||
              type.startsWith('Enum<') ||
              type.startsWith('Reference<')) &&
          type.endsWith('>')) {
        referenceType =
            type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
        if (referenceType.contains('<') && referenceType.endsWith('>')) {
          referenceType = referenceType.substring(
              referenceType.indexOf('<') + 1, referenceType.lastIndexOf('>'));
        }
      }
      isReference = !Misc.isPrimitiveType(type);

      var retryCount = parsedJson['retryCount'] ?? 3;
      if (retryCount is String) retryCount = int.parse(retryCount);
      return NsgGenFunction(
          name: name,
          apiType: apiType,
          httpGet: httpGet,
          httpPost: httpPost,
          description: parsedJson['description'] ?? '',
          apiPrefix: parsedJson.containsKey('apiPrefix')
              ? parsedJson['apiPrefix']
              : parsedJson['name'],
          authorize: parsedJson['authorize'] ?? 'none',
          type: parsedJson['type'] ?? '',
          referenceType: referenceType,
          isReference: isReference,
          isNullable: Misc.parseBoolOrTrue(parsedJson['isNullable']),
          useProgressDialog:
              Misc.parseBoolOrTrue(parsedJson['useProgressDialog']),
          retryCount: retryCount,
          dialogText: parsedJson['dialogText'] ?? '',
          readReferences: parsedJson.containsKey('readReferences')
              ? (parsedJson['readReferences'] as List)
                  .map((i) => i.toString())
                  .toList()
              : const [],
          params: parsedJson.containsKey('params')
              ? (parsedJson['params'] as List)
                  .map((i) => NsgGenMethodParam.fromJson(i))
                  .toList()
              : const []);
    } catch (e) {
      print('--- ERROR parsing function \'$name\' ---');
      rethrow;
    }
  }

  String get dartName => Misc.getDartName(name);

  String get returnType {
    if (Misc.needToSpecifyType(type)) {
      return referenceType;
    }
    return type;
  }

  String get dartType {
    if (type == 'Guid') return 'String';
    return returnType;
  }

  String get primType {
    var primType = type;
    if (primType.startsWith('Enum') || primType.contains('Enum<')) {
      return 'int';
    }
    return primType;
  }

  void writeMethod(NsgGenController nsgGenController, List<String> codeList) {
    if (description.isNotEmpty) {
      Misc.writeDescription(codeList, description, false);
    }
    var paramTNString = '';
    var paramNString = '';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += p.returnType + ' ' + p.name + ', ';
        paramNString += p.name + ', ';
      });
    }
    if (paramTNString.isNotEmpty) {
      paramTNString = paramTNString.substring(0, paramTNString.length - 2);
      paramNString = paramNString.substring(0, paramNString.length - 2);
    }
    // if (type == null) {
    //   codeList.add('void $dartName($paramTNString) { }');
    // } else
    if (type == 'String') {
      codeList.add('$dartType $dartName($paramTNString) => \'\';');
    } else if (type == 'Guid') {
      codeList.add(
          '$dartType $dartName($paramTNString) => \'00000000-0000-0000-0000-000000000000\';');
    } else if (type == 'DateTime') {
      codeList.add('$dartType $dartName($paramTNString) => $dartType();');
    } else if (type == 'Duration') {
      codeList.add('$dartType $dartName($paramTNString)=> $dartType();');
    } else if (type == 'int') {
      codeList.add('$dartType $dartName($paramTNString) => 0;');
    } else if (type == 'bool') {
      codeList.add('$dartType $dartName($paramTNString) => false;');
    } else if (type == 'double') {
      codeList.add('$dartType $dartName($paramTNString) => 0;');
    } else if (['Image', 'Binary'].contains(type)) {
      codeList.add('List<int> $dartName($paramTNString) => [];');
    } else if (type.startsWith('List')) {
      codeList.add('List<$dartType> $dartName($paramTNString) => [];');
    } else if (isReference) {
      codeList.add('String $dartName($paramTNString) => \'\';');
    } else {
      var message = "write getter for method type $type couldn't be found";
      print(message);
      throw Exception(message);
    }
    codeList.add('');
  }

  Future generateControllerMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramNString = controller.useAuthorization && authorize != 'none'
        ? 'user, findParams'
        : 'null, findParams';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramNString += ', ' + p.name;
      });
    }
    Misc.writeDescription(codeList, description, true);
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
    if (httpGet) codeList.add('[HttpGet]');
    if (httpPost) codeList.add('[HttpPost]');
    if (isReference) {
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> $name([FromBody] NsgFindParams findParams)');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      var uriParamNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += ', [FromUri] ${p.returnType} ${p.name}';
          uriParamNString += ', ${p.name}';
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString = 'HttpRequestMessage requestMessage';
        uriParamNString = controller.useAuthorization && authorize != 'none'
            ? 'user, requestMessage'
            : 'null, requestMessage';
      } else {
        uriParamTNString = uriParamTNString.substring(2);
        uriParamNString = uriParamNString.substring(2);
      }
      paramNString = uriParamNString;
      codeList.add(
          'public async Task<HttpResponseMessage> $name($uriParamTNString)');
    } else {
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<$primType>>> $name([FromBody] NsgFindParams findParams)');
    }
    codeList.add('{');
    if (controller.useAuthorization && authorize != 'none') {
      codeList.add('var user = await authController.GetUserByToken(Request);');
    }
    if (params.isNotEmpty && !(['Image', 'Binary'].contains(type))) {
      params.forEach((p) {
        if (p.type == 'DateTime') {
          codeList
              .add('if (!findParams.Parameters.ContainsKey("${p.name}") ||');
          codeList.add(
              '    !DateTime.TryParse(findParams.Parameters["${p.name}"].ToString(), out DateTime ${p.name}))');
          codeList.add('    ${p.name} = DateTime.Now;');
          return;
        }
        //if (!body.ContainsKey("date") || !DateTime.TryParse(body["date"].ToString(), out DateTime date)) date = DateTime.Now;
        var pStr = ['${p.returnType} ${p.name} = '];
        if (p.type == 'String') {
          pStr[0] += 'findParams.Parameters["${p.name}"].ToString();';
        } else if (['int', 'double'].contains(p.type)) {
          pStr[0] +=
              'findParams.Parameters["${p.name}"] is ${p.type} _${p.name}_ ? _${p.name}_ :';
          pStr.add(
              '    ${p.type}.Parse(findParams.Parameters["${p.name}"].ToString(), System.Globalization.CultureInfo.InvariantCulture);');
        } else if (p.type == 'bool') {
          pStr[0] +=
              '${p.type}.Parse(findParams.Parameters["${p.name}"].ToString());';
        } else if (p.type.startsWith('List')) {
          pStr[0] +=
              '(findParams.Parameters["${p.name}"] as Newtonsoft.Json.Linq.JArray)?.ToObject<${p.returnType}>() ?? new ${p.returnType}();';
        } else if (p.type.startsWith('Enum')) {
          pStr[0] +=
              '(${p.returnType})(findParams.Parameters["${p.name}"] is int _${p.name}_ ? _${p.name}_ :';
          pStr.add(
              '    int.Parse(findParams.Parameters["${p.name}"].ToString(), System.Globalization.CultureInfo.InvariantCulture));');
          // pStr[0] +=
          //     '(findParams.Parameters["${p.name}"] as Newtonsoft.Json.Linq.JObject)?.ToObject<${p.returnType}>() ?? (${p.returnType})0;';
        } else {
          pStr[0] +=
              '(findParams.Parameters["${p.name}"] as Newtonsoft.Json.Linq.JObject)?.ToObject<${p.returnType}>() ?? new ${p.returnType}();';
        }
        codeList.addAll(pStr);
      });
    }
    codeList.add('return await controller.$name($paramNString);');
    codeList.add('}');
    codeList.add('');
  }

  Future generateControllerInterfaceMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramTNString = 'INsgTokenExtension user, NsgFindParams findParams';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += ', ' + p.returnType + ' ' + p.name;
      });
    }
    if (isReference) {
      codeList.add(
          'Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> $name($paramTNString);');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += ', [FromUri] ${p.returnType} ${p.name}';
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString =
            'INsgTokenExtension user, System.Net.Http.HttpRequestMessage requestMessage';
      } else {
        uriParamTNString = uriParamTNString.substring(2);
      }
      codeList.add(
          'Task<System.Net.Http.HttpResponseMessage> $name($uriParamTNString);');
    } else {
      codeList.add(
          'Task<Dictionary<string, IEnumerable<$primType>>> $name($paramTNString);');
    }
    codeList.add('');
  }

  void generateControllerImplDesignerMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramTNString = 'INsgTokenExtension user, NsgFindParams findParams';
    var paramNString = 'user, findParams';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += ', ' + p.returnType + ' ' + p.name;
        paramNString += ', ' + p.name;
      });
    }
    if (isReference) {
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> $name($paramTNString)');
      codeList.add(
          '    => NsgServerMetadataItem.GetDictWithNestedFields<$returnType>(');
      codeList.add('        await On$name($paramNString), findParams);');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      var uriParamNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += ', ${p.returnType} ${p.name}';
          uriParamNString += ', ${p.name}';
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString =
            'INsgTokenExtension user, System.Net.Http.HttpRequestMessage requestMessage';
        uriParamNString = 'user, requestMessage';
      } else {
        uriParamTNString = uriParamTNString.substring(2);
        uriParamNString = uriParamNString.substring(2);
      }
      codeList.add(
          'public async Task<System.Net.Http.HttpResponseMessage> $name($uriParamTNString)');
      codeList.add('    => await On$name($uriParamNString);');
    } else {
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<$primType>>> $name($paramTNString)');
      codeList.add('    => await On$name($paramNString);');
    }
  }

  Future generateControllerImplMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramTNString = 'INsgTokenExtension user, NsgFindParams findParams';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += ', ' + p.returnType + ' ' + p.name;
      });
    }
    if (isReference) {
      codeList.add(
          'public async Task<IEnumerable<$returnType>> On$name($paramTNString)');
      codeList.add('{');
      codeList.add('throw new NotImplementedException();');
      codeList.add('}');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += ', ${p.returnType} ${p.name}';
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString =
            'INsgTokenExtension user, HttpRequestMessage requestMessage';
      } else {
        uriParamTNString = uriParamTNString.substring(2);
      }
      codeList.add(
          'public async Task<HttpResponseMessage> On$name($uriParamTNString)');
      codeList.add('{');
      codeList.add(
          'HttpResponseMessage response = new HttpResponseMessage(HttpStatusCode.OK);');
      codeList.add(
          '//response.Content = new StreamContent(new FileStream(fileName, FileMode.Open, FileAccess.Read));');
      codeList.add(
          '//response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment");');
      codeList.add(
          '//response.Content.Headers.ContentDisposition.FileName = fileName;');
      codeList.add(
          '//response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");');
      codeList.add('');
      codeList.add('return response;');
      codeList.add('}');
    } else {
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<$primType>>> On$name($paramTNString)');
      codeList.add('{');
      codeList
          .add('var RES = new Dictionary<string, IEnumerable<$primType>>();');
      codeList.add('');
      codeList.add('var res = new $primType[0];');
      codeList.add('RES[NsgServerDataItem.RESULTS] = res;');
      codeList.add('return RES;');
      codeList.add('}');
    }
  }

  Future generateCodeDart(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller) async {
    if (description.isNotEmpty) {
      Misc.writeDescription(codeList, description, false, indent: 2);
    }
    var paramTNString = ''; //NsgDataRequestParams? filter';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += p.returnType + ' ' + p.name + ', ';
      });
    }
    if (useProgressDialog) {
      var dlg = dialogText.isEmpty ? '' : ' = \'$dialogText\'';
      paramTNString +=
          '{NsgDataRequestParams? filter, bool showProgress = false, bool isStoppable = false, String? textDialog$dlg}';
    } else {
      paramTNString += '{NsgDataRequestParams? filter}';
    }

    // if (type.startsWith('List') && isReference) {
    //   codeList.add(
    //       '  Future<List<$dartType>> $dartName($paramTNString) async {');
    // } else
    if (isReference && !type.startsWith('List')) {
      String functionType = dartType;
      if (isNullable) functionType += '?';
      codeList.add('  Future<$functionType> $dartName($paramTNString) async {');
    } else {
      codeList
          .add('  Future<List<$dartType>> $dartName($paramTNString) async {');
    }
    var _ = '';
    if (useProgressDialog) {
      codeList.add(
          '    var progress = NsgProgressDialogHelper(showProgress: showProgress, isStoppable: isStoppable, textDialog: textDialog);');
      codeList.add('    try {');
      _ = '  ';
    }
    codeList.add('$_    var params = <String, dynamic>{};');
    if (params.isNotEmpty) {
      params.forEach((p) {
        if (p.type == 'String') {
          codeList.add('$_    params[\'${p.name}\'] = ${p.name};');
        } else if (p.type == 'DateTime') {
          codeList.add(
              '$_    params[\'${p.name}\'] = ${p.name}.toIso8601String();');
        } else if (p.type.startsWith('List')) {
          if (p.isReference) {
            codeList.add(
                '$_    params[\'${p.name}\'] = ${p.name}.map((obj) => obj.toJson()).toList();');
          } else {
            codeList.add('$_    params[\'${p.name}\'] = ${p.name};');
          }
        } else if (p.isReference) {
          codeList.add('$_    params[\'${p.name}\'] = ${p.name}.toJson();');
        } else if (p.type.startsWith('Enum')) {
          codeList.add('$_    params[\'${p.name}\'] = ${p.name}.value;');
        } else {
          codeList.add('$_    params[\'${p.name}\'] = ${p.name}.toString();');
        }
      });
    }
    codeList.add('$_    filter ??= NsgDataRequestParams();');
    codeList.add('$_    filter.params?.addAll(params);');
    codeList.add('$_    filter.params ??= params;');
    if (readReferences.isNotEmpty) {
      codeList.add('$_    var loadReference = [');
      readReferences.forEach((s) {
        if (s.contains('\$')) {
          codeList.add('$_      \'${s}\',');
        } else {
          codeList.add('$_      ${s},');
        }
      });
      codeList.add('$_    ];');
    }
    if (isReference) {
      if (type.startsWith('List')) {
        codeList.add(
            '$_    var res = await NsgDataRequest<$dartType>().requestItems(');
      } else {
        codeList.add(
            '$_    var res = await NsgDataRequest<$dartType>().requestItem(');
      }
    } else /*if (type.startsWith('List'))*/ {
      codeList.add(
          '$_    var res = await NsgSimpleRequest<$dartType>().requestItems(');
      codeList.add('$_        provider: provider!,');
      // } else {
      //   codeList.add(
      //       '      var res = await NsgSimpleRequest<$dartType>().requestItem(');
    }
    codeList
        .add('$_        function: \'/${controller.apiPrefix}/$apiPrefix\',');
    codeList.add('$_        method: \'${apiType.toUpperCase()}\',');
    codeList.add('$_        filter: filter,');
    codeList.add('$_        autoRepeate: ${retryCount > 0},');
    var endParam = '$_        autoRepeateCount: $retryCount';
    if (useProgressDialog) {
      codeList.add('$endParam,');
      endParam = '$_        cancelToken: progress.cancelToken';
    }
    if (readReferences.isNotEmpty) {
      codeList.add('$endParam,');
      endParam = '$_        loadReference: loadReference';
    }
    codeList.add('$endParam);');
    codeList.add('$_    return res;');
    // codeList.add('    } catch (e) {');
    // if (type == 'List<Reference>') {
    //   codeList.add('      return [];');
    // } else if (type == 'Reference') {
    //   codeList.add('      return null;');
    // } else {
    //   codeList.add('      return <$dartType>[];');
    // }
    if (useProgressDialog) {
      codeList.add('    } finally {');
      codeList.add('      progress.hide();');
      codeList.add('    }');
    }
    codeList.add('  }');
  }
}

class NsgGenMethodParam {
  final String name;
  final String type;
  final String referenceType;
  final bool isReference;

  NsgGenMethodParam(
      {required this.name,
      required this.type,
      this.referenceType = '',
      this.isReference = false});

  factory NsgGenMethodParam.fromJson(Map<String, dynamic> parsedJson) {
    var name = parsedJson['name'];
    try {
      var type = (parsedJson['type'] ?? '').toString();
      if (type.startsWith('String<')) {
        type = 'String';
      }
      bool isReference = Misc.needToSpecifyType(type);
      var referenceType = (parsedJson['referenceType'] ?? '').toString();
      if (type == 'Date') type = 'DateTime';
      if (referenceType.isEmpty &&
          type != 'List<Reference>' &&
          type != 'List<Enum>' &&
          (type.startsWith('List<') ||
              type.startsWith('Enum<') ||
              type.startsWith('Reference<')) &&
          type.endsWith('>')) {
        referenceType =
            type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
        if (referenceType.contains('<') && referenceType.endsWith('>')) {
          referenceType = referenceType.substring(
              referenceType.indexOf('<') + 1, referenceType.lastIndexOf('>'));
        }
      }
      isReference = !Misc.isPrimitiveType(type);
      return NsgGenMethodParam(
          name: parsedJson['name'],
          type: type,
          referenceType: referenceType,
          isReference: isReference);
    } catch (e) {
      print('--- ERROR parsing function param \'$name\' ---');
      rethrow;
    }
  }

  String get returnType {
    if (type.startsWith('Reference') || type.startsWith('Enum')) {
      return referenceType;
    }
    if (type.startsWith('List')) {
      return 'List<$referenceType>';
    }
    return type;
  }
}
