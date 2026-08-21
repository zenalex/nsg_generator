import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'misc.dart';
import 'nsgGenerator.dart';

class NsgGenEnum {
  /// Имя файла-аксессора локализации, который эмитится рядом с
  /// перечислениями.
  ///
  /// Аксессор нужен потому, что геттеры перечислений читают локализованное
  /// имя сразу, а вызываются в том числе вне дерева виджетов (фоновая
  /// догрузка, permanent-контроллеры, обработка событий сокета). Там
  /// Get.context == null, и прямое AppLocalizations.of(Get.context!) падает
  /// с "Null check operator used on a null value".
  static const localizationAccessorFile = '_enum_localization.dart';

  /// Имя геттера в этом файле.
  static const localizationAccessor = 'enumTran';

  final String className;
  final String dataTypeFile;
  final bool useLocalization;
  String description;
  List<NsgGenEnumItem>? values;

  NsgGenEnum(
      {required this.className,
      required this.dataTypeFile,
      required this.useLocalization,
      this.description = ''});

  factory NsgGenEnum.fromJson(Map<String, dynamic> parsedJson) {
    Misc.checkObsoleteKeysInJSON(
        'enum', parsedJson, {'class_name': 'className'},
        throwIfAny: true);
    return NsgGenEnum(
        className: parsedJson['className'],
        dataTypeFile: parsedJson['dataTypeFile'] ?? '',
        useLocalization: Misc.parseBool(parsedJson['useLocalization']),
        description: parsedJson['description'] ?? '');
  }

  Future load(NsgGenerator nsgGenerator) async {
    //print('$className Enum initializing');
    var text =
        await File('${nsgGenerator.jsonPath}/$dataTypeFile').readAsString();
    var parsedEnumJson = json.decode(text);
    values = (parsedEnumJson['values'] as List)
        .map((i) => NsgGenEnumItem(
            codeName: i['codeName'],
            name: i['name'] ?? i['codeName'],
            value: i['value']))
        .toList();
    //print('$className Enum initialized');
  }

  Future generateCode(NsgGenerator nsgGenerator) async {
    var currentStage = 'C#';
    try {
      if (nsgGenerator.doCSharp) {
        var codeList = <String>[];
        codeList.add('using System;');
        codeList.add('using System.Collections.Generic;');
        codeList.add('using System.Linq;');
        codeList.add('using NsgServerClasses;');
        codeList.add('');
        Misc.writeThisFileIsGeneratedServer(codeList);
        codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
        codeList.add('{');
        if (description.isNotEmpty) {
          Misc.writeDescription(codeList, description, true);
        }
        codeList.add('public class $className : NsgServerEnum');
        codeList.add('{');
        assert(values != null);
        values!.forEach((i) {
          codeList.add(
              'public static $className ${i.codeName} { get; } = new $className(${i.value}, "${i.name}");');
        });
        codeList.add('');
        codeList.add(
            'private $className(int val, string name) : base(val, name) { }');
        codeList.add('');
        codeList.add('public static IEnumerable<$className> List()');
        codeList.add('{');
        codeList.add(
            'return new[] { ${values!.map((e) => e.codeName).join(', ')} };');
        codeList.add('}');
        codeList.add('');
        codeList.add('public static explicit operator $className(string name)');
        codeList.add('{');
        codeList.add('foreach ($className i in List())');
        codeList.add('{');
        codeList.add(
            'if (string.Equals(i.Name, name, StringComparison.OrdinalIgnoreCase))');
        codeList.add('    return i;');
        codeList.add('}');
        codeList.add('return null;');
        codeList.add('}');
        codeList.add('');
        codeList.add('public static explicit operator $className(int value)');
        codeList.add('{');
        codeList.add('foreach ($className i in List())');
        codeList.add('{');
        codeList.add('if (i.Value == value)');
        codeList.add('    return i;');
        codeList.add('}');
        codeList.add('return null;');
        codeList.add('}');
        codeList.add('}');
        codeList.add('}');
        Misc.indentCSharpCode(codeList);

        var fn = '${nsgGenerator.cSharpPath}/Enums/$className.cs';
        //if (!File(fn).existsSync()) {
        await Misc.writeFileIfChanged(fn, codeList.join('\r\n'));
        //}
      }
      if (nsgGenerator.doDart) {
        currentStage = 'Dart';
        await generateCodeDart(nsgGenerator);
      }
    } catch (e) {
      print('--- ERROR generating $currentStage enum $className ---');
      rethrow;
    }
  }

  Future generateCodeDart(NsgGenerator nsgGenerator) async {
    await generateEnumDart(nsgGenerator);
  }

  static Future generateEnums(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    if (enums.isEmpty) return;
    await Future.forEach<NsgGenEnum>(enums, (element) async {
      print('loading ${element.className}');
      await element.load(nsgGenerator);
    });
    await Future.forEach<NsgGenEnum>(enums, (element) async {
      print('generating ${element.className}');
      await element.generateCode(nsgGenerator);
    });
    if (nsgGenerator.doDart) {
      await generateExportFile(nsgGenerator, enums);
      await generateLocalizationAccessorFile(nsgGenerator, enums);
    }
  }

