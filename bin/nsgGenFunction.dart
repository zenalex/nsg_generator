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
  final String referenceName;
  final String referenceType;
  final bool isReference;
  final String dialogText;
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
      this.referenceName = '',
      this.referenceType = '',
      this.isReference = false,
      this.dialogText = '',
      this.params = const []});

  factory NsgGenFunction.fromJson(Map<String, dynamic> parsedJson) {
    var httpGet =
        parsedJson.containsKey('httpGet') && parsedJson['httpGet'] == 'true';
    var httpPost =
        parsedJson.containsKey('httpPost') && parsedJson['httpPost'] == 'true';
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
    bool isReference = Misc.typesNeedingReferenceType.contains(type);
    var referenceType = (parsedJson['referenceType'] ?? '').toString();
    if (referenceType.isEmpty &&
        type != 'List<Reference>' &&
        (type.startsWith('List<') && type.endsWith('>'))) {
      referenceType =
          type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
      isReference = !Misc.primitiveTypes.contains(referenceType);
    }
    return NsgGenFunction(
        name: parsedJson['name'] ?? '',
        apiType: apiType,
        httpGet: httpGet,
        httpPost: httpPost,
        description: parsedJson['description'] ?? '',
        apiPrefix: parsedJson.containsKey('apiPrefix')
            ? parsedJson['apiPrefix']
            : parsedJson.containsKey('api_prefix')
                ? parsedJson['api_prefix']
                : parsedJson['name'],
        authorize: parsedJson['authorize'] ?? 'none',
        type: parsedJson['type'] ?? '',
        referenceName: parsedJson['referenceName'] ?? '',
        referenceType: referenceType,
        isReference: isReference,
        dialogText: parsedJson['dialogText'] ?? '',
        params: parsedJson.containsKey('params')
            ? (parsedJson['params'] as List)
                .map((i) => NsgGenMethodParam.fromJson(i))
                .toList()
            : []);
  }

  String get dartName => Misc.getDartName(name);

  String get returnType {
    if (type == 'Reference' || type == 'List<Reference>' || type == 'Enum') {
      return referenceType;
    }
    return type;
  }

  String get dartType {
    if (type == 'Reference' || type == 'List<Reference>' || type == 'Enum') {
      return referenceType;
    }
    if (type == 'Guid') return 'String';
    return type;
  }

  String get nsgDataType {
    if (type == 'String' || type == 'Guid') {
      return 'NsgDataStringField';
    } else if (type == 'DateTime') {
      return 'NsgDataDateField';
    } else if (type == 'int') {
      return 'NsgDataIntField';
    } else if (type == 'double') {
      return 'NsgDataDoubleField';
    } else if (type == 'bool') {
      return 'NsgDataBoolField';
    } else if (type == 'Image') {
      return 'NsgDataImageField';
    } else if (type == 'Binary') {
      return 'NsgDataBinaryField';
    } else if (type == 'Reference') {
      return 'NsgDataReferenceField<$referenceType>';
    } else if (type == 'List<Reference>') {
      return 'NsgDataReferenceListField<$referenceType>';
    } else {
      print("get nsgDataType for field type $type couldn't be found");
      throw Exception();
    }
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
    } else if (type == 'Reference') {
      codeList.add('String $dartName($paramTNString) => \'\';');
    } else {
      print("write getter for method type $type couldn't be found");
      throw Exception();
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
    if (type == 'Reference' || type.startsWith('List') && isReference) {
      codeList.add(
          'public async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> $name([FromBody] NsgFindParams findParams)');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      var uriParamNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += '[FromUri] ' + p.returnType + ' ' + p.name;
          uriParamNString += p.name;
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString = 'HttpRequestMessage requestMessage';
        uriParamNString = controller.useAuthorization && authorize != 'none'
            ? 'user, requestMessage'
            : 'null, requestMessage';
      }
      paramNString = uriParamNString;
      codeList.add(
          'public async Task<HttpResponseMessage> $name($uriParamTNString)');
    } else {
      var primType = type;
      if (type == 'Enum') {
        primType = 'int';
      }
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
    if (['Reference', 'List<Reference>'].contains(type)) {
      codeList.add(
          'Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> $name($paramTNString);');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += '[FromUri] ' + p.returnType + ' ' + p.name;
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString =
            'INsgTokenExtension user, System.Net.Http.HttpRequestMessage requestMessage';
      }
      codeList.add(
          'Task<System.Net.Http.HttpResponseMessage> $name($uriParamTNString);');
    } else {
      var primType = type;
      if (type == 'Enum') {
        primType = 'int';
      }
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
    if (['Reference', 'List<Reference>'].contains(type)) {
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
          uriParamTNString += p.returnType + ' ' + p.name;
          uriParamNString += p.name;
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString =
            'INsgTokenExtension user, System.Net.Http.HttpRequestMessage requestMessage';
        uriParamNString = 'user, requestMessage';
      }
      codeList.add(
          'public async Task<System.Net.Http.HttpResponseMessage> $name($uriParamTNString)');
      codeList.add('    => await On$name($uriParamNString);');
    } else {
      var primType = type;
      if (type == 'Enum') {
        primType = 'int';
      }
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
    if (['Reference', 'List<Reference>'].contains(type)) {
      codeList
          .add('public Task<IEnumerable<$returnType>> On$name($paramTNString)');
      codeList.add('{');
      codeList.add('throw new NotImplementedException();');
      codeList.add('}');
    } else if (['Image', 'Binary'].contains(type)) {
      var uriParamTNString = '';
      if (params.isNotEmpty) {
        for (var p in params) {
          uriParamTNString += p.returnType + ' ' + p.name;
        }
      }
      if (uriParamTNString.isEmpty) {
        uriParamTNString =
            'INsgTokenExtension user, HttpRequestMessage requestMessage';
      }
      codeList
          .add('public Task<HttpResponseMessage> On$name($uriParamTNString)');
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
      var primType = type;
      if (type == 'Enum') {
        primType = 'int';
      }
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
    var dlg = dialogText.isEmpty ? '' : ' = \'$dialogText\'';
    paramTNString +=
        '{NsgDataRequestParams? filter, bool showProgress = false, bool isStoppable = false, String? textDialog$dlg}';

    // if (type == 'List<Reference>') {
    //   codeList.add(
    //       '  Future<List<$dartType>> ${nsgGenerator.getDartName(name)}($paramTNString) async {');
    // } else
    if (type == 'Reference') {
      codeList.add(
          '  Future<$dartType?> ${Misc.getDartName(name)}($paramTNString) async {');
    } else {
      codeList.add(
          '  Future<List<$dartType>> ${Misc.getDartName(name)}($paramTNString) async {');
    }
    codeList.add(
        '    var progress = NsgProgressDialogHelper(showProgress: showProgress, isStoppable: isStoppable, textDialog: textDialog);');
    codeList.add('    try {');
    codeList.add('      var params = <String, dynamic>{};');
    if (params.isNotEmpty) {
      params.forEach((p) {
        if (p.type == 'String') {
          codeList.add('      params[\'${p.name}\'] = ${p.name};');
        } else if (p.type == 'DateTime') {
          codeList.add(
              '      params[\'${p.name}\'] = ${p.name}.toIso8601String();');
        } else if (p.type == 'Reference') {
          codeList.add('      params[\'${p.name}\'] = ${p.name}.toJson();');
        } else if (p.type.startsWith('List')) {
          codeList.add(
              '      params[\'${p.name}\'] = ${p.name}.map((obj) => obj.toJson()).toList();');
        } else if (p.type == 'Enum') {
          codeList.add('      params[\'${p.name}\'] = ${p.name}.value;');
        } else {
          codeList.add('      params[\'${p.name}\'] = ${p.name}.toString();');
        }
      });
    }
    codeList.add('      filter ??= NsgDataRequestParams();');
    codeList.add('      filter.params?.addAll(params);');
    codeList.add('      filter.params ??= params;');
    if (type == 'List<Reference>') {
      codeList.add(
          '      var res = await NsgDataRequest<$dartType>().requestItems(');
    } else if (type == 'Reference') {
      codeList.add(
          '      var res = await NsgDataRequest<$dartType>().requestItem(');
    } else /*if (type.startsWith('List'))*/ {
      codeList.add(
          '      var res = await NsgSimpleRequest<$dartType>().requestItems(');
      codeList.add('          provider: provider!,');
      // } else {
      //   codeList.add(
      //       '      var res = await NsgSimpleRequest<$dartType>().requestItem(');
    }
    codeList
        .add('          function: \'/${controller.apiPrefix}/$apiPrefix\',');
    codeList.add('          method: \'${apiType.toUpperCase()}\',');
    codeList.add('          filter: filter,');
    codeList.add('          autoRepeate: true,');
    codeList.add('          autoRepeateCount: 3,');
    codeList.add('          cancelToken: progress.cancelToken);');
    codeList.add('      return res;');
    // codeList.add('    } catch (e) {');
    // if (type == 'List<Reference>') {
    //   codeList.add('      return [];');
    // } else if (type == 'Reference') {
    //   codeList.add('      return null;');
    // } else {
    //   codeList.add('      return <$dartType>[];');
    // }
    codeList.add('    } finally {');
    codeList.add('      progress.hide();');
    codeList.add('    }');
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
    var type = (parsedJson['type'] ?? '').toString();
    bool isReference = Misc.typesNeedingReferenceType.contains(type);
    var referenceType = (parsedJson['referenceType'] ?? '').toString();
    if (type == 'Date') type = 'DateTime';
    if (referenceType.isEmpty &&
        type != 'List<Reference>' &&
        (type.startsWith('List<') && type.endsWith('>'))) {
      referenceType =
          type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
      isReference = !Misc.primitiveTypes.contains(referenceType);
    }
    return NsgGenMethodParam(
        name: parsedJson['name'],
        type: type,
        referenceType: referenceType,
        isReference: isReference);
  }

  String get returnType {
    if (type == 'Reference') {
      return referenceType;
    }
    if (type.startsWith('List')) {
      return 'List<$referenceType>';
    }
    return type;
  }
}
