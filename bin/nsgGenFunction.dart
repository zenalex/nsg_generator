import 'nsgGenController.dart';
import 'nsgGenerator.dart';

class NsgGenFunction {
  final String name;
  final String type;
  final String description;
  final String apiPrefix;
  final String authorize;
  final String referenceName;
  final String referenceType;
  final List<NsgGenMethodParam> params;

  NsgGenFunction(
      {this.name,
      this.type,
      this.description,
      this.apiPrefix,
      this.authorize,
      this.referenceName,
      this.referenceType,
      this.params});

  factory NsgGenFunction.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenFunction(
        name: parsedJson['name'],
        type: parsedJson['type'],
        description: parsedJson['description'],
        apiPrefix: parsedJson['api_prefix'],
        authorize: parsedJson['authorize'] ?? 'none',
        referenceName: parsedJson['referenceName'],
        referenceType: parsedJson['referenceType'],
        params: parsedJson.containsKey('params')
            ? (parsedJson['params'] as List)
                .map((i) => NsgGenMethodParam.fromJson(i))
                .toList()
            : null);
  }

  String get dartName => NsgGenerator.generator.getDartName(name);

  String get returnType {
    if (type == 'Reference' || type == 'List<Reference>' || type == 'Enum') {
      return referenceType;
    } else if (type == 'Date') {
      return 'DateTime';
    }
    return type;
  }

  String get dartType {
    if (type == 'Reference' || type == 'List<Reference>' || type == 'Enum') {
      return referenceType;
    }
    if (type == 'Date') return 'DateTime';
    if (type == 'Guid') return 'String';
    return type;
  }

  String get nsgDataType {
    if (type == 'String' || type == 'Guid') {
      return 'NsgDataStringField';
    } else if (type == 'Date' || type == 'DateTime') {
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
      return 'NsgDataReferenceField<$referenceType>';
    } else if (type == 'List<Reference>') {
      return 'NsgDataReferenceListField<$referenceType>';
    } else {
      print("get nsgDataType for field type $type couldn't be found");
      throw Exception();
    }
  }

  void writeMethod(NsgGenController nsgGenController, List<String> codeList) {
    if (description != null && description.isNotEmpty) {
      description.split('\n').forEach((descLine) {
        codeList.add('/// $descLine');
      });
    }
    var paramTNString = '';
    var paramNString = '';
    if (params != null && params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += p.returnType + ' ' + p.name + ', ';
        paramNString += p.name + ', ';
      });
    }
    if (paramTNString.isNotEmpty) {
      paramTNString = paramTNString.substring(0, paramTNString.length - 2);
      paramNString = paramNString.substring(0, paramNString.length - 2);
    }
    if (type == null) {
      codeList.add('void $dartName($paramTNString) { }');
    } else if (type == 'String') {
      codeList.add('$dartType $dartName($paramTNString) => \'\';');
    } else if (type == 'Guid') {
      codeList.add(
          '$dartType $dartName($paramTNString) => \'00000000-0000-0000-0000-000000000000\';');
    } else if (type == 'Date' || type == 'DateTime') {
      codeList.add('$dartType $dartName($paramTNString) => $dartType();');
    } else if (type == 'Duration') {
      codeList.add('$dartType $dartName($paramTNString)=> $dartType();');
    } else if (type == 'int') {
      codeList.add('$dartType $dartName($paramTNString) => 0;');
    } else if (type == 'bool') {
      codeList.add('$dartType $dartName($paramTNString) => false;');
    } else if (type == 'double') {
      codeList.add('$dartType $dartName($paramTNString) => 0;');
    } else if (type == 'Image') {
      codeList.add('String $dartName($paramTNString) => \'\';');
    } else if (type == 'Reference') {
      codeList.add('String $dartName($paramTNString) => \'\';');
    } else {
      print("write getter for method type $type couldn't be found");
      throw Exception();
    }
    codeList.add('');
  }

  void generateControllerMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramNString =
        controller.useAuthorization ? 'user, findParams' : 'null, findParams';
    if (params != null && params.isNotEmpty) {
      params.forEach((p) {
        paramNString += ', ' + p.name;
      });
    }
    codeList.add('/// <summary>');
    codeList.add('/// $description');
    codeList.add('/// </summary>');
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
    var apiType = 'HttpPost';
    if (type == 'get') apiType = 'HttpGet';
    codeList.add('[$apiType]');
    codeList.add(
        'public async Task<IEnumerable<$returnType>> $name([FromBody] NsgFindParams findParams)');
    codeList.add('{');
    if (controller.useAuthorization) {
      codeList.add('var user = await authController.GetUserByToken(Request);');
    }
    params.forEach((p) {
      if (p.type == 'Date' || p.type == 'DateTime') {
        codeList.add('if (!findParams.Parameters.ContainsKey("${p.name}") ||');
        codeList.add(
            '    !DateTime.TryParse(findParams.Parameters["${p.name}"].ToString(), out DateTime ${p.name}))');
        codeList.add('    ${p.name} = DateTime.Now;');
        return;
      }
      //if (!body.ContainsKey("date") || !DateTime.TryParse(body["date"].ToString(), out DateTime date)) date = DateTime.Now;
      var pStr = '${p.returnType} ${p.name} = ';
      if (p.type == 'String') {
        pStr += 'findParams.Parameters["${p.name}"].ToString()';
      } else if (p.type == 'int' || p.type == 'double') {
        pStr +=
            '${p.type}.Parse(findParams.Parameters["${p.name}"].ToString(), System.Globalization.CultureInfo.InvariantCulture)';
      } else {
        pStr +=
            '(findParams.Parameters["${p.name}"] as Newtonsoft.Json.Linq.JObject)?.ToObject<${p.returnType}>() ?? new ${p.returnType}()';
      }
      codeList.add(pStr + ';');
    });
    codeList.add('return await controller.$name($paramNString);');
    codeList.add('}');
  }

  void generateControllerInterfaceMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramTNString = 'INsgTokenExtension user, NsgFindParams findParams';
    if (params != null && params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += ', ' + p.returnType + ' ' + p.name;
      });
    }
    codeList.add('Task<IEnumerable<$returnType>> $name($paramTNString);');
  }

  void generateControllerImplDesignerMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramTNString = 'INsgTokenExtension user, NsgFindParams findParams';
    var paramNString = 'user, findParams';
    if (params != null && params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += ', ' + p.returnType + ' ' + p.name;
        paramNString += ', ' + p.name;
      });
    }
    codeList.add('public Task<IEnumerable<$returnType>> $name($paramTNString)');
    codeList.add('    => On$name($paramNString);');
  }

  void generateControllerImplMethod(List<String> codeList,
      NsgGenerator nsgGenerator, NsgGenController controller) async {
    var paramTNString = 'INsgTokenExtension user, NsgFindParams findParams';
    if (params != null && params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += ', ' + p.returnType + ' ' + p.name;
      });
    }
    codeList
        .add('public Task<IEnumerable<$returnType>> On$name($paramTNString)');
    codeList.add('{');
    codeList.add('throw new NotImplementedException();');
    codeList.add('}');
  }

  void generateCodeDart(List<String> codeList, NsgGenerator nsgGenerator,
      NsgGenController controller) async {
    var paramTNString = '';
    if (params != null && params.isNotEmpty) {
      params.forEach((p) {
        paramTNString += p.returnType + ' ' + p.name + ', ';
      });
    }
    if (paramTNString.isNotEmpty) {
      paramTNString = paramTNString.substring(0, paramTNString.length - 2);
    }

    if (type == 'List<Reference>') {
      codeList.add(
          '  Future<List<$dartType>?> ${nsgGenerator.getDartName(name)}($paramTNString) async {');
    } else {
      codeList.add(
          '  Future<$dartType?> ${nsgGenerator.getDartName(name)}($paramTNString) async {');
    }
    codeList.add('    var params = <String, String>{};');
    params.forEach((p) {
      if (p.type == 'String') {
        codeList.add('    params[\'${p.name}\'] = ${p.name};');
      } else if (p.type == 'Date' || p.type == 'DateTime') {
        codeList
            .add('    params[\'${p.name}\'] = ${p.name}.toIso8601String();');
      } else if (p.type == 'Reference') {
        codeList.add('    params[\'${p.name}\'] = ${p.name}.toJson();');
      } else if (p.type == 'Enum') {
        codeList.add('    params[\'${p.name}\'] = ${p.name}.value;');
      } else {
        codeList.add('    params[\'${p.name}\'] = ${p.name}.toString();');
      }
    });
    codeList.add('    final filter = NsgDataRequestParams(params: params);');
    codeList.add('    try {');
    if (type == 'List<Reference>') {
      codeList.add(
          '      var res = await NsgDataRequest<$dartType>().requestItems(');
    } else {
      codeList.add(
          '      var res = await NsgDataRequest<$dartType>().requestItem(');
    }
    codeList
        .add('          function: \'/${controller.api_prefix}/$apiPrefix\',');
    codeList.add('          method: \'POST\',');
    codeList.add('          filter: filter,');
    codeList.add('          autoRepeate: true,');
    codeList.add('          autoRepeateCount: 3);');
    codeList.add('      return res;');
    codeList.add('    } catch (e) {');
    codeList.add('      return null;');
    codeList.add('    }');
    codeList.add('  }');
  }
}

class NsgGenMethodParam {
  final String name;
  final String type;
  final String referenceType;

  NsgGenMethodParam({this.name, this.type, this.referenceType});

  factory NsgGenMethodParam.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenMethodParam(
        name: parsedJson['name'],
        type: parsedJson['type'],
        referenceType: parsedJson['referenceType']);
  }

  String get returnType {
    if (type == 'Reference') {
      return referenceType;
    }
    return type;
  }
}
