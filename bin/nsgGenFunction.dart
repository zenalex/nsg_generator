import 'misc.dart';
import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenFunction {
  final String name;
  final String apiType;
  final String description;
  final String apiPrefix;
  final String authorize;
  final String type;
  final String referenceName;
  final String referenceType;
  final List<NsgGenMethodParam> params;

  NsgGenFunction(
      {required this.name,
      required this.apiType,
      this.description = '',
      this.apiPrefix = '',
      required this.authorize,
      required this.type,
      this.referenceName = '',
      this.referenceType = '',
      this.params = const []});

  factory NsgGenFunction.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenFunction(
        name: parsedJson['name'] ?? '',
        apiType: (parsedJson['apiType'] ?? 'post').toLowerCase(),
        description: parsedJson['description'] ?? '',
        apiPrefix: parsedJson.containsKey('apiPrefix')
            ? parsedJson['apiPrefix']
            : parsedJson.containsKey('api_prefix')
                ? parsedJson['api_prefix']
                : parsedJson['name'],
        authorize: parsedJson['authorize'] ?? 'none',
        type: parsedJson['type'] ?? '',
        referenceName: parsedJson['referenceName'] ?? '',
        referenceType: parsedJson['referenceType'] ?? '',
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
    var paramNString =
        controller.useAuthorization ? 'user, findParams' : 'null, findParams';
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
    var httpApiType = 'HttpPost';
    if (apiType == 'get') httpApiType = 'HttpGet';
    codeList.add('[$httpApiType]');
    if (['Reference', 'List<Reference>'].contains(type)) {
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
    if (controller.useAuthorization) {
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
        var pStr = '${p.returnType} ${p.name} = ';
        if (p.type == 'String') {
          pStr += 'findParams.Parameters["${p.name}"].ToString()';
        } else if (['int', 'double', 'DateTime'].contains(p.type)) {
          pStr +=
              '${p.type}.Parse(findParams.Parameters["${p.name}"].ToString(), System.Globalization.CultureInfo.InvariantCulture)';
        } else if (p.type == 'bool') {
          pStr +=
              '${p.type}.Parse(findParams.Parameters["${p.name}"].ToString())';
        } else {
          pStr +=
              '(findParams.Parameters["${p.name}"] as Newtonsoft.Json.Linq.JObject)?.ToObject<${p.returnType}>() ?? new ${p.returnType}()';
        }
        codeList.add(pStr + ';');
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
          'public Task<Dictionary<string, IEnumerable<$primType>>> On$name($paramTNString)');
      codeList.add('{');
      codeList
          .add('var RES = new Dictionary<string, IEnumerable<$primType>>();');
      codeList.add('');
      codeList.add('var res = new $primType[0];');
      codeList.add('RES[RESULTS] = res;');
      codeList.add('return RES;');
      codeList.add('}');
    }
  }

  Future generateCodeDart(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller) async {
    if (description.isNotEmpty) {
      Misc.writeDescription(codeList, description, false);
    }
    var paramTNString = ''; //NsgDataRequestParams? filter';
    if (params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += p.returnType + ' ' + p.name + ', ';
      });
    }
    paramTNString +=
        '{NsgDataRequestParams? filter, bool showProgress = false, bool isStoppable = false}';

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
        '  var progress = NsgProgressDialogHelper(showProgress: showProgress, isStoppable: isStoppable);');
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
        } else if (p.type.startsWith('List<')) {
          codeList.add(
              '      params[\'${p.name}\'] = ${p.name}.map((obj) => obj.toJson());');
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

  NsgGenMethodParam(
      {required this.name, required this.type, this.referenceType = ''});

  factory NsgGenMethodParam.fromJson(Map<String, dynamic> parsedJson) {
    var type = (parsedJson['type'] ?? '').toString();
    if (type == 'Date') type = 'DateTime';
    return NsgGenMethodParam(
        name: parsedJson['name'],
        type: type,
        referenceType: parsedJson['referenceType'] ?? '');
  }

  String get returnType {
    if (type == 'Reference') {
      return referenceType;
    }
    if (type == 'List<Reference>') {
      return 'List<$referenceType>';
    }
    return type;
  }
}
