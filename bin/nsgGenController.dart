import 'dart:io';
import 'dart:async';

import 'nsgGenCSProject.dart';
import 'nsgGenMethod.dart';
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

  NsgGenController(
      {this.api_prefix,
      this.class_name,
      this.impl_controller_name,
      this.impl_auth_controller_name,
      this.dataType,
      this.serverUri,
      this.useAuthorization,
      this.uploadEnabled,
      this.methods});

  factory NsgGenController.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenController(
        api_prefix: parsedJson['api_prefix'],
        class_name: parsedJson['class_name'],
        impl_controller_name:
            (parsedJson['impl_controller_name']?.isNotEmpty ?? false)
                ? parsedJson['impl_controller_name']
                : parsedJson['class_name'],
        impl_auth_controller_name:
            (parsedJson['impl_auth_controller_name']?.isNotEmpty ?? false)
                ? parsedJson['impl_auth_controller_name']
                : 'AuthController',
        dataType: parsedJson['dataType'],
        serverUri: parsedJson['serverUri'],
        useAuthorization: parsedJson['useAuthorization'] == 'true',
        uploadEnabled: parsedJson['uploadEnabled'] == 'true',
        methods: (parsedJson['method'] as List)
            .map((i) => NsgGenMethod.fromJson(i))
            .toList());
  }

  void generateCode(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using Microsoft.AspNetCore.Mvc;');
    codeList.add('using Microsoft.Extensions.Logging;');
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Threading.Tasks;');
    if (nsgGenerator.targetFramework != 'net5.0') {
      codeList.add('using System.Web.Http;');
      codeList
          .add('using HttpGetAttribute = System.Web.Http.HttpGetAttribute;');
      codeList
          .add('using HttpPostAttribute = System.Web.Http.HttpPostAttribute;');
      codeList.add('using RouteAttribute = System.Web.Http.RouteAttribute;');
      codeList
          .add('using FromBodyAttribute = System.Web.Http.FromBodyAttribute;');
      codeList.add(
          'using AuthorizeAttribute = System.Web.Http.AuthorizeAttribute;');
      codeList.add(
          'using ActionNameAttribute = System.Web.Http.ActionNameAttribute;');
    }
    codeList.add('using Microsoft.AspNetCore.Authorization;');
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

    await Future.forEach<NsgGenMethod>(methods, (element) async {
      await element.generateCode(codeList, nsgGenerator, this, element);
    });

    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);

    var fn = '${nsgGenerator.cSharpPath}/${class_name}.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\n'));
    //}
    await generateInterfaceData(nsgGenerator);
    await generateImplController(nsgGenerator);
    await generateImplAuthController(nsgGenerator);
    await generateCodeDart(nsgGenerator);
  }

  void generateInterfaceData(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Net;');
    codeList.add('using Microsoft.AspNetCore.Mvc;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
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
            '${publicMdf}Task<Dictionary<string, IEnumerable<object>>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        if (_.allowPost) {
          // codeList.add(
          //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
          codeList.add(
              '${publicMdf}Task<Dictionary<string, IEnumerable<object>>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
        }
      } else {
        // codeList.add(
        //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        codeList.add(
            '${publicMdf}Task<Dictionary<string, IEnumerable<object>>> ${_.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams);');
        if (_.allowPost) {
          // codeList.add(
          //     '${publicMdf}Task<IEnumerable<${_.genDataItem.typeName}>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
          codeList.add(
              '${publicMdf}Task<Dictionary<string, IEnumerable<object>>> ${_.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${_.genDataItem.typeName}> items);');
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

    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    var fn = '${nsgGenerator.cSharpPath}/${class_name}Interface.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\n'));
    //}
  }

  void generateImplController(NsgGenerator nsgGenerator) async {
    // Designer
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net;');
    codeList.add('using Microsoft.AspNetCore.Mvc;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList.add(
        'public partial class ${impl_controller_name} : ${class_name}Interface');
    codeList.add('{');

    methods.forEach((m) {
      if (m.authorize != 'none') {
        codeList.add(
            'public Task<Dictionary<string, IEnumerable<object>>> ${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('    => On${m.name}(user, findParams);');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'public Task<Dictionary<string, IEnumerable<object>>> ${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${m.genDataItem.typeName}> items)');
          codeList.add('    => On${m.name}Post(user, items);');
          codeList.add('');
        }
      } else {
        codeList.add(
            'public Task<Dictionary<string, IEnumerable<object>>> ${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('    => On${m.name}(user, findParams);');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'public Task<Dictionary<string, IEnumerable<object>>> ${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${m.genDataItem.typeName}> items)');
          codeList.add('    => On${m.name}Post(user, items);');
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

    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    var fn =
        '${nsgGenerator.cSharpPath}/Controllers/${impl_controller_name}.Designer.cs';
    await File(fn).writeAsString(codeList.join('\n'));

    // Editable
    codeList.clear();
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net;');
    codeList.add('using Microsoft.AspNetCore.Mvc;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}.Controllers');
    codeList.add('{');
    codeList.add('public partial class ${impl_controller_name}');
    codeList.add('{');

    methods.forEach((m) {
      if (m.authorize != 'none') {
        codeList.add(
            'private Task<Dictionary<string, IEnumerable<object>>> On${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('{');
        codeList.add('throw new NotImplementedException();');
        codeList.add('}');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'private Task<Dictionary<string, IEnumerable<object>>> On${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${m.genDataItem.typeName}> items)');
          codeList.add('{');
          codeList.add('throw new NotImplementedException();');
          codeList.add('}');
          codeList.add('');
        }
      } else {
        codeList.add(
            'private Task<Dictionary<string, IEnumerable<object>>> On${m.name}(INsgTokenExtension user, [FromBody] NsgFindParams findParams)');
        codeList.add('{');
        codeList.add('throw new NotImplementedException();');
        codeList.add('}');
        codeList.add('');
        if (m.allowPost) {
          codeList.add(
              'private Task<Dictionary<string, IEnumerable<object>>> On${m.name}Post(INsgTokenExtension user, [FromBody] IEnumerable<${m.genDataItem.typeName}> items)');
          codeList.add('{');
          codeList.add('throw new NotImplementedException();');
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

    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    fn = '${nsgGenerator.cSharpPath}/Controllers/${impl_controller_name}.cs';
    if (!File(fn).existsSync()) {
      await File(fn).writeAsString(codeList.join('\n'));
    }
  }

  void generateImplAuthController(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using Microsoft.AspNetCore.Http;');
    codeList.add('using Microsoft.AspNetCore.Mvc;');
    codeList.add('using NsgServerClasses;');
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.Linq;');
    codeList.add('using System.Net.Http;');
    codeList.add('using System.Threading.Tasks;');
    codeList.add('');
    codeList.add('namespace ScifWebApi.Controllers');
    codeList.add('{');
    codeList
        .add('public class ${impl_auth_controller_name} : AuthImplInterface');
    codeList.add('{');
    codeList.add('}');
    codeList.add('}');
    NsgGenCSProject.indentCode(codeList);
    var fn =
        '${nsgGenerator.cSharpPath}/Controllers/${impl_auth_controller_name}.cs';
    if (!File(fn).existsSync()) {
      await File(fn).writeAsString(codeList.join('\n'));
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
      codeList.add("export '${_.genDataItem.typeName}.dart';");
      codeList.add(
          "export '${nsgGenerator.genPathName}/${_.genDataItem.typeName}.g.dart';");
    });

    await File(
            '${nsgGenerator.dartPath}/${nsgGenerator.getDartName(class_name)}Model.dart')
        .writeAsString(codeList.join('\n'));
  }

  Future generateInitController(NsgGenerator nsgGenerator) async {
    //----------------------------------------------------------
    //generate service class ControllerName.g.dart
    //----------------------------------------------------------
    var codeList = <String>[];
    codeList.add("import 'package:get/get.dart';");
    codeList.add("import 'package:nsg_data/nsg_data.dart';");
    codeList
        .add("import '../${nsgGenerator.getDartName(class_name)}Model.dart';");
    codeList.add('');
    codeList.add('class ${class_name}Generated extends NsgBaseController {');
    codeList.add('  NsgDataProvider? provider;');
    codeList.add('  @override');
    codeList.add('  Future onInit() async {');
    codeList.add('    if (provider == null) {');
    codeList.add('      provider = NsgDataProvider();');
    codeList.add('    }');
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
    codeList.add('  ');
    codeList.add('  Future loadData() async {');
    codeList.add(
        '    change(NsgBaseControllerData(), status: RxStatus.success());');
    codeList.add('    sendNotify();');
    codeList.add('  }');

    codeList.add('}');

    await File('${nsgGenerator.dartPathGen}/${class_name}.g.dart')
        .writeAsString(codeList.join('\n'));

    //----------------------------------------------------------
    //generate main class ControllerName.dart
    //----------------------------------------------------------
    codeList = <String>[];
    //codeList.add("import '${nsgGenerator.getDartName(class_name)}Model.dart';");
    codeList.add("import '${nsgGenerator.genPathName}/${class_name}.g.dart';");
    codeList.add('');
    codeList.add('class ${class_name} extends ${class_name}Generated {');
    codeList.add('');
    codeList
        .add('  ${class_name}(NsgDataProvider provider) : super(provider);');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  Future loadData() async {');
    codeList.add('    super.loadData();');
    codeList.add('  }');

    codeList.add('}');

    var fn = '${nsgGenerator.dartPath}/${class_name}.dart';
    if (!File(fn).existsSync()) {
      await File(fn).writeAsString(codeList.join('\n'));
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
  }
}
