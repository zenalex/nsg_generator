import 'dart:io';
import 'dart:async';

import 'misc.dart';
import 'nsgGenDataItem.dart';
import 'nsgGenMethod.dart';
import 'nsgGenFunction.dart';
import 'nsgGenerator.dart';

class NsgGenController {
  final String apiPrefix;
  final String className;
  final String implControllerName;
  final String implAuthControllerName;
  final String dataType;
  final String serverUri;
  final bool useAuthorization;
  final bool useMetrics;
  final bool uploadEnabled;
  final bool loginRequired;
  final bool writeOnClient;
  final bool useGetUserByTokenSync;
  final List<NsgGenMethod> methods;
  final List<NsgGenFunction> functions;
  bool hasGetStreamFunction;
  String get callGetUserByToken => useGetUserByTokenSync
      ? "authController.GetUserByTokenSync(Request)"
      : "await authController.GetUserByToken(Request)";

  NsgGenController(
      {required this.apiPrefix,
      required this.className,
      required this.implControllerName,
      required this.implAuthControllerName,
      required this.dataType,
      required this.serverUri,
      this.useAuthorization = false,
      this.useMetrics = false,
      this.uploadEnabled = false,
      this.loginRequired = true,
      this.writeOnClient = true,
      this.useGetUserByTokenSync = false,
      this.methods = const [],
      this.functions = const [],
      this.hasGetStreamFunction = false});

  static Map<String, String> obsoleteKeys = {
    'class_name': 'className',
    'api_prefix': 'apiPrefix',
    'impl_controller_name': 'implControllerName',
    'impl_auth_controller_name': 'implAuthControllerName',
  };

  factory NsgGenController.fromJson(Map<String, dynamic> parsedJson) {
    Misc.checkObsoleteKeysInJSON('controller', parsedJson, obsoleteKeys,
        throwIfAny: true);
    var className = parsedJson['className'];
    var functions = parsedJson.containsKey('functions')
        ? (parsedJson['functions'] as List)
            .map((i) => NsgGenFunction.fromJson(i))
            .toList()
        : <NsgGenFunction>[];
    return NsgGenController(
        apiPrefix: parsedJson['apiPrefix'],
        className: className,
        implControllerName: parsedJson.containsKey('implControllerName')
            ? parsedJson['implControllerName']
            : className + 'Implementation',
        implAuthControllerName: parsedJson.containsKey('implAuthControllerName')
            ? parsedJson['implAuthControllerName']
            : 'AuthControllerImplementation',
        dataType: parsedJson['dataType'] ?? '',
        serverUri: parsedJson['serverUri'] ?? '',
        useAuthorization: Misc.parseBool(parsedJson['useAuthorization']),
        useMetrics: Misc.parseBool(parsedJson['useMetrics']),
        uploadEnabled: Misc.parseBool(parsedJson['uploadEnabled']),
        loginRequired: Misc.parseBoolOrTrue(parsedJson['loginRequired']),
        writeOnClient: Misc.parseBoolOrTrue(parsedJson['writeOnClient']),
        useGetUserByTokenSync:
            Misc.parseBool(parsedJson['useGetUserByTokenSync']),
        methods: parsedJson.containsKey('method')
            ? (parsedJson['method'] as List)
                .map((i) => NsgGenMethod.fromJson(i))
                .toList()
            : [],
        functions: functions,
        hasGetStreamFunction: functions.any((f) => f.name == "GetStream"));
  }

