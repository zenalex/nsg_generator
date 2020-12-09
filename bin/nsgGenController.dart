import 'dart:io';
import 'dart:async';

import 'nsgGenMethod.dart';
import 'nsgGenerator.dart';

class NsgGenController {
  final String api_prefix;
  final String class_name;
  final String dataType;
  final String serverUri;
  final bool useAuthorization;
  final List<NsgGenMethod> methods;

  NsgGenController(
      {this.api_prefix,
      this.class_name,
      this.dataType,
      this.serverUri,
      this.useAuthorization,
      this.methods});

  factory NsgGenController.fromJson(Map<String, dynamic> parsedJson) {
    return NsgGenController(
        api_prefix: parsedJson['api_prefix'],
        class_name: parsedJson['class_name'],
        dataType: parsedJson['dataType'],
        serverUri: parsedJson['serverUri'],
        useAuthorization: parsedJson['useAuthorization'] == 'true',
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
    codeList.add('using Microsoft.AspNetCore.Authorization;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('  /// <summary>');
    codeList.add('  ///${dataType}Interface Controller');
    codeList.add('  /// </summary>');
    codeList.add('  [ApiController]');
    codeList.add('  [Route("${api_prefix}")]');
    codeList.add('  public class ${class_name} : ControllerBase');
    codeList.add('  {');

    codeList.add('    ${class_name}Interface controller;');
    codeList.add('    AuthImplInterface authController;');

    codeList.add('    private readonly ILogger<${class_name}> _logger;');
    codeList.add('    public ${class_name}(ILogger<${class_name}> logger)');
    codeList.add('    {');
    codeList.add('      _logger = logger;');
    codeList.add('      #if (Real)');
    codeList.add('        controller = new ${class_name}Real();');
    codeList.add('        authController = new AuthControllerReal();');
    codeList.add('      #else');
    codeList.add('        controller = new ${class_name}Mock();');
    codeList.add('        authController = new AuthImplMock();');
    codeList.add('      #endif');
    codeList.add('    }');
    codeList.add('    ');

    await Future.forEach<NsgGenMethod>(methods, (element) async {
      await element.generateCode(codeList, nsgGenerator, this, element);
    });

    codeList.add('  }');
    codeList.add('}');

    var fn = '${nsgGenerator.cSharpPath}/${class_name}.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\n'));
    //}
    await generateInterfaceData(nsgGenerator);
    await generateCodeDart(nsgGenerator);
  }

  void generateInterfaceData(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    codeList.add('using System;');
    codeList.add('using System.Collections.Generic;');
    codeList.add('using System.IO;');
    codeList.add('using System.Net;');
    codeList.add('using System.Net.Http;');
    codeList.add('using System.Net.Http.Headers;');
    codeList.add('using ${nsgGenerator.cSharpNamespace};');
    codeList.add('using NsgServerClasses;');
    codeList.add('');
    codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
    codeList.add('{');
    codeList.add('  public interface ${class_name}Interface');
    codeList.add('  {');

    methods.forEach((_) {
      if (_.authorize != 'none') {
        codeList.add(
            '    public IEnumerable<${_.genDataItem.typeName}> ${_.name}(INsgTokenExtension user);');
      } else {
        codeList.add(
            '    public IEnumerable<${_.genDataItem.typeName}> ${_.name}();');
      }
    });

    codeList.add('  }');
    codeList.add('}');

    var fn = '${nsgGenerator.cSharpPath}/${class_name}Interface.cs';
    //if (!File(fn).existsSync()) {
    await File(fn).writeAsString(codeList.join('\n'));
    //}
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
    codeList.add('class ${class_name}Generated extends GetxController');
    codeList.add('    with StateMixin<NsgBaseControllerData> {');
    codeList.add('  NsgDataProvider provider;');
    codeList.add('  @override');
    codeList.add('  void onInit() async {');
    codeList.add('    if (provider == null) {');
    codeList.add('      provider = NsgDataProvider();');
    codeList.add("      provider.serverUri = '${serverUri}';");
    addRegisterDataItems(nsgGenerator, codeList);
    codeList.add('      provider.useNsgAuthorization = ${useAuthorization};');
    codeList.add('      await provider.connect();');
    if (useAuthorization) {
      codeList.add('      if (provider.isAnonymous) {');
      codeList.add('        await Get.to(NsgPhoneLoginPage(provider,');
      codeList
          .add('          widgetParams: NsgPhoneLoginParams.defaultParams))');
      codeList.add('          .then((value) => loadData());');
      codeList.add('      } else {');

      codeList.add('        await loadData();');
      codeList.add('      }');
    } else {
      codeList.add('        await loadData();');
    }
    codeList.add('    }');
    codeList.add('    super.onInit();');
    codeList.add('  }');
    codeList.add('  ');
    codeList.add('  Future loadData() async {');
    codeList.add(
        '    change(NsgBaseControllerData(), status: RxStatus.success());');
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