  static Future generateExportFile(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    List<String> codeList;

    var filePath = '${nsgGenerator.dartPath}/enums.dart';
    var file = File(filePath);
    if (await file.exists()) {
      codeList = await file.readAsLines();
    } else {
      codeList = <String>[];
    }

    enums.forEach((_) {
      var item =
          "export 'enums/${Misc.getDartUnderscoreName(_.className)}.dart';";
      if (!codeList.contains(item)) {
        codeList.add(item);
      }
    });

    await Misc.writeFileIfChanged(
        '${nsgGenerator.dartPath}/enums.dart', codeList.join('\r\n'));
  }

  /// Эмитит рядом с перечислениями файл с безопасным аксессором локализации.
  ///
  /// Пустую строку при отсутствии контекста возвращать нельзя: initialize()
  /// заполняет NsgEnum.listAllValues этими же геттерами, и один вызов без
  /// имени закеширует ВСЕ имена перечисления пустыми до перезапуска
  /// приложения. Поэтому фолбэк идёт на локаль: сначала Get.locale, затем
  /// defaultLocale проекта (язык arb-шаблона).
  static Future generateLocalizationAccessorFile(
      NsgGenerator nsgGenerator, List<NsgGenEnum> enums) async {
    if (!nsgGenerator.useLocalization &&
        !enums.any((e) => e.useLocalization)) {
      return;
    }

    var codeList = <String>[];
    Misc.writeThisFileIsGeneratedClient(codeList);
    codeList.add('import \'package:flutter/widgets.dart\';');
    codeList.add('import \'package:get/get.dart\';');
    codeList.add('import \'../../l10n/app_localizations.dart\';');
    codeList.add('');
    codeList.add('/// Локализация для автогенерируемых перечислений.');
    codeList.add('///');
    codeList.add(
        '/// Контекст здесь только предпочтителен: геттеры перечислений');
    codeList.add(
        '/// вызываются и вне дерева виджетов, где Get.context == null.');
    codeList.add(
        '/// Нет контекста - имя берётся по текущей локали GetX, нет и её');
    codeList.add(
        '/// (или язык не поддерживается) - по локали-шаблону проекта.');
    codeList.add('AppLocalizations get $localizationAccessor {');
    codeList.add('  final ctx = Get.context;');
    codeList.add(
        '  final fromContext = ctx != null ? AppLocalizations.of(ctx) : null;');
    codeList.add('  if (fromContext != null) return fromContext;');
    codeList.add(
        '  return lookupAppLocalizations(_supportedLocale(Get.locale));');
    codeList.add('}');
    codeList.add('');
    codeList.add(
        'const Locale _fallbackLocale = Locale(\'${nsgGenerator.defaultLocale}\');');
    codeList.add('');
    codeList.add('Locale _supportedLocale(Locale? locale) {');
    codeList.add('  if (locale == null) return _fallbackLocale;');
    codeList.add('  final supported = AppLocalizations.supportedLocales');
    codeList.add(
        '      .any((e) => e.languageCode == locale.languageCode);');
    codeList.add('  return supported ? locale : _fallbackLocale;');
    codeList.add('}');
    codeList.add('');

    await Misc.writeFileIfChanged(
        '${nsgGenerator.dartPath}/enums/$localizationAccessorFile',
        codeList.join('\r\n'));
  }

  Future generateEnumDart(NsgGenerator nsgGenerator) async {
    var codeList = <String>[];
    Misc.writeThisFileIsGeneratedClient(codeList);
    if (useLocalization || nsgGenerator.useLocalization) {
      // Локализованное имя берётся через аксессор, а не через
      // AppLocalizations.of(Get.context!): геттеры перечислений вызываются
      // и вне дерева виджетов, где Get.context == null. Сам аксессор
      // эмитится рядом, см. generateLocalizationAccessorFile.
      codeList.add('import \'$localizationAccessorFile\';');
    }
    codeList.add('import \'package:nsg_data/nsg_data.dart\';');
    codeList.add('');
    if (description.isNotEmpty) {
      Misc.writeDescription(codeList, description, false);
    }
    codeList.add('class $className extends NsgEnum {');
    if (useLocalization || nsgGenerator.useLocalization) {
      var lowerCaseClassName = Misc.getDartName(className);
      values!.forEach((i) {
        var iCodeName = Misc.getDartName(i.codeName);
        var localizationKey = '${lowerCaseClassName}_$iCodeName';
        codeList.add(
            '  static $className get ${Misc.getDartName(i.codeName)} => $className(${i.value}, $localizationAccessor.$localizationKey);');
        nsgGenerator.localizationDict[localizationKey] = i.name;
      });
    } else {
      values!.forEach((i) {
        codeList.add(
            '  static $className ${Misc.getDartName(i.codeName)} = $className(${i.value}, \'${i.name}\');');
      });
    }
    codeList.add('');
    codeList.add(
        '  $className(dynamic value, String name) : super(value: value, name: name);');
    codeList.add('');
    codeList.add('  @override');
    codeList.add('  void initialize() {');
    codeList.add('    NsgEnum.listAllValues[runtimeType] = <int, $className>{');
    values!.forEach((v) {
      codeList.add('      ${v.value}: ${Misc.getDartName(v.codeName)},');
    });
    codeList.add('    };');
    codeList.add('  }');
    codeList.add('}');
    codeList.add('');
    await Misc.writeFileIfChanged(
        '${nsgGenerator.dartPath}/enums/${Misc.getDartUnderscoreName(className)}.dart',
        codeList.join('\r\n'));
  }
}

class NsgGenEnumItem {
  final String codeName;
  final String name;
  final dynamic value;

  NsgGenEnumItem(
      {required this.codeName, required this.name, required this.value});
}
