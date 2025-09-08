import 'nsgCodeGenerator.dart';
import 'nsgGeneratorArgs.dart';

void main(List<String> args) async {
  var nsgArgs = NsgGeneratorArgs();

  var project = Project.Tech2Server;

  nsgArgs.serviceConfigPath = project.configPath;
  nsgArgs.cSharpPath = project.csPath;
  nsgArgs.doCSharp = project.doCSharp;
  nsgArgs.dartPath = project.dartPath;
  nsgArgs.doDart = project.doDart;

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
  static Project ScifStorekeeper = Project(
      'C:/Users/pro5/source/repos/scif_storekeeper_server/model_config',
      'C:/Users/pro5/source/repos/scif_storekeeper_server',
      'C:/Users/pro5/source/repos/scif_storekeeper_app/lib/model');
  static Project TechControl = Project(
      'C:/Users/pro5/source/repos/TechControl/Server/GeneratorConfig',
      'C:/Users/pro5/source/repos/TechControl/Server',
      'C:/Users/pro5/source/repos/TechControl/tech_control_app/lib/model');
  static Project Football = Project(
      'C:/Users/pro5/source/repos/FootballersDiary_Server/FootballersDiary/GeneratorConfig',
      'C:/Users/pro5/source/repos/FootballersDiary_Server/FootballersDiary',
      'C:/Users/pro5/source/repos/footballers_diary_app/lib/model');
  static Project Tech2Server = Project('D:/NSG/GIT/Tech2Server/json',
      'D:/NSG/GIT/Tech2Server/', 'D:/NSG/GIT/tech2_app/lib/model');
  static Project Storekeeper = Project(
      'C:/Users/pro5/source/repos/StorekeeperServer/model_config',
      'C:/Users/pro5/source/repos/StorekeeperServer',
      'C:/Users/pro5/source/repos/StorekeeperClient/lib/model');
  static Project OneClick = Project(
      'C:/Users/pro5/source/repos/oneclick_server/model_config',
      'C:/Users/pro5/source/repos/oneclick_server',
      'C:/Users/pro5/source/repos/oneclick_app/lib/model');
  static Project NsgTimerApp = Project(
      'C:/Users/pro5/source/repos/nsg_timer_server/json',
      'C:/Users/pro5/source/repos/nsg_timer_server',
      'C:/Users/pro5/source/repos/nsg_timer_app/lib/model');
  static Project TaskManager = Project(
      'C:/Users/pro5/source/repos/task_manager_server/json',
      'C:/Users/pro5/source/repos/task_manager_server',
      'C:/Users/pro5/source/repos/task_manager_app/lib/model');
  static Project Titan112Button = Project(
      'C:/Users/pro5/source/repos/titan112button/serviceConfig',
      'C:/Users/pro5/source/repos/titan112button_server/',
      'C:/Users/pro5/source/repos/titan112button/lib/model/');
  static Project TitanLK = Project(
      'C:/Users/pro5/source/repos/titan_lk_server/json',
      'C:/Users/pro5/source/repos/titan_lk_server',
      'C:/Users/pro5/source/repos/titan_lk_app/lib/model');
  static Project Answerzz = Project(
      'C:/Users/pro5/source/repos/answerzz_server/model_config',
      'C:/Users/pro5/source/repos/answerzz_server',
      'C:/Users/pro5/source/repos/answerzz_app/lib/model');
  static Project BonPlant = Project(
      'C:/Users/pro5/source/repos/bon_plant_server/json',
      'C:/Users/pro5/source/repos/bon_plant_server',
      'C:/Users/pro5/source/repos/bon_plant_app/lib/model');
  static Project SalAd = Project(
      'C:/Users/pro5/source/repos/sal_ad_server/GenerationConfig',
      'C:/Users/pro5/source/repos/sal_ad_server',
      'C:/Users/pro5/source/repos/sal_ad_app_a/lib/model');
  static Project CognitiveTraining = Project(
      'C:/Users/pro5/source/repos/cognitive_training/json',
      'C:/Users/pro5/source/repos/cognitive_training_server',
      'C:/Users/pro5/source/repos/cognitive_training/lib/model');
  static Project NsgChats = Project(
      'C:/Users/pro5/source/repos/nsg_chats_server/GenerationConfig',
      'C:/Users/pro5/source/repos/nsg_chats_server',
      '',
      doDart: false);
  static Project TestProj = Project('C:/Users/pro5/source/repos/test_proj/json',
      '', 'C:/Users/pro5/source/repos/test_proj/lib/model');
  static Project NsgLocalization = Project(
      'C:/Users/pro5/source/repos/nsg_localization_server/json', '', '');
  static Project ScifForklift = Project(
      'C:/Users/pro5/source/repos/scif_forklift_server/json',
      'C:/Users/pro5/source/repos/scif_forklift_server',
      'C:/Users/pro5/source/repos/scif_forklift_app/lib/model');
  static Project GPT = Project(
      'C:/Users/pro5/source/repos/ChatGPTServer/GenerationConfig',
      'C:/Users/pro5/source/repos/ChatGPTServer',
      '',
      doDart: false);
  String configPath;
  String csPath;
  String dartPath;
  bool doCSharp = true;
  bool doDart = true;
  Project(this.configPath, this.csPath, this.dartPath, {doCSharp, doDart});
}