  Future generateCode(NsgGenerator nsgGenerator) async {
    var currentStage = 'code';
    try {
      if (nsgGenerator.doCSharp) {
        currentStage = 'C# controller $className';
        var codeList = <String>[];
        codeList.add('using Microsoft.Extensions.Logging;');
        codeList.add('using System;');
        codeList.add('using System.Collections.Generic;');
        codeList.add('using System.Linq;');
        codeList.add('using System.Net.Http;');
        codeList.add('using System.Threading;');
        codeList.add('using System.Threading.Tasks;');
        if (nsgGenerator.isDotNetCore) {
          codeList.add('using Microsoft.AspNetCore.Mvc;');
          codeList.add('using Microsoft.AspNetCore.Authorization;');
        } else {
          codeList.add('using System.Web.Http;');
          codeList.add('using System.Web.Http.Controllers;');
          codeList.add('using System.Web.Mvc;');
          codeList.add(
              'using HttpGetAttribute = System.Web.Http.HttpGetAttribute;');
          codeList.add(
              'using HttpPostAttribute = System.Web.Http.HttpPostAttribute;');
          codeList.add(
              'using HttpDeleteAttribute = System.Web.Http.HttpDeleteAttribute;');
          codeList.add(
              'using RoutePrefixAttribute = System.Web.Http.RoutePrefixAttribute;');
          codeList
              .add('using RouteAttribute = System.Web.Http.RouteAttribute;');
          codeList.add(
              'using FromBodyAttribute = System.Web.Http.FromBodyAttribute;');
          codeList.add(
              'using AuthorizeAttribute = System.Web.Http.AuthorizeAttribute;');
          codeList.add(
              'using ActionNameAttribute = System.Web.Http.ActionNameAttribute;');
        }
        codeList.add('using ${nsgGenerator.cSharpNamespace};');
        codeList.add('using ${nsgGenerator.cSharpNamespace}.Controllers;');
        codeList.add('using NsgServerClasses;');
        codeList.add('');
        codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
        codeList.add('{');
        Misc.writeDescription(
            codeList, '${dataType}Interface Controller', true);
        if (nsgGenerator.isDotNetCore) {
          codeList.add('[ApiController]');
          codeList.add('[Route("$apiPrefix")]');
        } else {
          codeList.add('[RoutePrefix("$apiPrefix")]');
        }
        codeList.add('public class $className : ' +
            (nsgGenerator.isDotNetCore ? 'ControllerBase' : 'ApiController'));
        codeList.add('{');

        codeList.add('${className}Interface controller;');
        codeList.add('AuthImplInterface authController;');

        codeList.add('private readonly ILogger<$className> _logger;');
        codeList.add('public $className(ILogger<$className> logger)');
        codeList.add('{');
        codeList.add('_logger = logger;');
        // codeList.add('#if (Real)');
        codeList.add('controller = new $implControllerName();');
        if (useAuthorization) {
          codeList.add('authController = new $implAuthControllerName();');
        } else {
          codeList.add('authController = AuthController.CurrentController;');
        }
        // codeList.add('#else');
        // codeList.add('controller = new ${implControllerName}Mock();');
        // if (useAuthorization) {
        //   codeList.add('authController = new ${implAuthControllerName}Mock();');
        // } else {
        //   codeList.add('authController = AuthController.CurrentController;');
        // }
        // codeList.add('#endif');
        codeList.add('}');
        codeList.add('');
        if (!nsgGenerator.isDotNetCore) {
          codeList.add(
              'public $className() : this(Program.LoggerFactory.CreateLogger<$className>()) { }');
          codeList.add('');
        }
        codeList.add('private static $className currentController;');
        codeList.add('public static $className getController');
        codeList.add('{');
        codeList.add('get');
        codeList.add('{');
        if (nsgGenerator.isDotNetCore) {
          codeList.add(
              'if (currentController == null) currentController = new $className(null);');
        } else {
          codeList.add(
              'if (currentController == null) currentController = new $className();');
        }
        codeList.add('return currentController;');
        codeList.add('}');
        codeList.add('}');
        codeList.add('public static AuthImplInterface getAuthController');
        codeList.add('{');
        codeList.add('get');
        codeList.add('{');
        codeList.add('return getController.authController;');
        codeList.add('}');
        codeList.add('}');
        codeList.add('');
        codeList.add('public void Init()');
        codeList.add('{');
        codeList.add('#region types');
        methods.forEach((el) {
          codeList.add(
              'NsgServerDataItem.Types.TryAdd("${Misc.getDartName(el.genDataItem.typeName)}", new ${el.genDataItem.typeName}());');
        });
        codeList.add('#endregion');
        codeList.add(
            'if (NsgServerClasses.AuthController.currentController == null)');
        codeList.add('{');
        if (useAuthorization) {
          codeList.add('authController = new $implAuthControllerName();');
        } else {
          codeList.add('authController = AuthController.CurrentController;');
        }
        codeList.add(
            'NsgServerClasses.AuthController.currentController = authController;');
        codeList.add('}');
        codeList.add('}');
        codeList.add('');
        await Future.forEach<NsgGenMethod>(methods, (element) async {
          currentStage = 'C# method ${element.name}';
          await element.generateCode(codeList, nsgGenerator, this);
        });

        await Future.forEach<NsgGenFunction>(functions, (element) async {
          currentStage = 'C# function ${element.name}';
          await element.generateControllerMethod(codeList, nsgGenerator, this);
        });
        currentStage = 'C# controller $className';

        codeList.add('}');
        codeList.add('}');
        Misc.indentCSharpCode(codeList);

        var fn = '${nsgGenerator.cSharpPath}/$className.cs';
        //if (!File(fn).existsSync()) {
        await File(fn).writeAsString(codeList.join('\r\n'));
        //}
        await generateInterfaceData(nsgGenerator);
        await generateImplController(nsgGenerator);
        if (useAuthorization) {
          await generateImplAuthController(nsgGenerator);
        }
      }
      if (nsgGenerator.doDart && this.writeOnClient) {
        currentStage = 'Dart code';
        await generateCodeDart(nsgGenerator);
      }
    } catch (e) {
      print('--- ERROR generating $currentStage ---');
      rethrow;
    }
  }

