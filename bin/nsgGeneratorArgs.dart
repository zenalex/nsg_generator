class NsgGeneratorArgs {
  /// путь к папке
  String serviceConfigPath = '';

  ///путь для генерации C#
  String cSharpPath = '';

  ///путь для генерации dart
  String dartPath = '';

  /// принудительная перезапись
  bool forceOverwrite = false;

  /// генерировать C#
  bool doCSharp = true;

  /// генерировать dart
  bool doDart = true;

  /// если в папке найден файл .csproj, копировать
  bool copyCsproj = false;

  /// если в папке найден файл Program.cs, копировать
  bool copyProgramCs = false;

  /// если в папке найден файл Startup.cs, копировать
  bool copyStartupCs = false;
}
