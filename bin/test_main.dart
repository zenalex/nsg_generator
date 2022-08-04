import 'nsgCodeGenerator.dart';
import 'nsgGeneratorArgs.dart';

void main(List<String> args) async {
  var nsgArgs = NsgGeneratorArgs();

  var project = Project.Scif;

  nsgArgs.serviceConfigPath = project.configPath;
  nsgArgs.cSharpPath = project.csPath;
  nsgArgs.doCSharp = true;
  nsgArgs.dartPath = project.dartPath;
  nsgArgs.doDart = true;

  nsgArgs.copyCsproj = false;
  nsgArgs.copyProgramCs = false;
  nsgArgs.copyStartupCs = false;

  startGenerator(nsgArgs);
}

class Project {
  static Project Scif = Project(
      'C:/Users/pro5/source/repos/scif_app_server/model_config',
      'C:/Users/pro5/source/repos/scif_app_server',
      'C:/Users/pro5/source/repos/scif_app/lib/model');
  static Project TechControl = Project(
      'C:/Users/pro5/source/repos/TechControl/Server/GeneratorConfig',
      'C:/Users/pro5/source/repos/TechControl/Server',
      'C:/Users/pro5/source/repos/TechControl/tech_control_app/lib/model');
  static Project Football = Project(
      'C:/Users/pro5/source/repos/FootballersDiary_Server/FootballersDiary/GeneratorConfig',
      'C:/Users/pro5/source/repos/FootballersDiary_Server/FootballersDiary',
      'C:/Users/pro5/source/repos/footballers_diary_app/lib/model');
  static Project Tech2Server = Project(
      'C:/Users/pro5/source/repos/Tech2Server/json',
      'C:/Users/pro5/source/repos/Tech2Server',
      'C:/Users/pro5/source/repos/tech2_app/lib/model');
  static Project Storekeeper = Project(
      'C:/Users/pro5/source/repos/StorekeeperServer/model_config',
      'C:/Users/pro5/source/repos/StorekeeperServer',
      'C:/Users/pro5/source/repos/StorekeeperClient/lib/model');
  String configPath;
  String csPath;
  String dartPath;
  Project(this.configPath, this.csPath, this.dartPath);
}