  Future generateInterfaceData(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Net;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.isDotNetCore) {
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public interface ${className}Interface');
    codeList.add('{');
    codeList.add(
        'Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Get<T>(INsgTokenExtension user, NsgFindParams findParams)');
    codeList.add('    where T : NsgServerDataItem, new();');
    codeList.add('');
    codeList.add(
        'Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Create<T>(INsgTokenExtension user, NsgFindParams findParams)');
    codeList.add('    where T : NsgServerDataItem, new();');
    codeList.add('');
    codeList.add(
        'Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Post<T>(INsgTokenExtension user, NsgFindParams findParams, IEnumerable<T> items)');
    codeList.add('    where T : NsgServerDataItem, new();');
    codeList.add('');
    codeList.add(
        'Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Delete<T>(INsgTokenExtension user, IEnumerable<T> items)');
    codeList.add('    where T : NsgServerDataItem, new();');
    //var publicMdf = (nsgGenerator.isDotNetCore ? 'public ' : '');
    methods.forEach((_) {
      // _.imageFieldList.forEach((el) {
      //   if (_.authorize != 'none') {
      //     codeList.add(
      //         '${publicMdf}Task<FileStreamResult> ${_.name}${el.apiPrefix}(INsgTokenExtension user, String file);');
      //   } else {
      //     codeList.add(
      //         '${publicMdf}Task<FileStreamResult> ${_.name}${el.apiPrefix}(INsgTokenExtension user, String file);');
      //   }
      // });
    });
    codeList.add('');
    await Future.forEach<NsgGenFunction>(functions, (element) async {
      await element.generateControllerInterfaceMethod(
          codeList, nsgGenerator, this);
    });
    codeList.add(
        'void ApplyServerFilter<T>(INsgTokenExtension user, ref NsgFindParams findParams) where T : NsgServerDataItem, new();');

    codeList.add('}');
    codeList.add('}');
    Misc.indentCSharpCode(codeList);
    var fn = '${nsgGenerator.cSharpPath}/${className}Interface.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\r\n'));
    //}
  }

  Future generateImplController(NsgGenerator nsgGenerator) async {
    // ${implControllerName}.Designer.cs
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.isDotNetCore) {
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    codeList.add('');
    codeList.add(
        '// --------------------------------------------------------------');
    codeList.add(
        '// This file is autogenerated. Manual changes will be overwritten');
    codeList.add(
        '// --------------------------------------------------------------');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList.add(
        'public partial class $implControllerName : ${className}Interface');
    codeList.add('{');
    codeList.add(
        'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Get<T>(INsgTokenExtension user, NsgFindParams findParams) where T : NsgServerDataItem, new()');
    codeList.add('{');
    codeList.add('ApplyServerFilter<T>(user, ref findParams);');
    codeList.add('return new T().Get(user, findParams);');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Create<T>(INsgTokenExtension user, NsgFindParams findParams) where T : NsgServerDataItem, new()');
    codeList.add('{');
    codeList.add('ApplyServerFilter<T>(user, ref findParams);');
    codeList.add('return new T().Create(user, findParams);');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Post<T>(INsgTokenExtension user, NsgFindParams findParams, IEnumerable<T> items) where T : NsgServerDataItem, new()');
    codeList.add('{');
    codeList.add('OnBeforePost(user, items);');
    codeList.add('return new T().Post(user, findParams, items);');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> Delete<T>(INsgTokenExtension user, IEnumerable<T> items) where T : NsgServerDataItem, new()');
    codeList.add('{');
    codeList.add('return new T().Delete(user, items);');
    codeList.add('}');
    codeList.add('');

    var hasMetadata = false;
    methods.forEach((m) {
      if (m.genDataItem.databaseType.isNotEmpty) {
        hasMetadata = true;
      }
      // m.imageFieldList.forEach((el) {
      //   if (m.authorize != 'none') {
      //     codeList.add(
      //         'public Task<FileStreamResult> ${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
      //     codeList.add('    => On${m.name}${el.apiPrefix}(user, file);');
      //     codeList.add('');
      //   } else {
      //     codeList.add(
      //         'public Task<FileStreamResult> ${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
      //     codeList.add('    => On${m.name}${el.apiPrefix}(user, file);');
      //     codeList.add('');
      //   }
      // });
    });
    await Future.forEach<NsgGenFunction>(functions, (element) async {
      element.generateControllerImplDesignerMethod(
          codeList, nsgGenerator, this);
      codeList.add('');
    });

    codeList.add(
        'public void ApplyServerFilter<T>(INsgTokenExtension user, ref NsgFindParams findParams) where T : NsgServerDataItem, new()');
    codeList.add('{');
    codeList.add('T obj = new T();');
    codeList.add('if (findParams == null) findParams = new NsgFindParams();');
    codeList.add('obj.PrepareFindParams(findParams);');
    codeList.add('OnGetControllerCompare(user, obj, findParams);');
    codeList.add('OnApplyServerFilter(user, obj, findParams);');
    codeList.add('obj.ApplyServerFilter(user, findParams);');
    codeList.add('}');

    codeList.add('}');
    codeList.add('}');
    Misc.indentCSharpCode(codeList);
    var fn =
        '${nsgGenerator.cSharpPath}/Controllers/$implControllerName.Designer.cs';
    await File(fn).writeAsString(codeList.join('\r\n'));

    // ${implControllerName}.cs
    codeList.clear();
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net;');
    if (functions.any((f) => ['Image', 'Binary'].contains(f.type))) {
      codeList.add('using System.Net.Http;');
      codeList.add('using System.Net.Http.Headers;');
    }
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.isDotNetCore) {
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    if (hasMetadata) {
      codeList.add('using NsgSoft.Common;');
      codeList.add('using NsgSoft.DataObjects;');
      var usedNSs = <String>[];
      methods.forEach((m) {
        if (m.genDataItem.databaseTypeNamespace.isEmpty) return;
        if (usedNSs.contains(m.genDataItem.databaseTypeNamespace)) return;
        codeList.add('using ${m.genDataItem.databaseTypeNamespace};');
        usedNSs.add(m.genDataItem.databaseTypeNamespace);
      });
    }
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList.add('public partial class $implControllerName');
    codeList.add('{');
    // codeList.add('public ${implControllerName}()');
    // codeList.add('{');
    // codeList.add('}');
    // codeList.add('');
    methods.forEach((m) {
      // m.imageFieldList.forEach((el) {
      //   if (m.authorize != 'none') {
      //     codeList.add(
      //         'private Task<FileStreamResult> On${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
      //     codeList.add('{');
      //     codeList.add('throw new NotImplementedException();');
      //     codeList.add('}');
      //     codeList.add('');
      //   } else {
      //     codeList.add(
      //         'private Task<FileStreamResult> On${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
      //     codeList.add('{');
      //     codeList.add('throw new NotImplementedException();');
      //     codeList.add('}');
      //     codeList.add('');
      //   }
      // });
    });
    await Future.forEach<NsgGenFunction>(functions, (element) async {
      await element.generateControllerImplMethod(codeList, nsgGenerator, this);
      codeList.add('');
    });
    codeList.add('#region Common');
    codeList.add(
        'public void OnGetControllerCompare(INsgTokenExtension user, NsgServerDataItem obj, NsgFindParams findParams) { }');
    codeList.add('');
    codeList.add(
        'private void OnBeforePost(INsgTokenExtension user, IEnumerable<NsgServerDataItem> items) { }');
    codeList.add('');
    codeList.add(
        'public void OnApplyServerFilter(INsgTokenExtension user, NsgServerDataItem obj, NsgFindParams findParams) { }');
    codeList.add('#endregion');
    codeList.add('}');
    codeList.add('}');
    Misc.indentCSharpCode(codeList);
    fn = '${nsgGenerator.cSharpPath}/Controllers/$implControllerName.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  static void generateImplMetadataGetMethodBody(
      NsgGenerator nsgGenerator, List<String> codeList, NsgGenMethod m) async {
    if (m.genDataItem.entityType != NsgGenDataItemEntityType.dataItem) {
      codeList.add(
          'return await Get<${m.genDataItem.typeName}>(user, findParams);');
    } else {
      codeList.add(
          'var RES = GetResultDictionary<${m.genDataItem.typeName}>(findParams);');
      codeList.add('');
      codeList.add('return RES;');
    }
  }

  Future generateImplAuthController(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using NsgServerClasses;');
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net.Http;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('using System.Web;');
    if (nsgGenerator.isDotNetCore) {
      codeList.add('using Microsoft.AspNetCore.Http;');
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList.add('public class $implAuthControllerName : AuthImplInterface');
    codeList.add('{');
    var methodSignatures = [
      'public Task<INsgTokenExtension> CheckUserToken(string token, string firebaseToken)',
      'public Task<int> CheckVersion(string appId, string version)',
      'public Task<int> CheckVersion(string accessToken, string appId, string version, string model, string manufacturer, string versionOS, string platform)',
      'public Task<bool> EndUserSession(INsgTokenExtension user, Guid sessionId)',
      'public Task<INsgTokenExtension> GetAnonymousToken(INsgTokenExtension tokenExtension)',
      'public Task<FileStreamResult> GetCapture(string token)',
      'public Task<INsgTokenExtension> GetUserByToken(HttpRequestMessage request)',
      'public INsgTokenExtension GetUserByTokenSync(HttpRequestMessage request)',
      'public Task<IEnumerable<UserSession>> GetUserSessions(INsgTokenExtension user, NsgFindParams findParams)',
      'public Task Logout(string accessToken)',
      'public Task<LoginResponse> PhoneLogin(string token, PhoneLoginModel model)',
      'public Task<LoginResponse> PhoneLoginRequestEmail(string accessToken, PhoneLoginModel model)',
      'public Task<LoginResponse> PhoneLoginRequestGoogle(string accessToken, PhoneLoginModel model)',
      'public Task<LoginResponse> PhoneLoginRequestSMS(string accessToken, PhoneLoginModel model)',
      'public Task<LoginResponse> PhoneLoginRequestVK(string accessToken, PhoneLoginModel model)',
      'public Task<LoginResponse> PhoneLoginVerifyGoogle(string accessToken, SocialMediaLoginModel model)',
      'public Task<LoginResponse> PhoneLoginVerifyVK(string accessToken, SocialMediaLoginModel model)',
      'public Task<int> SetLocale(string token, string locale)',
      'public Task<bool> Validate(HttpRequest request, string token)',
    ];
    methodSignatures.forEach((action) {
      codeList.add(action);
      codeList.add('{');
      codeList.add('throw new NotImplementedException();');
      codeList.add('}');
      codeList.add('');
    });
    codeList.removeLast();
    codeList.add('}');
    codeList.add('}');
    Misc.indentCSharpCode(codeList);
    var fn =
        '${nsgGenerator.cSharpPath}/Controllers/$implAuthControllerName.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }

    codeList.clear();
    codeList.add('using NsgServerClasses;');
    codeList.add('using NsgSoft.DataObjects;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public class ServerTokenItem : NsgTokenItem');
    codeList.add('{');
    codeList.add('// TODO: уточнить тип');
    codeList
        .add('public /*ПользователиСервисов*/NsgDataDictionary Пользователь;');
    codeList
        .add('//public override string DbUser => Пользователь?.ToString();');
    codeList.add('}');
    codeList.add('}');
    Misc.indentCSharpCode(codeList);
    fn = '${nsgGenerator.cSharpPath}/Controllers/ServerTokenItem.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  Future load(NsgGenerator nsgGenerator) async {
    print('load Controller $className start');
    await Future.forEach<NsgGenMethod>(methods, (element) async {
      await element.loadGenDataItem(nsgGenerator);
      if (!nsgGenerator.dataItems.containsKey(element.genDataItem.typeName)) {
        nsgGenerator.dataItems[element.genDataItem.typeName] =
            element.genDataItem;
      }
    });
    print('load $className finished');
  }

  Future generateCodeDart(NsgGenerator nsgGenerator) async {
    //Init controller initialization
    await generateInitController(nsgGenerator);
    await Future.forEach<NsgGenMethod>(methods, (_) async {
      await _.generateCodeDart(nsgGenerator, this);
    });
    await generateExportFile(nsgGenerator);
  }

  Future generateExportFile(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    methods.forEach((_) {
      codeList.add(
          "export '${Misc.getDartUnderscoreName(_.genDataItem.typeName)}.dart';");
      codeList.add(
          "export '${nsgGenerator.genPathName}/${Misc.getDartUnderscoreName(_.genDataItem.typeName)}.g.dart';");
    });

    await File(
            '${nsgGenerator.dartPath}/${Misc.getDartUnderscoreName(className)}_model.dart')
        .writeAsString(codeList.join('\r\n'));
  }

  Future generateInitController(NsgGenerator nsgGenerator) async {
    //----------------------------------------------------------
    //generate service class controllerName.g.dart
    //----------------------------------------------------------
    var codeList = <String>[];
    codeList.add("import 'package:get/get.dart';");
    if (functions.isNotEmpty) {
      codeList.add("import 'package:nsg_controls/nsg_controls.dart';");
    }
    codeList.add("import 'package:nsg_data/nsg_data.dart';");
    codeList.add("// ignore: depend_on_referenced_packages");
    codeList.add("import 'package:package_info_plus/package_info_plus.dart';");
    codeList.add("import '../options/server_options.dart';");
    // if (functions.any((f) => ['Image', 'Binary'].contains(f.type))) {
    //   codeList.add("import 'dart:io';");
    // }
    if (nsgGenerator.enums.isNotEmpty) {
      codeList.add("import '../enums.dart';");
    }
    codeList.add(
        "import '../${Misc.getDartUnderscoreName(className)}_model.dart';");
    codeList.add('');
    codeList.add('class ${className}Generated extends NsgBaseController {');
    codeList.add('  NsgDataProvider? provider;');
    codeList.add('  @override');
    codeList.add('  Future onInit() async {');
    codeList.add('    final info = await PackageInfo.fromPlatform();');
    if (useMetrics) {
      codeList.add('    NsgMetrica.activate();');
    }
    codeList.add('    NsgMetrica.reportAppStart();');
    codeList.add('    provider ??= NsgDataProvider(');
    codeList.add(
        '        applicationName: \'${nsgGenerator.applicationName}\', applicationVersion: info.version, firebaseToken: \'\', availableServers: NsgServerOptions.availableServers);');
    codeList.add('    provider?.loadServerAddress();');
    if (!loginRequired) {
      codeList.add('    provider!.loginRequired = false;');
    }
    codeList.add('');
    addRegisterDataItems(nsgGenerator, codeList);
    codeList
        .add('    await NsgLocalDb.instance.init(provider!.applicationName);');
    codeList.add('    provider!.useNsgAuthorization = $useAuthorization;');
    codeList.add('    var db = NsgLocalDb.instance;');
    codeList.add('    await db.init(\'${nsgGenerator.applicationName}\');');
    codeList.add('    await provider!.connect(this);');
    //codeList.add('    if (provider!.isAnonymous) {');
    // codeList.add(
    //     '      await Get.to(provider!.loginPage)?.then((value) => loadData());');
    // codeList.add('    } else {');
    // codeList.add('      await loadData();');
    // codeList.add('    }');
    codeList.add('');
    codeList.add('    super.onInit();');
    codeList.add('  }');
    codeList.add('');

    codeList.add('  @override');
    codeList.add('  Future loadProviderData() async {');
    codeList.add(
        '    currentStatus = GetStatus.success(NsgBaseController.emptyData);');
    codeList.add('    sendNotify();');
    codeList.add('  }');

    await Future.forEach<NsgGenFunction>(functions, (_) async {
      if (!_.writeOnClient) return;
      codeList.add('');
      await _.generateCodeDart(codeList, nsgGenerator, this);
    });

    codeList.add('}');
    codeList.add('');

    await File(
            '${nsgGenerator.dartPathGen}/${Misc.getDartUnderscoreName(className)}.g.dart')
        .writeAsString(codeList.join('\r\n'));

    //----------------------------------------------------------
    //generate main class ControllerName.dart
    //----------------------------------------------------------
    codeList = <String>[];
    //codeList.add("import '${nsgGenerator.getDartName(className)}Model.dart';");
    codeList.add(
        "import '${nsgGenerator.genPathName}/${Misc.getDartUnderscoreName(className)}.g.dart';");
    codeList.add('');
    codeList.add('class $className extends ${className}Generated {');
    codeList.add('  $className() : super();');
    codeList.add('}');

    var fn =
        '${nsgGenerator.dartPath}/${Misc.getDartUnderscoreName(className)}.dart';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  static Future generateControllerOptions(
      NsgGenerator nsgGenerator, List<NsgGenController> controllers) async {
    var codeList = <String>[];
    codeList.add('class NsgServerOptions {');
    controllers.forEach((c) {
      codeList.add(
          '  static const String serverUri${c.className} = \'${c.serverUri}\';');
      codeList.add(
          '  static NsgServerParams availableServers = NsgServerParams({\'${c.serverUri}\': \'main\'}, \'${c.serverUri}\');');
    });
    codeList.add('}');

    codeList.add('class NsgMetricaOptions {');
    codeList.add('  static String yandexMetricaId = "";');
    codeList.add('}');

    var file = File('${nsgGenerator.dartPath}/options/server_options.dart');
    if (await file.exists() && !nsgGenerator.forceOverwrite) return;
    await file.writeAsString(codeList.join('\r\n'));
  }

  void addRegisterDataItems(NsgGenerator nsgGenerator, List<String> codeList) {
    methods.forEach((_) {
      codeList.add('    NsgDataClient.client');
      codeList.add(
          '        .registerDataItem(${_.genDataItem.typeName}(), remoteProvider: provider);');
    });
    nsgGenerator.enums.forEach((_) {
      codeList.add('    NsgDataClient.client');

      codeList.add(
          '        .registerDataItem(${_.className}(0, \'\'), remoteProvider: provider);');
    });
  }
}
