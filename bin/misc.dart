class Misc {
  static void indentCSharpCode(List<String> codeList) {
    var indentMultiplier = 0;
    for (var i = 0; i < codeList.length; i++) {
      if (codeList[i].startsWith('}')) {
        indentMultiplier--;
        codeList[i] = ('    ' * indentMultiplier) + codeList[i];
      } else {
        var isComment = codeList[i].startsWith('//');
        codeList[i] = ('    ' * indentMultiplier) + codeList[i];
        if (!isComment) {
          if (codeList[i].contains('{')) indentMultiplier++;
          if (codeList[i].contains('}')) indentMultiplier--;
        }
      }
    }
  }

  static RegExp nonUpperCaseRE = RegExp(r'[^A-ZА-Я]');
  static String getDartName(String dn) {
    if (dn.isEmpty) return dn;
    var firstLowerCaseIndex = dn.indexOf(nonUpperCaseRE);
    if (firstLowerCaseIndex == -1) {
      return dn.toLowerCase();
    }
    if (firstLowerCaseIndex == 0) {
      return dn;
    }
    if (firstLowerCaseIndex > 1) firstLowerCaseIndex--;
    var fc = dn.substring(0, firstLowerCaseIndex);
    if (fc.length != dn.length) {
      dn = fc.toLowerCase() + dn.substring(firstLowerCaseIndex);
    }
    return dn;
  }

  static String getDartUnderscoreName(String dn) {
    if (dn.isEmpty) return dn;
    var exp = RegExp(r'(?<=[a-zA-Z])((?<=[a-z])|(?=[A-Z][a-z]))[A-Z]');
    dn = dn
        .replaceAllMapped(exp, (Match m) => ('_' + (m.group(0) ?? '')))
        .toLowerCase();
    return dn;
  }

  static RegExp csToStringRE = RegExp(r'{((\w+)([.](\w+)(\(.*\))?)*){1,}}');
  static String getDartToString(String presentation) {
    if (presentation.contains(csToStringRE)) {
      var allMatches = csToStringRE.allMatches(presentation);
      allMatches.forEach((match) {
        var s = match[0]!; //.toString();
        if (s.contains('.')) {
          var sSplit = s.substring(1, s.length - 1).split('.');
          var sMap = sSplit.map((e) => Misc.getDartName(e));
          var sReplacement = '{' + sMap.join('.') + '}';
          presentation = presentation.replaceFirst(
              s, '\$' + sReplacement.replaceAll('\"', '\''));
        } else {
          presentation = presentation.replaceFirst(
              s, '\$' + Misc.getDartName(s.substring(1, s.length - 1)));
        }
        print(s);
      });
      print(allMatches.length);
    }
    return Misc.getDartName('\'' + presentation + '\'');
  }

  static void writeDescription(List<String> codeList, String text, bool xmlWrap,
      {int indent = 0}) {
    if (text.isEmpty) return;
    if (xmlWrap) {
      codeList.add('${' ' * indent}/// <summary>');
    }
    text.split('\n').forEach((descLine) {
      codeList.add('${' ' * indent}/// $descLine');
    });
    if (xmlWrap) {
      codeList.add('${' ' * indent}/// </summary>');
    }
  }

  static String CamelCaseToNormal(String s) {
    if (s.isEmpty) return s;
    var exp = RegExp(
        r'(?<=[a-zA-Zа-яА-Я])((?<=[a-zа-я])|(?=[A-ZА-Я][a-zа-я]))[A-ZА-Я]');
    s = s.replaceAllMapped(
        exp, (Match m) => (' ' + (m.group(0) ?? '').toLowerCase()));
    return s;
  }

  static String cutTableRowTypeNameEnding(String typeName) =>
      typeName.replaceAll(RegExp(r"[.]Строка"), '');

  static bool needToSpecifyType(String typeName) =>
      typesNeedingReferenceType.any((el) => typeName.startsWith(el));

  static List<String> typesNeedingReferenceType = ['Reference', 'List', 'Enum'];

  static bool isPrimitiveType(String typeName) =>
      primitiveTypes.any((el) => typeName.contains(el));

  static List<String> primitiveTypes = [
    'UntypedReference',
    'Enum',
    'int',
    'double',
    'String',
    'Guid',
    'bool',
    'DateTime',
    'Image',
    'Binary'
  ];
}
