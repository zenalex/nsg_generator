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
}
