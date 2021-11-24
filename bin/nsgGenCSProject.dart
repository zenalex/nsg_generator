import 'dart:io';

import 'nsgGenerator.dart';

class NsgGenCSProject {
  static void generateProject(NsgGenerator nsgGenerator) {
    _generateCsproj(nsgGenerator);
    _generateProgramCS(nsgGenerator);
    _generateStartupCS(nsgGenerator);
  }

  static void _generateCsproj(NsgGenerator nsgGenerator) {
    var file = File(
        nsgGenerator.cSharpPath + '/${nsgGenerator.cSharpNamespace}.csproj');
    if (file.existsSync()) return;
    var targetFramework = nsgGenerator.targetFramework ?? 'net5.0';
    if (targetFramework.isEmpty) targetFramework = 'net5.0';
    print('generating .csproj');
    // TODO: store .csproj in the target /serviceConfig
    var codeList = <String>[];
    codeList.add('<Project Sdk="Microsoft.NET.Sdk.Web">');
    codeList.add('');
    codeList.add('  <PropertyGroup>');
    codeList.add('    <TargetFramework>${targetFramework}</TargetFramework>');
    codeList.add('  </PropertyGroup>');
    codeList.add('');
    codeList.add(
        '  <PropertyGroup Condition="\'\$(Configuration)|\$(Platform)\'==\'Debug|AnyCPU\'">');
    codeList.add('    <DefineConstants>TRACE;Real</DefineConstants>');
    codeList.add('  </PropertyGroup>');
    codeList.add('');
    codeList.add('  <ItemGroup>');
    codeList.add('    <Reference Include="NsgServerClasses">');
    codeList.add(
        '      <HintPath>..\\..\\NsgServerClasses\\bin\\Debug\\${targetFramework}\\NsgServerClasses.dll</HintPath>');
    codeList.add('    </Reference>');
    codeList.add('  </ItemGroup>');
    codeList.add('');
    codeList.add('  <ItemGroup>');
    codeList.add('    <Folder Include="Controllers\\" />');
    codeList.add('    <Folder Include="Models\\" />');
    codeList.add('  </ItemGroup>');
    codeList.add('');
    codeList.add('  <ItemGroup>');
    if (targetFramework != 'net5.0') {
      codeList.add(
          '    <PackageReference Include="Microsoft.AspNetCore.HttpsPolicy" Version="2.2.0" />');
      codeList.add(
          '    <PackageReference Include="Microsoft.Owin.Diagnostics" Version="4.2.0" />');
      codeList.add(
          '    <PackageReference Include="Microsoft.Owin.Host.SystemWeb" Version="4.2.0" />');
      codeList.add(
          '    <PackageReference Include="Microsoft.AspNet.Cors" Version="5.2.7" />');
      codeList.add(
          '    <PackageReference Include="Microsoft.AspNet.WebApi.Cors" Version="5.2.7" />');
      codeList.add(
          '    <PackageReference Include="Microsoft.AspNetCore.Cors" Version="2.2.0" />');
      codeList.add(
          '    <PackageReference Include="Microsoft.Owin.Cors" Version="4.2.0" />');
    }
    codeList.add(
        '    <PackageReference Include="Microsoft.AspNet.WebApi.OwinSelfHost" Version="5.2.7" />');
    codeList.add(
        '    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="' +
            (targetFramework == 'net5.0' ? '5.0.7' : '3.1.21') +
            '" />');
    codeList.add(
        '    <PackageReference Include="Microsoft.IdentityModel.Tokens" Version="6.11.1" />');
    codeList.add('  </ItemGroup>');
    codeList.add('');
    codeList.add('');
    codeList.add('</Project>');
    file.writeAsString(codeList.join('\n'));
  }

  static void _generateProgramCS(NsgGenerator nsgGenerator) {
    var file = File(nsgGenerator.cSharpPath + '/Program.cs');
    if (file.existsSync()) return;
    print('generating Program.cs');
    // TODO: store Program.cs in the target /serviceConfig
    var codeList = <String>[];
    if (nsgGenerator.targetFramework == 'net5.0') {
      codeList.add('using Microsoft.AspNetCore.Hosting;');
      codeList.add('using Microsoft.Extensions.Configuration;');
      codeList.add('using Microsoft.Extensions.Hosting;');
      codeList.add('using Microsoft.Extensions.Logging;');
      codeList.add('using System;');
      codeList.add('using System.Collections.Generic;');
      codeList.add('using System.Linq;');
      codeList.add('using System.Threading.Tasks;');
      codeList.add('');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public class Program');
      codeList.add('{');
      codeList.add('public static void Main(string[] args)');
      codeList.add('{');
      codeList.add('CreateHostBuilder(args).Build().Run();');
      codeList.add('}');
      codeList.add('');
      codeList.add(
          'public static IHostBuilder CreateHostBuilder(string[] args) =>');
      codeList.add('    Host.CreateDefaultBuilder(args)');
      codeList.add('        .ConfigureWebHostDefaults(webBuilder =>');
      codeList.add('        {');
      codeList.add('        webBuilder.UseStartup<Startup>();');
      codeList.add('        });');
      codeList.add('}');
      codeList.add('}');
    } else {
      codeList.add('using Microsoft.Owin.Hosting;');
      codeList.add('using System;');
      codeList.add('');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('class Program');
      codeList.add('{');
      codeList.add('public static void Main(string[] args)');
      codeList.add('{');
      codeList.add('string baseAddress = "http://127.0.0.1:5000/";');
      codeList.add('using (WebApp.Start<Startup>(url: baseAddress))');
      codeList.add('{');
      codeList.add('Console.ReadLine();');
      codeList.add('}');
      codeList.add('}');
      codeList.add('}');
      codeList.add('}');
    }
    indentCode(codeList);
    file.writeAsString(codeList.join('\n'));
  }

