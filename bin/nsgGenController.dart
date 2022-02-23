import 'dart:io';
import 'dart:async';

import 'nsgGenCSProject.dart';
import 'nsgGenMethod.dart';
import 'nsgGenFunction.dart';
import 'nsgGenerator.dart';

class NsgGenController {
  final String api_prefix;
  final String class_name;
  final String impl_controller_name;
  final String impl_auth_controller_name;
  final String dataType;
  final String serverUri;
  final bool useAuthorization;
  final bool uploadEnabled;
  final List<NsgGenMethod> methods;
  final List<NsgGenFunction> functions;

  NsgGenController(
      {this.api_prefix,
      this.class_name,
      this.impl_controller_name,
      this.impl_auth_controller_name,
      this.dataType,
      this.serverUri,
      this.useAuthorization,
      this.uploadEnabled,
      this.methods,
      this.functions});

  factory NsgGenController.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenController(
        api_prefix: parsedJson['api_prefix'],
        class_name: parsedJson['class_name'],
        impl_controller_name:
            (parsedJson['impl_controller_name']?.isNotEmpty ?? false)
                ? parsedJson['impl_controller_name']
                : parsedJson['class_name'] + 'Implementation',
        impl_auth_controller_name:
            (parsedJson['impl_auth_controller_name']?.isNotEmpty ?? false)
                ? parsedJson['impl_auth_controller_name']
                : 'AuthControllerImplementation',
        dataType: parsedJson['dataType'],
        serverUri: parsedJson['serverUri'],
        useAuthorization: parsedJson['useAuthorization'] == 'true',
        uploadEnabled: parsedJson['uploadEnabled'] == 'true',
        methods: (parsedJson['method'] as List)
            .map((i) => NsgGenMethod.fromJson(i))
            .toList(),
        functions: parsedJson.containsKey('functions')
            ? (parsedJson['functions'] as List)
                .map((i) => NsgGenFunction.fromJson(i))
                .toList()
            : []);
  }

  void generateCode(NsgGenerator nsgGenerator) async {
    if (nsgGenerator.doCSharp) {
      var codeList = <String>[];
      codeList.add('using Microsoft.Extensions.Logging;');
      codeList.add('using System;');
      codeList.add('using System.Collections.Generic;');
      codeList.add('using System.Linq;');
      codeList.add('using System.Threading.Tasks;');
      if (nsgGenerator.targetFramework == 'net5.0') {
        codeList.add('using Microsoft.AspNetCore.Mvc;');
        codeList.add('using Microsoft.AspNetCore.Authorization;');
      } else {
        codeList.add('using System.Web.Http;');
        codeList.add('using System.Web.Mvc;');
        codeList
            .add('using HttpGetAttribute = System.Web.Http.HttpGetAttribute;');
        codeList.add(
            'using HttpPostAttribute = System.Web.Http.HttpPostAttribute;');
        codeList.add(
            'using RoutePrefixAttribute = System.Web.Http.RoutePrefixAttribute;');
        codeList.add('using RouteAttribute = System.Web.Http.RouteAttribute;');
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
      codeList.add('/// <summary>');
      codeList.add('///${dataType}Interface Controller');
      codeList.add('/// </summary>');
      if (nsgGenerator.targetFramework == 'net5.0') {
        codeList.add('[ApiController]');
        codeList.add('[Route("${api_prefix}")]');
      } else {
        codeList.add('[RoutePrefix("${api_prefix}")]');
      }
      codeList.add('public class ${class_name} : ' +
          (nsgGenerator.targetFramework == 'net5.0'
              ? 'ControllerBase'
              : 'ApiController'));
      codeList.add('{');

      codeList.add('${class_name}Interface controller;');
      codeList.add('AuthImplInterface authController;');

      codeList.add('private readonly ILogger<${class_name}> _logger;');
      codeList.add('public ${class_name}(ILogger<${class_name}> logger)');
      codeList.add('{');
      codeList.add('_logger = logger;');
      codeList.add('#if (Real)');
      codeList.add('controller = new ${impl_controller_name}();');
      codeList.add('authController = new ${impl_auth_controller_name}();');
      codeList.add('#else');
      codeList.add('controller = new ${impl_controller_name}Mock();');
      codeList.add('authController = new ${impl_auth_controller_name}Mock();');
      codeList.add('#endif');
      codeList.add('}');
      codeList.add('');
      if (nsgGenerator.targetFramework != 'net5.0') {
        codeList.add('public ${class_name}() : this(null) { }');
        codeList.add('');
      }
      codeList.add('private static ${class_name} currentController;');
      codeList.add('public static ${class_name} getController');
      codeList.add('{');
      codeList.add('get');
      codeList.add('{');
      codeList.add(
          'if (currentController == null) currentController = new ${class_name}();');
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
      codeList.add(
          'if (NsgServerClasses.AuthController.currentController == null)');
      codeList.add('{');
      codeList.add('authController = new ${impl_auth_controller_name}();');
      codeList.add(
          'NsgServerClasses.AuthController.currentController = authController;');
      codeList.add('}');
      codeList.add('}');
      codeList.add('');
      await Future.forEach<NsgGenMethod>(methods, (element) async {
        await element.generateCode(codeList, nsgGenerator, this, element);
      });

      await Future.forEach<NsgGenFunction>(functions, (element) async {
        await element.generateControllerMethod(codeList, nsgGenerator, this);
      });

      codeList.add('}');
      codeList.add('}');
      NsgGenCSProject.indentCode(codeList);

      var fn = '${nsgGenerator.cSharpPath}/${class_name}.cs';
      //if (!File(fn).existsSync()) {
      await File(fn).writeAsString(codeList.join('\r\n'));
      //}
      await generateInterfaceData(nsgGenerator);
      await generateImplController(nsgGenerator);
      await generateImplAuthController(nsgGenerator);
    }
    if (nsgGenerator.doDart) {
      await generateCodeDart(nsgGenerator);
    }
  }

  void generateInterfaceData(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Net;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.targetFramework == 'net5.0') {
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('public interface ${class_name}Interface');
    codeList.add('{');

    var publicMdf = (nsgGenerator.targetFramework == 'net5.0' ? 'public ' : '');
    methods.forEach((_) {
      if (_.authorize != 'none') {
        // codeList.add(
        //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        codeList.add(
            '${publicMdf}Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        if (_.allowPost) {
          // codeList.add(
          //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
          codeList.add(
              '${publicMdf}Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
        }
      } else {
        // codeList.add(
        //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        codeList.add(
            '${publicMdf}Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        if (_.allowPost) {
          // codeList.add(
          //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
          codeList.add(
              '${publicMdf}Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
        }
      }
      _.imageFieldList.forEach((el) {
        if (_.authorize != 'none') {
          codeList.add(
              '${publicMdf}Task<FileStreamResult> ${_.name}${el.apiPrefix}(INsgTokenExtension user, String file);');
        } else {
          codeList.add(
              '${publicMdf}Task<FileStreamResult> ${_.name}${el.apiPrefix}(INsgTokenExtension user, String file);');
        }
      });
    });
    codeList.add('');
    await Future.forEach<NsgGenFunction>(functions, (element) async {
      await element.generateControllerInterfaceMethod(
          codeList, nsgGenerator, this);
    });
    if (functions.isNotEmpty) {
      codeList.add('');
    }
    codeList.add(
        'void ApplyServerFilter<T>(INsgTokenExtension user, NsgFindParams findParams) where T : NsgServerDataItem, new();');

    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    var fn = '${nsgGenerator.cSharpPath}/${class_name}Interface.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\r\n'));
    //}
  }

  void generateImplController(NsgGenerator nsgGenerator) async {
    // ${impl_controller_name}.Designer.cs
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.targetFramework == 'net5.0') {
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
        'public partial class ${impl_controller_name} : ${class_name}Interface');
    codeList.add('{');
    codeList.add(
        'private delegate Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> HttpGetEventHandler(INsgTokenExtension user, NsgFindParams findParams);');
    codeList.add(
        'private delegate Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> HttpPostEventHandler<T>(INsgTokenExtension user, IEnumerable<NsgServerDataItem> items) where T : NsgServerDataItem;');

    var hasMetadata = false;
    methods.forEach((m) {
      if (m.genDataItem.databaseType != null &&
          m.genDataItem.databaseType.isNotEmpty) {
        hasMetadata = true;
      }
      if (m.authorize != 'none') {
        codeList.add('private event HttpGetEventHandler ${m.name}Event;');
        codeList.add(
            'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('{');
        codeList.add(
            'ApplyServerFilter<${m.genDataItem.typeName}>(user, findParams);');
        codeList.add('return ${m.name}Event(user, findParams);');
        codeList.add('}');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'private event HttpPostEventHandler<${m.genDataItem.typeName}> ${m.name}PostEvent;');
          codeList.add(
              'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${m.genDataItem.typeName}> items)');
          codeList.add('    => ${m.name}PostEvent(user, items);');
          codeList.add('');
        }
      } else {
        codeList.add('private event HttpGetEventHandler ${m.name}Event;');
        codeList.add(
            'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('{');
        codeList.add(
            'ApplyServerFilter<${m.genDataItem.typeName}>(user, findParams);');
        codeList.add('return ${m.name}Event(user, findParams);');
        codeList.add('}');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'private event HttpPostEventHandler<${m.genDataItem.typeName}> ${m.name}PostEvent;');
          codeList.add(
              'public Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> ${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${m.genDataItem.typeName}> items)');
          codeList.add('    => ${m.name}PostEvent(user, items);');
          codeList.add('');
        }
      }
      m.imageFieldList.forEach((el) {
        if (m.authorize != 'none') {
          codeList.add(
              'public Task<FileStreamResult> ${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
          codeList.add('    => On${m.name}${el.apiPrefix}(user, file);');
          codeList.add('');
        } else {
          codeList.add(
              'public Task<FileStreamResult> ${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
          codeList.add('    => On${m.name}${el.apiPrefix}(user, file);');
          codeList.add('');
        }
      });
    });
    await Future.forEach<NsgGenFunction>(functions, (element) async {
      await element.generateControllerImplDesignerMethod(
          codeList, nsgGenerator, this);
      codeList.add('');
    });

    codeList.add(
        'public void ApplyServerFilter<T>(INsgTokenExtension user, NsgFindParams findParams) where T : NsgServerDataItem, new()');
    codeList.add('{');
    codeList.add('T obj = new T();');
    codeList.add('if (findParams == null) findParams = new NsgFindParams();');
    codeList.add('obj.PrepareFindParams(findParams);');
    if (hasMetadata) {
      codeList.add('');
      codeList.add(
          'var cmp = string.IsNullOrWhiteSpace(findParams.SearchCriteriaXml) ?');
      codeList.add('    new NsgSoft.DataObjects.NsgCompare() :');
      codeList.add(
          '    NsgSoft.DataObjects.NsgCompare.FromXml(findParams.SearchCriteriaXml);');
      codeList.add('OnGetControllerCompare(user, obj, cmp);');
      codeList.add('findParams.SearchCriteriaXml = cmp.ToXml();');
      codeList.add('');
    }
    codeList.add('OnApplyServerFilter(user, obj, findParams);');
    codeList.add('obj.ApplyServerFilter(user, findParams);');
    codeList.add('}');

    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    var fn =
        '${nsgGenerator.cSharpPath}/Controllers/${impl_controller_name}.Designer.cs';
    await File(fn).writeAsString(codeList.join('\r\n'));

    // ${impl_controller_name}.cs
    codeList.clear();
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.targetFramework == 'net5.0') {
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    if (hasMetadata) {
      codeList.add('using NsgSoft.DataObjects;');
      var usedNSs = <String>[];
      methods.forEach((m) {
        if (!usedNSs.contains(m.genDataItem.databaseTypeNamespace)) {
          codeList.add('using ${m.genDataItem.databaseTypeNamespace};');
          usedNSs.add(m.genDataItem.databaseTypeNamespace);
        }
      });
    }
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList.add('public partial class ${impl_controller_name}');
    codeList.add('{');
    codeList.add('public ${impl_controller_name}()');
    codeList.add('{');
    methods.forEach((m) {
      codeList.add('${m.name}Event += On${m.name};');
      if (m.allowPost) {
        codeList.add('${m.name}PostEvent += On${m.name}Post;');
      }
    });
    codeList.add('}');
    codeList.add('');
    methods.forEach((m) {
      if (m.authorize != 'none') {
        codeList.add(
            'private async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> On${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('{');
        if (hasMetadata &&
            m.genDataItem.databaseType != null &&
            m.genDataItem.databaseType.isNotEmpty) {
          generateImplMetadataGetMethodBody(nsgGenerator, codeList, m);
        } else {
          codeList.add('throw new NotImplementedException();');
        }
        codeList.add('}');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'private async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> On${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<NsgServerDataItem> items)');
          codeList.add('{');
          if (hasMetadata &&
              m.genDataItem.databaseType != null &&
              m.genDataItem.databaseType.isNotEmpty) {
            codeList.add(
                'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
            codeList.add(
                'RES["results"] = NsgServerMetadataItem.PostAll<${m.genDataItem.typeName}>(items);');
            codeList.add('return RES;');
          } else {
            codeList.add('throw new NotImplementedException();');
          }
          codeList.add('}');
          codeList.add('');
        }
      } else {
        codeList.add(
            'private async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> On${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('{');
        if (hasMetadata &&
            m.genDataItem.databaseType != null &&
            m.genDataItem.databaseType.isNotEmpty) {
          generateImplMetadataGetMethodBody(nsgGenerator, codeList, m);
        } else {
          codeList.add('throw new NotImplementedException();');
        }
        codeList.add('}');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'private async Task<Dictionary<string, IEnumerable<NsgServerDataItem>>> On${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<NsgServerDataItem> items)');
          codeList.add('{');
          if (hasMetadata &&
              m.genDataItem.databaseType != null &&
              m.genDataItem.databaseType.isNotEmpty) {
            codeList.add(
                'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
            codeList.add(
                'RES["results"] = NsgServerMetadataItem.PostAll<ScifProvider>(items);');
            codeList.add('return RES;');
          } else {
            codeList.add('throw new NotImplementedException();');
          }
          codeList.add('}');
          codeList.add('');
        }
      }
      m.imageFieldList.forEach((el) {
        if (m.authorize != 'none') {
          codeList.add(
              'private Task<FileStreamResult> On${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
          codeList.add('{');
          codeList.add('throw new NotImplementedException();');
          codeList.add('}');
          codeList.add('');
        } else {
          codeList.add(
              'private Task<FileStreamResult> On${m.name}${el.apiPrefix}(INsgTokenExtension user, String file)');
          codeList.add('{');
          codeList.add('throw new NotImplementedException();');
          codeList.add('}');
          codeList.add('');
        }
      });
    });
    await Future.forEach<NsgGenFunction>(functions, (element) async {
      await element.generateControllerImplMethod(codeList, nsgGenerator, this);
      codeList.add('');
    });
    if (hasMetadata) {
      codeList.add(
          'public void OnGetControllerCompare(INsgTokenExtension user, NsgServerDataItem obj, NsgSoft.DataObjects.NsgCompare cmp) { }');
      codeList.add('');
    }
    codeList.add(
        'public void OnApplyServerFilter(INsgTokenExtension user, NsgServerDataItem obj, NsgFindParams findParams) { }');

    if (hasMetadata) {
      codeList.add('');
      codeList.add('#region Common');
      codeList.add(
          'private static Dictionary<string, IEnumerable<NsgServerDataItem>> GetResultDictionary<T>(NsgMultipleObject nsgMultipleObject, NsgFindParams findParams)');
      codeList.add('    where T : NsgServerMetadataItem, new()');
      codeList.add('{');
      codeList.add('var res = GetResults<T>(nsgMultipleObject, findParams);');
      codeList.add(
          'Dictionary<string, IEnumerable<NsgServerDataItem>> RES = new Dictionary<string, IEnumerable<NsgServerDataItem>>();');
      codeList.add('RES["results"] = res;');
      codeList.add('return RES;');
      codeList.add('}');
      codeList.add('');
      codeList.add(
          'private static IEnumerable<ServerT> GetResults<ServerT>(NsgMultipleObject nsgMultipleObject, NsgFindParams findParams) where ServerT : NsgServerMetadataItem, new()');
      codeList.add('{');
      codeList.add('NsgCompare cmp = new NsgCompare();');
      codeList.add('NsgSorting sorting = new NsgSorting();');
      codeList.add('if (findParams != null)');
      codeList.add('{');
      codeList.add('cmp = NsgCompare.FromXml(findParams.SearchCriteriaXml);');
      codeList
          .add('sorting = new ServerT().GetNsgSorting(findParams.Sorting);');
      codeList.add('}');
      codeList.add(
          'var res = NsgServerMetadataItem.FindAll<ServerT>(nsgMultipleObject, cmp, sorting);');
      codeList.add('return res;');
      codeList.add('}');
      codeList.add('#endregion');
    }
    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    fn = '${nsgGenerator.cSharpPath}/Controllers/${impl_controller_name}.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  void generateImplMetadataGetMethodBody(
      NsgGenerator nsgGenerator, List<String> codeList, NsgGenMethod m) async {
    codeList.add(
        'var RES = GetResultDictionary<${m.genDataItem.typeName}>(${m.genDataItem.databaseType}.Новый(), findParams);');
    codeList.add('');
    var tables = m.genDataItem.fields
        .where((element) => element.type == 'List<Reference>');
    if (tables.isNotEmpty) {
      codeList
          .add('if (!string.IsNullOrWhiteSpace(findParams?.ReadNestedField))');
      codeList.add('{');
      codeList
          .add('var res = RES["results"].Cast<${m.genDataItem.typeName}>();');
      codeList.add(
          'string[] fields = findParams.ReadNestedField.Split(new[] { \',\' }, StringSplitOptions.RemoveEmptyEntries);');
      codeList.add('foreach (string s in fields)');
      codeList.add('{');
      codeList.add('string field = s.Trim();');
      codeList.add(
          'var referent = res.FirstOrDefault()?.NSGObject[field].ToReferent();');
      tables.forEach((table) {
        if (table.dbType != null && table.dbType.isNotEmpty) {
          codeList.add('if (referent is ${table.dbType})');
        } else if (table.dbName != null && table.dbName.isNotEmpty) {
          codeList.add('if (field == "${table.dbName}")');
        } else {
          return;
        }
        codeList.add('{');
        codeList.add('var refs = res.SelectMany(i => i.${table.name});');
        codeList.add('RES[field] = refs;');
        codeList.add('}');
      });
      codeList.add('}');
      codeList.add('}');
      codeList.add('');
    }
    codeList.add('return RES;');
  }

  void generateImplAuthController(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using NsgServerClasses;');
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net.Http;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.targetFramework == 'net5.0') {
      codeList.add('using Microsoft.AspNetCore.Http;');
      codeList.add('using Microsoft.AspNetCore.Mvc;');
    } else {
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Mvc;');
    }
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList
        .add('public class ${impl_auth_controller_name} : AuthImplInterface');
    codeList.add('{');
    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    var fn =
        '${nsgGenerator.cSharpPath}/Controllers/${impl_auth_controller_name}.cs';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  void load(NsgGenerator nsgGenerator) async {
    print('load Controller ${class_name} start');
    await Future.forEach<NsgGenMethod>(methods, (element) async {
      await element.loadGenDataItem(nsgGenerator);
    });
    print('load ${class_name} finished');
  }

  void generateCodeDart(NsgGenerator nsgGenerator) async {
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
          "export '${nsgGenerator.getDartUnderscoreName(_.genDataItem.typeName)}.dart';");
      codeList.add(
          "export '${nsgGenerator.genPathName}/${nsgGenerator.getDartUnderscoreName(_.genDataItem.typeName)}.g.dart';");
    });

    await File(
            '${nsgGenerator.dartPath}/${nsgGenerator.getDartUnderscoreName(class_name)}_model.dart')
        .writeAsString(codeList.join('\r\n'));
  }

  Future generateInitController(NsgGenerator nsgGenerator) async {
    //----------------------------------------------------------
    //generate service class controllerName.g.dart
    //----------------------------------------------------------
    var codeList = <String>[];
    codeList.add("import 'package:get/get.dart';");
    codeList.add("import 'package:nsg_data/nsg_data.dart';");
    if (nsgGenerator.enums.isNotEmpty) {
      codeList.add("import '../enums.dart';");
    }
    codeList.add(
        "import '../${nsgGenerator.getDartUnderscoreName(class_name)}_model.dart';");
    codeList.add('');
    codeList.add('class ${class_name}Generated extends NsgBaseController {');
    codeList.add('  NsgDataProvider? provider;');
    codeList.add('  @override');
    codeList.add('  Future onInit() async {');
    codeList.add('    provider ??= NsgDataProvider(firebaseToken: \'\');');
    codeList.add("  provider!.serverUri = '$serverUri';");
    codeList.add('  ');
    addRegisterDataItems(nsgGenerator, codeList);
    codeList.add('    provider!.useNsgAuthorization = ${useAuthorization};');
    codeList.add('    await provider!.connect(this);');
    codeList.add('    if (provider!.isAnonymous) {');
    codeList.add(
        '      await Get.to(provider!.loginPage)?.then((value) => loadData());');
    codeList.add('    } else {');
    codeList.add('      await loadData();');
    codeList.add('    }');
    codeList.add('    ');
    codeList.add('    super.onInit();');
    codeList.add('  }');

    await Future.forEach<NsgGenFunction>(functions, (_) async {
      codeList.add('');
      await _.generateCodeDart(codeList, nsgGenerator, this);
    });

    codeList.add('  ');
    codeList.add('  Future loadData() async {');
    codeList.add('    currentStatus = RxStatus.success();');
    codeList.add('    sendNotify();');
    codeList.add('  }');

    codeList.add('}');

    await File(
            '${nsgGenerator.dartPathGen}/${nsgGenerator.getDartUnderscoreName(class_name)}.g.dart')
        .writeAsString(codeList.join('\r\n'));

    //----------------------------------------------------------
    //generate main class ControllerName.dart
    //----------------------------------------------------------
    codeList = <String>[];
    //codeList.add("import '${nsgGenerator.getDartName(class_name)}Model.dart';");
    codeList.add(
        "import '${nsgGenerator.genPathName}/${nsgGenerator.getDartUnderscoreName(class_name)}.g.dart';");
    codeList.add('');
    codeList.add('class ${class_name} extends ${class_name}Generated {');
    // codeList.add('');
    // codeList
    //     .add('  ${class_name}(NsgDataProvider provider) : super(provider);');
    // codeList.add('');
    // codeList.add('  @override');
    // codeList.add('  Future loadData() async {');
    // codeList.add('    super.loadData();');
    // codeList.add('  }');
    codeList.add('  DataController() : super();');

    codeList.add('}');

    var fn =
        '${nsgGenerator.dartPath}/${nsgGenerator.getDartUnderscoreName(class_name)}.dart';
    if (!File(fn).existsSync() || nsgGenerator.forceOverwrite) {
      await File(fn).writeAsString(codeList.join('\r\n'));
    }
  }

  void addRegisterDataItems(NsgGenerator nsgGenerator, List<String> codeList) {
    methods.forEach((_) {
      codeList.add('      NsgDataClient.client');
      if (_.genDataItem == null) {
        print('${_.name}.genDataItem == null');
      }
      codeList.add(
          '       .registerDataItem(${_.genDataItem.typeName}(), remoteProvider: provider);');
    });
    nsgGenerator.enums.forEach((_) {
      codeList.add('      NsgDataClient.client');
      if (_ == null) {
        print('${_.class_name}.genDataItem == null');
      }
      codeList.add(
          '       .registerDataItem(${_.class_name}(0, \'\'), remoteProvider: provider);');
    });
  }
}