  static void _generateStartupCS(NsgGenerator nsgGenerator) {
    var file = File(nsgGenerator.cSharpPath + '/Startup.cs');
    if (file.existsSync()) return;
    print('generating Startup.cs');
    // TODO: store Startup.cs in the target /serviceConfig
    var codeList = <String>[];
    if (nsgGenerator.targetFramework == 'net5.0') {
      codeList.add('using Microsoft.AspNetCore.Builder;');
      codeList.add('using Microsoft.AspNetCore.Hosting;');
      codeList.add('using Microsoft.AspNetCore.HttpsPolicy;');
      codeList.add('using Microsoft.AspNetCore.Mvc;');
      codeList.add('using Microsoft.Extensions.Configuration;');
      codeList.add('using Microsoft.Extensions.DependencyInjection;');
      codeList.add('using Microsoft.Extensions.Hosting;');
      codeList.add('using Microsoft.Extensions.Logging;');
      codeList.add('using System;');
      codeList.add('using System.Collections.Generic;');
      codeList.add('using System.Linq;');
      codeList.add('using System.Threading.Tasks;');
      codeList.add('');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public class Startup');
      codeList.add('{');
      codeList.add('public Startup(IConfiguration configuration)');
      codeList.add('{');
      codeList.add('Configuration = configuration;');
      codeList.add('}');
      codeList.add('');
      codeList.add('public IConfiguration Configuration { get; }');
      codeList.add('');
      codeList.add(
          '// This method gets called by the runtime. Use this method to add services to the container.');
      codeList
          .add('public void ConfigureServices(IServiceCollection services)');
      codeList.add('{');
      codeList.add('services.AddControllers();');
      codeList.add('services.AddCors(options =>');
      codeList.add('{');
      codeList.add('options.AddPolicy(name: "AllowAll",');
      codeList.add('    builder =>');
      codeList.add('    {');
      codeList.add('    builder.AllowAnyOrigin().AllowAnyHeader()');
      codeList.add(
          '           .WithMethods("GET", "POST", "OPTIONS", "PUT", "DELETE");');
      codeList.add('    });');
      codeList.add('});');
      codeList.add('}');
      codeList.add('');
      codeList.add(
          '// This method gets called by the runtime. Use this method to configure the HTTP request pipeline.');
      codeList.add(
          'public void Configure(IApplicationBuilder app, IWebHostEnvironment env)');
      codeList.add('{');
      codeList.add('if (env.IsDevelopment())');
      codeList.add('{');
      codeList.add('app.UseDeveloperExceptionPage();');
      codeList.add('}');
      codeList.add('');
      codeList.add('app.UseHttpsRedirection();');
      codeList.add('');
      codeList.add('app.UseRouting();');
      codeList.add('');
      codeList.add('app.UseCors("AllowAll");');
      codeList.add('');
      codeList.add('app.UseAuthorization();');
      codeList.add('');
      codeList.add('app.UseEndpoints(endpoints =>');
      codeList.add('{');
      codeList.add('endpoints.MapControllers();');
      codeList.add('});');
      codeList.add('}');
      codeList.add('}');
      codeList.add('}');
    } else {
      codeList.add('using Microsoft.Owin;');
      codeList.add('using Owin;');
      codeList.add('using System.Web.Http;');
      codeList.add('using System.Web.Http.Cors;');
      codeList.add('');
      codeList.add('namespace ${nsgGenerator.cSharpNamespace}');
      codeList.add('{');
      codeList.add('public class Startup');
      codeList.add('{');
      codeList.add('public void Configuration(IAppBuilder app)');
      codeList.add('{');
      codeList.add('app.UseErrorPage();');
      codeList.add('HttpConfiguration config = new HttpConfiguration();');
      codeList.add('');
      codeList.add(
          'config.EnableCors(new EnableCorsAttribute("*", "*", "GET, POST, OPTIONS, PUT, DELETE"));');
      codeList.add('app.UseCors(Microsoft.Owin.Cors.CorsOptions.AllowAll);');
      codeList.add('');
      codeList.add('config.MapHttpAttributeRoutes();');
      codeList.add('config.Routes.MapHttpRoute(');
      codeList.add('    name: "DefaultApi",');
      codeList.add('    routeTemplate: "api/{controller}/{action}/{id}",');
      codeList.add('    defaults: new { id = RouteParameter.Optional }');
      codeList.add(');');
      codeList.add('app.UseWebApi(config);');
      codeList.add('}');
      codeList.add('}');
      codeList.add('}');
    }
    indentCode(codeList);
    file.writeAsString(codeList.join('\n'));
  }

  static void indentCode(List<String> codeList) {
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
}
