import 'dart:io';

import 'package:test/test.dart';

import '../bin/nsgGenDataItem.dart';
import '../bin/nsgGenDataItemField.dart';
import '../bin/nsgGenerator.dart';
import '../bin/nsgGenNetcore.dart';

// 2.1.1/2.1.2: проверка загрузки additive-полей pgTableName/pgColumnName
// и валидации, что pgColumnName для Reference-полей не оканчивается на _id.
// Сам валидатор netcore-режима (validateForNetcoreEmit) поднимается через
// NsgGenerator.fromJson, что требует полного controller-набора и I/O —
// для unit-тестов проверяем парсинг и поле-уровневую валидацию напрямую.

void main() {
  group('NsgGenDataItemField.fromJson — pgColumnName parsing', () {
    test('default empty pgColumnName when absent', () {
      final f = NsgGenDataItemField.fromJson({
        'name': 'Name',
        'type': 'String',
      });
      expect(f.pgColumnName, isEmpty);
    });

    test('reads pgColumnName for scalar field', () {
      final f = NsgGenDataItemField.fromJson({
        'name': 'Name',
        'databaseName': 'Наименование',
        'pgColumnName': 'name',
        'type': 'String',
      });
      expect(f.pgColumnName, equals('name'));
    });

    test('reads pgColumnName for Reference<T> field (semantic, no _id)', () {
      final f = NsgGenDataItemField.fromJson({
        'name': 'Photo',
        'databaseName': 'Фото',
        'pgColumnName': 'photo',
        'type': 'Reference<FileItem>',
      });
      expect(f.pgColumnName, equals('photo'));
    });

    test('rejects pgColumnName ending with _id on Reference<T>', () {
      expect(
        () => NsgGenDataItemField.fromJson({
          'name': 'Photo',
          'databaseName': 'Фото',
          'pgColumnName': 'photo_id',
          'type': 'Reference<FileItem>',
        }),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('must NOT end with "_id"'))),
      );
    });

    test('rejects pgColumnName ending with _id on UntypedReference<...>', () {
      expect(
        () => NsgGenDataItemField.fromJson({
          'name': 'Owner',
          'databaseName': 'Владелец',
          'pgColumnName': 'owner_id',
          'type': 'UntypedReference<UserItem, TeamItem>',
        }),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('must NOT end with "_id"'))),
      );
    });

    test('allows _id-ending pgColumnName on non-Reference fields', () {
      // Скаляр с именем, оканчивающимся на _id — допустимо (например, legacy).
      final f = NsgGenDataItemField.fromJson({
        'name': 'External',
        'databaseName': 'Внешний',
        'pgColumnName': 'external_id',
        'type': 'String',
      });
      expect(f.pgColumnName, equals('external_id'));
    });
  });

  group('NsgGenDataItem.fromJson — pgTableName parsing', () {
    Map<String, dynamic> shopJson({String? pgTable}) => {
          'typeName': 'ShopItem',
          'databaseType': 'Магазины',
          if (pgTable != null) 'pgTableName': pgTable,
          'fields': [
            {
              'name': 'Id',
              'databaseName': 'Идентификатор',
              'pgColumnName': 'id',
              'type': 'String',
              'isPrimary': 'true',
            }
          ],
        };

    test('default empty pgTableName when absent', () {
      final di = NsgGenDataItem.fromJson(shopJson());
      expect(di.pgTableName, isEmpty);
    });

    test('reads pgTableName when present', () {
      final di = NsgGenDataItem.fromJson(shopJson(pgTable: 'shops'));
      expect(di.pgTableName, equals('shops'));
    });

    test('field-level pgColumnName propagates through nested parsing', () {
      final di = NsgGenDataItem.fromJson(shopJson(pgTable: 'shops'));
      expect(di.fields.single.pgColumnName, equals('id'));
    });
  });

  group('NsgGenerator.fromJson — netcoreOutputPath / serverEmitKind', () {
    // Минимальный валидный generator-конфиг с пустыми controller и enums.
    Map<String, dynamic> baseConfig({
      String? serverEmitKind,
      String? netcoreOutputPath,
    }) =>
        {
          'targetFramework': 'net10.0',
          'cSharpNamespace': 'TestNs',
          'cSharpPath': 'out_cs',
          'dartPath': 'out_dart',
          if (serverEmitKind != null) 'serverEmitKind': serverEmitKind,
          if (netcoreOutputPath != null) 'netcoreOutputPath': netcoreOutputPath,
          'controller': <dynamic>[],
        };

    test('default nsgframework mode: netcoreOutputPath optional, parses empty', () {
      final g = NsgGenerator.fromJson(baseConfig());
      expect(g.serverEmitKind, equals(NsgServerEmitKind.nsgframework));
      expect(g.netcoreOutputPath, isEmpty);
    });

    test('nsgframework mode: netcoreOutputPath is read but not required', () {
      // Если автор положил netcoreOutputPath в nsgframework-конфиг — не падаем,
      // поле просто загружается. В nsgframework-эмите оно не используется.
      final g = NsgGenerator.fromJson(
          baseConfig(netcoreOutputPath: 'some/path'));
      expect(g.netcoreOutputPath, equals('some/path'));
    });

    test('netcore mode: netcoreOutputPath required (missing → throw)', () {
      expect(
        () => NsgGenerator.fromJson(baseConfig(serverEmitKind: 'netcore')),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('netcoreOutputPath is required'))),
      );
    });

    test('netcore mode: netcoreOutputPath empty string → throw', () {
      expect(
        () => NsgGenerator.fromJson(
            baseConfig(serverEmitKind: 'netcore', netcoreOutputPath: '')),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('netcoreOutputPath is required'))),
      );
    });

    test('netcore mode: netcoreOutputPath set → loads OK', () {
      final g = NsgGenerator.fromJson(baseConfig(
          serverEmitKind: 'netcore', netcoreOutputPath: 'out_netcore'));
      expect(g.serverEmitKind, equals(NsgServerEmitKind.netcore));
      expect(g.netcoreOutputPath, equals('out_netcore'));
    });

    test('unknown serverEmitKind → throw', () {
      expect(
        () => NsgGenerator.fromJson(baseConfig(serverEmitKind: 'rust')),
        throwsA(predicate(
            (e) => e is Exception && e.toString().contains('not valid'))),
      );
    });
  });

  group('NsgGenNetcore.emitModel / emitConfiguration (raund 2)', () {
    // Минимальный NsgGenerator для эмита — без I/O контроллеров.
    NsgGenerator makeGenerator() {
      return NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'out_cs',
        'dartPath': 'out_dart',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'out_netcore',
        'controller': <dynamic>[],
      });
    }

    // ShopItem из NsgDiscounts (после TASK03). PK + scalar + Reference.
    NsgGenDataItem shopItem() => NsgGenDataItem.fromJson({
          'typeName': 'ShopItem',
          'databaseType': 'Магазины',
          'pgTableName': 'shops',
          'fields': [
            {
              'name': 'Id',
              'databaseName': 'Идентификатор',
              'pgColumnName': 'id',
              'type': 'String',
              'isPrimary': 'true',
            },
            {
              'name': 'Name',
              'databaseName': 'Наименование',
              'pgColumnName': 'name',
              'type': 'String',
            },
            {
              'name': 'Photo',
              'databaseName': 'Фото',
              'pgColumnName': 'photo',
              'type': 'Reference<FileItem>',
            },
          ],
        });

    test('ShopItem model: byte-identical to §2.0.8 reference', () {
      final gen = makeGenerator();
      final di = shopItem();
      final actual = NsgGenNetcore.emitModel(gen, di);
      const expected = '// <auto-generated>\n'
          '//   This file is generated by nsg_generator. Manual edits will be overwritten.\n'
          '// </auto-generated>\n'
          '#nullable enable\n'
          'using System;\n'
          '\n'
          'namespace NsgDiscountsServer.Models;\n'
          '\n'
          'public class ShopItem\n'
          '{\n'
          '    public Guid Id { get; set; }\n'
          '\n'
          '    public string? Name { get; set; }\n'
          '\n'
          '    public Guid? PhotoId { get; set; }\n'
          '    public FileItem? Photo { get; set; }\n'
          '}\n';
      expect(actual, equals(expected));
    });

    test('ShopItem configuration: byte-identical to §2.0.8 reference', () {
      final gen = makeGenerator();
      final di = shopItem();
      final actual = NsgGenNetcore.emitConfiguration(gen, di);
      const expected = '// <auto-generated>\n'
          '//   This file is generated by nsg_generator. Manual edits will be overwritten.\n'
          '// </auto-generated>\n'
          '#nullable enable\n'
          'using Microsoft.EntityFrameworkCore;\n'
          'using Microsoft.EntityFrameworkCore.Metadata.Builders;\n'
          'using NsgDiscountsServer.Models;\n'
          '\n'
          'namespace NsgDiscountsServer.Configurations;\n'
          '\n'
          'public class ShopItemConfiguration : IEntityTypeConfiguration<ShopItem>\n'
          '{\n'
          '    public void Configure(EntityTypeBuilder<ShopItem> builder)\n'
          '    {\n'
          '        // Из pgTableName.\n'
          '        builder.ToTable("shops");\n'
          '\n'
          '        builder.HasKey(x => x.Id);\n'
          '        builder.Property(x => x.Id)\n'
          '            .HasColumnName("id")                 // из pgColumnName\n'
          '            .HasColumnType("uuid");\n'
          '\n'
          '        builder.Property(x => x.Name)\n'
          '            .HasColumnName("name");              // из pgColumnName\n'
          '\n'
          '        // FK: pgColumnName = "photo" + автоматический "_id" суффикс\n'
          '        // (симметрия с Dart-логикой nsgGenDataItemField.dart:76-85).\n'
          '        builder.Property(x => x.PhotoId)\n'
          '            .HasColumnName("photo_id")\n'
          '            .HasColumnType("uuid");\n'
          '\n'
          '        builder.HasOne(x => x.Photo)\n'
          '            .WithMany()\n'
          '            .HasForeignKey(x => x.PhotoId)\n'
          '            .OnDelete(DeleteBehavior.Restrict);\n'
          '    }\n'
          '}\n';
      expect(actual, equals(expected));
    });

    test('fields without databaseName are skipped (UserItem.IsCurrentUser)', () {
      final gen = makeGenerator();
      // Минимальный кейс: одно поле с databaseName, одно без.
      final di = NsgGenDataItem.fromJson({
        'typeName': 'UserItem',
        'databaseType': 'Users',
        'pgTableName': 'users',
        'fields': [
          {
            'name': 'Id',
            'databaseName': 'Id',
            'pgColumnName': 'id',
            'type': 'String',
            'isPrimary': 'true',
          },
          {
            'name': 'Name',
            'databaseName': 'Name',
            'pgColumnName': 'name',
            'type': 'String',
          },
          {
            // Поле БЕЗ databaseName — должно быть пропущено.
            'name': 'IsCurrentUser',
            'type': 'bool',
            'allowPost': false,
            'writeOnServer': false,
          },
        ],
      });
      final model = NsgGenNetcore.emitModel(gen, di);
      expect(model, contains('public Guid Id'));
      expect(model, contains('public string? Name'));
      expect(model, isNot(contains('IsCurrentUser')));

      final config = NsgGenNetcore.emitConfiguration(gen, di);
      expect(config, contains('builder.HasKey(x => x.Id);'));
      expect(config, contains('HasColumnName("name")'));
      expect(config, isNot(contains('IsCurrentUser')));
    });

    test('reference field emits FK Property + HasOne navigation pair', () {
      final gen = makeGenerator();
      final di = shopItem();
      final config = NsgGenNetcore.emitConfiguration(gen, di);
      expect(config, contains('builder.Property(x => x.PhotoId)'));
      expect(config, contains('.HasColumnName("photo_id")'));
      expect(config, contains('builder.HasOne(x => x.Photo)'));
      expect(config, contains('.WithMany()'));
      expect(config, contains('.HasForeignKey(x => x.PhotoId)'));
      expect(config, contains('.OnDelete(DeleteBehavior.Restrict)'));
    });
  });

  group('NsgGenNetcore — AppDbContext (раунд 3.А)', () {
    test('dbSetName: Item-suffix → drop+s', () {
      expect(NsgGenNetcore.dbSetName('ShopItem'), equals('Shops'));
      expect(NsgGenNetcore.dbSetName('DiscountCardItem'),
          equals('DiscountCards'));
      expect(NsgGenNetcore.dbSetName('UserItem'), equals('Users'));
      expect(NsgGenNetcore.dbSetName('FileItem'), equals('Files'));
    });

    test('dbSetName: no Item suffix → +s', () {
      expect(NsgGenNetcore.dbSetName('BannerPlayerListTable'),
          equals('BannerPlayerListTables'));
      expect(NsgGenNetcore.dbSetName('Tournament'), equals('Tournaments'));
    });

    test('Designer: byte-identical to §2.0.8 reference (1 type)', () {
      // Эталон §2.0.8 показывает Designer с одним ShopItem.
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'out_cs',
        'dartPath': 'out_dart',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'out_netcore',
        'controller': <dynamic>[],
      });
      // Заполняем dataItems напрямую — обходим I/O controllers/methods.
      final shop = NsgGenDataItem.fromJson({
        'typeName': 'ShopItem',
        'databaseType': 'Магазины',
        'pgTableName': 'shops',
        'fields': [
          {
            'name': 'Id',
            'databaseName': 'Идентификатор',
            'pgColumnName': 'id',
            'type': 'String',
            'isPrimary': 'true',
          },
        ],
      });
      gen.dataItems['ShopItem'] = shop;

      final actual = NsgGenNetcore.emitDbContextDesigner(gen);
      const expected = '// <auto-generated>\n'
          '//   This file is generated by nsg_generator. Manual edits will be overwritten.\n'
          '// </auto-generated>\n'
          '#nullable enable\n'
          'using Microsoft.EntityFrameworkCore;\n'
          'using NsgDiscountsServer.Configurations;\n'
          'using NsgDiscountsServer.Models;\n'
          '\n'
          'namespace NsgDiscountsServer;\n'
          '\n'
          'public partial class AppDbContext : DbContext\n'
          '{\n'
          '    public DbSet<ShopItem> Shops => Set<ShopItem>();\n'
          '\n'
          '    partial void OnModelCreatingGenerated(ModelBuilder modelBuilder)\n'
          '    {\n'
          '        modelBuilder.ApplyConfiguration(new ShopItemConfiguration());\n'
          '    }\n'
          '}\n';
      expect(actual, equals(expected));
    });

    test('AppDbContext.cs manual: byte-identical to §2.0.8 reference', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'out_cs',
        'dartPath': 'out_dart',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'out_netcore',
        'controller': <dynamic>[],
      });
      final actual = NsgGenNetcore.emitDbContextManual(gen);
      const expected = 'using Microsoft.EntityFrameworkCore;\n'
          '\n'
          'namespace NsgDiscountsServer;\n'
          '\n'
          'public partial class AppDbContext : DbContext\n'
          '{\n'
          '    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }\n'
          '\n'
          '    protected override void OnModelCreating(ModelBuilder modelBuilder)\n'
          '    {\n'
          '        OnModelCreatingGenerated(modelBuilder);\n'
          '        // место для ручных конфигураций / seed\n'
          '    }\n'
          '\n'
          '    partial void OnModelCreatingGenerated(ModelBuilder modelBuilder);\n'
          '}\n';
      expect(actual, equals(expected));
    });

    test('Designer: DbSet emitted in alphabetic typeName order', () {
      // Вход — insertion-order Z..A, ожидаем выход — A..Z.
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'X',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      Map<String, dynamic> mk(String name) => {
            'typeName': name,
            'databaseType': name,
            'pgTableName': name.toLowerCase(),
            'fields': [
              {
                'name': 'Id',
                'databaseName': 'id',
                'pgColumnName': 'id',
                'type': 'String',
                'isPrimary': 'true',
              }
            ],
          };
      gen.dataItems['ZItem'] = NsgGenDataItem.fromJson(mk('ZItem'));
      gen.dataItems['AItem'] = NsgGenDataItem.fromJson(mk('AItem'));
      gen.dataItems['MItem'] = NsgGenDataItem.fromJson(mk('MItem'));

      final out = NsgGenNetcore.emitDbContextDesigner(gen);
      final aIdx = out.indexOf('DbSet<AItem>');
      final mIdx = out.indexOf('DbSet<MItem>');
      final zIdx = out.indexOf('DbSet<ZItem>');
      expect(aIdx, isNonNegative);
      expect(aIdx < mIdx, isTrue);
      expect(mIdx < zIdx, isTrue);
      // То же для ApplyConfiguration.
      final aCfg = out.indexOf('AItemConfiguration');
      final mCfg = out.indexOf('MItemConfiguration');
      final zCfg = out.indexOf('ZItemConfiguration');
      expect(aCfg < mCfg, isTrue);
      expect(mCfg < zCfg, isTrue);
    });

    test('csproj: byte-identical with parameterized versions', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final actual = NsgGenNetcore.emitCsproj(gen);
      final expected = '<Project Sdk="Microsoft.NET.Sdk.Web">\n'
          '\n'
          '  <PropertyGroup>\n'
          '    <TargetFramework>${NsgGenNetcore.targetFramework}</TargetFramework>\n'
          '    <Nullable>enable</Nullable>\n'
          '    <RootNamespace>NsgDiscountsServer</RootNamespace>\n'
          '  </PropertyGroup>\n'
          '\n'
          '  <ItemGroup>\n'
          '    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="${NsgGenNetcore.efCoreVersion}" />\n'
          '    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="${NsgGenNetcore.efCoreVersion}">\n'
          '      <PrivateAssets>all</PrivateAssets>\n'
          '      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>\n'
          '    </PackageReference>\n'
          '    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="${NsgGenNetcore.npgsqlVersion}" />\n'
          '  </ItemGroup>\n'
          '\n'
          '</Project>\n';
      expect(actual, equals(expected));
    });

    test('Program.cs: byte-identical (no implicit usings — explicit using-list)', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final actual = NsgGenNetcore.emitProgramCs(gen);
      const expected = 'using Microsoft.AspNetCore.Builder;\n'
          'using Microsoft.EntityFrameworkCore;\n'
          'using Microsoft.Extensions.Configuration;\n'
          'using Microsoft.Extensions.DependencyInjection;\n'
          'using NsgDiscountsServer;\n'
          '\n'
          'var builder = WebApplication.CreateBuilder(args);\n'
          'builder.Services.AddDbContext<AppDbContext>(opt =>\n'
          '    opt.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));\n'
          'var app = builder.Build();\n'
          'app.Run();\n';
      expect(actual, equals(expected));
    });

    test('appsettings.json: dev-values with db name from cSharpNamespace (lowercased)', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final actual = NsgGenNetcore.emitAppsettings(gen);
      const expected = '{\n'
          '  "ConnectionStrings": {\n'
          '    "DefaultConnection": "Host=localhost;Port=5432;Database=nsgdiscountsserver;Username=postgres;Password=postgres"\n'
          '  },\n'
          '  "Logging": {\n'
          '    "LogLevel": {\n'
          '      "Default": "Information",\n'
          '      "Microsoft.AspNetCore": "Warning"\n'
          '    }\n'
          '  },\n'
          '  "AllowedHosts": "*"\n'
          '}\n';
      expect(actual, equals(expected));
    });

    test('launchSettings.json: single http profile on :5000', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final actual = NsgGenNetcore.emitLaunchSettings(gen);
      const expected = '{\n'
          '  "\$schema": "http://json.schemastore.org/launchsettings.json",\n'
          '  "profiles": {\n'
          '    "http": {\n'
          '      "commandName": "Project",\n'
          '      "dotnetRunMessages": true,\n'
          '      "launchBrowser": false,\n'
          '      "applicationUrl": "http://localhost:5000",\n'
          '      "environmentVariables": {\n'
          '        "ASPNETCORE_ENVIRONMENT": "Development"\n'
          '      }\n'
          '    }\n'
          '  }\n'
          '}\n';
      expect(actual, equals(expected));
    });

    test('emitHostingFiles: all 4 files are one-shot (not overwritten)', () async {
      final outDir =
          '${Directory.systemTemp.path}/nsg_hosting_oneshot_${DateTime.now().microsecondsSinceEpoch}';
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': outDir,
        'controller': <dynamic>[],
      });

      try {
        // 1) First emit — все 4 файла создаются.
        await NsgGenNetcore.emitHostingFiles(gen);
        final files = [
          '$outDir/NsgDiscountsServer.csproj',
          '$outDir/Program.cs',
          '$outDir/appsettings.json',
          '$outDir/Properties/launchSettings.json',
        ];
        for (final p in files) {
          expect(await File(p).exists(), isTrue, reason: 'expected file: $p');
        }

        // 2) Симулируем ручную правку каждого.
        const sentinel = '// MANUAL EDIT — MUST SURVIVE\n';
        for (final p in files) {
          await File(p).writeAsString(sentinel);
        }

        // 3) Re-emit без forceOverwrite — все 4 файла нетронуты.
        await NsgGenNetcore.emitHostingFiles(gen);
        for (final p in files) {
          expect(await File(p).readAsString(), equals(sentinel),
              reason: 'file should not be overwritten: $p');
        }
      } finally {
        await Directory(outDir).delete(recursive: true);
      }
    });

    test('cascade: table-row Owner FK gets OnDelete(Cascade); other FKs Restrict', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'FutbolistaServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      // BannerPlayerList с List<BannerPlayerListTable>.
      final owner = NsgGenDataItem.fromJson({
        'typeName': 'BannerPlayerList',
        'databaseType': 'ЭлементБаннера',
        'pgTableName': 'banner_player_lists',
        'fields': [
          { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
          { 'name': 'Players', 'databaseName': 'Players', 'pgColumnName': 'players', 'type': 'List<BannerPlayerListTable>' },
        ],
      });
      // BannerPlayerListTable — табчасть-row (databaseType ends with .Строка).
      final row = NsgGenDataItem.fromJson({
        'typeName': 'BannerPlayerListTable',
        'databaseType': 'ЭлементБаннера.Строка',
        'pgTableName': 'banner_player_list_rows',
        'fields': [
          { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
          { 'name': 'Owner', 'databaseName': 'Owner', 'pgColumnName': 'owner', 'type': 'Reference<BannerPlayerList>' },
          { 'name': 'Player', 'databaseName': 'Player', 'pgColumnName': 'player', 'type': 'Reference<PlayerItem>' },
        ],
      });
      gen.dataItems['BannerPlayerList'] = owner;
      gen.dataItems['BannerPlayerListTable'] = row;

      // 1) computeTableRowOwners видит owner и имя его обратной коллекции.
      final ownersMap = NsgGenNetcore.computeTableRowOwners(gen);
      expect(ownersMap['BannerPlayerListTable']?.typeName,
          equals('BannerPlayerList'));
      expect(ownersMap['BannerPlayerListTable']?.collectionFieldName,
          equals('Players'));

      // 2) В Configuration табчасти-row: Owner FK → Cascade + WithMany(o => o.Players),
      //    Player FK → Restrict + WithMany().
      final config = NsgGenNetcore.emitConfiguration(gen, row);
      final ownerHasOneIdx = config.indexOf('builder.HasOne(x => x.Owner)');
      expect(ownerHasOneIdx, isNonNegative, reason: 'Owner HasOne expected');
      final ownerSection = config.substring(ownerHasOneIdx);
      expect(ownerSection, contains('.WithMany(o => o.Players)'),
          reason: 'Owner FK must name back-collection or EF creates shadow FK');
      expect(ownerSection, contains('.OnDelete(DeleteBehavior.Cascade)'),
          reason: 'Owner FK should be Cascade');
      final playerHasOneIdx = config.indexOf('builder.HasOne(x => x.Player)');
      expect(playerHasOneIdx, isNonNegative, reason: 'Player HasOne expected');
      final playerSection = config.substring(playerHasOneIdx);
      expect(playerSection, contains('.WithMany()'),
          reason: 'Non-owner Reference: WithMany without arg');
      expect(playerSection, contains('.OnDelete(DeleteBehavior.Restrict)'),
          reason: 'Player FK should be Restrict (non-owner Reference)');
      // Block-комментарий про Cascade присутствует только в Owner-блоке.
      expect(config, contains('// FK табчасть → owner: Cascade'));
    });

    test('FieldMap per-entity: wire ↔ C# round-trip for scalar+FK', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'DiscountServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final shop = NsgGenDataItem.fromJson({
        'typeName': 'ShopItem',
        'databaseType': 'Магазины',
        'pgTableName': 'shops',
        'fields': [
          { 'name': 'Id',    'databaseName': 'Id',   'pgColumnName': 'id',   'type': 'String', 'isPrimary': 'true' },
          { 'name': 'Name',  'databaseName': 'Name', 'pgColumnName': 'name', 'type': 'String' },
          { 'name': 'Photo', 'databaseName': 'Фото', 'pgColumnName': 'photo', 'type': 'Reference<FileItem>' },
        ],
      });
      final out = NsgGenNetcore.emitFieldMap(gen, shop);
      // Wire-имена — snake_case (dartName). FK имеет name=PhotoId после
      // fromJson-мутации, dartName=photo_id (совпадает с SQL-колонкой).
      expect(out, contains('"id"] = "Id"'));
      expect(out, contains('"name"] = "Name"'));
      expect(out, contains('"photoId"] = "PhotoId"'));
      // И обратное направление.
      expect(out, contains('"Id"] = "id"'));
      expect(out, contains('"PhotoId"] = "photoId"'));
      // Namespace и имя класса.
      expect(out, contains('namespace DiscountServer.Configurations;'));
      expect(out, contains('public static class ShopItemFieldMap'));
    });

    test('FieldMap skips fields without databaseName and List<> nav-collections', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'X',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final di = NsgGenDataItem.fromJson({
        'typeName': 'BannerPlayerList',
        'databaseType': 'X',
        'pgTableName': 'banner_player_lists',
        'fields': [
          { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
          { 'name': 'Players', 'databaseName': 'Players', 'type': 'List<BannerPlayerListTable>' },
          { 'name': 'Internal', 'type': 'String' },  // no databaseName
        ],
      });
      final out = NsgGenNetcore.emitFieldMap(gen, di);
      expect(out, contains('"id"] = "Id"'));
      expect(out, isNot(contains('Players')),  reason: 'List<> nav-collection has no wire-key in NsgCompare');
      expect(out, isNot(contains('Internal')), reason: 'fields without databaseName are skipped');
    });

    test('TypeNameMap: wire typeName ↔ pgTableName for all entities, sorted by typeName', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'DiscountServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      Map<String, dynamic> mk(String name, String table) => {
            'typeName': name,
            'databaseType': name,
            'pgTableName': table,
            'fields': [
              { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
            ],
          };
      gen.dataItems['ZItem'] = NsgGenDataItem.fromJson(mk('ZItem', 'zs'));
      gen.dataItems['AItem'] = NsgGenDataItem.fromJson(mk('AItem', 'as_'));

      final out = NsgGenNetcore.emitTypeNameMap(gen);
      // Алфавитный порядок по typeName.
      expect(out.indexOf('"AItem"'), lessThan(out.indexOf('"ZItem"')));
      // WireToPgTable: typeName → pgTableName.
      expect(out, contains('"AItem"] = "as_"'));
      expect(out, contains('"ZItem"] = "zs"'));
      // PgTableToWire: обратно.
      expect(out, contains('"as_"] = "AItem"'));
      expect(out, contains('"zs"] = "ZItem"'));
      expect(out, contains('public static class TypeNameMap'));
    });

    test('cascade auto-detect: List<UntypedReference<X,...>> in owner is NOT treated as owner-attribute for X', () {
      // Synthetic кейс: тип `Bag` имеет `List<UntypedReference<XRow, YRow>>`.
      // XRow — isTableRow. Без defensive-фильтра auto-detect мог бы решить,
      // что Bag — owner для XRow (потому что parser выставит referenceType=XRow).
      // Это полиморфная коллекция, не owner-привязка. Owner НЕ должен найтись.
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'X',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      final xRow = NsgGenDataItem.fromJson({
        'typeName': 'XRow',
        'databaseType': 'X.Строка',
        'pgTableName': 'x_rows',
        'fields': [
          { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
        ],
      });
      final bag = NsgGenDataItem.fromJson({
        'typeName': 'Bag',
        'databaseType': 'Bag',
        'pgTableName': 'bags',
        'fields': [
          { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
          { 'name': 'Items', 'databaseName': 'Items', 'type': 'List<UntypedReference<XRow, YRow>>' },
        ],
      });
      gen.dataItems['XRow'] = xRow;
      gen.dataItems['Bag'] = bag;

      final map = NsgGenNetcore.computeTableRowOwners(gen);
      expect(map['XRow'], isNull,
          reason: 'List<UntypedReference<...>> must not be treated as owner-attribute');
    });

    test('cascade: regular entity (not isTableRow) — all FK Restrict', () {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'a',
        'dartPath': 'b',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath': 'n',
        'controller': <dynamic>[],
      });
      // ShopItem из discount_server — обычная сущность, не isTableRow.
      final shop = NsgGenDataItem.fromJson({
        'typeName': 'ShopItem',
        'databaseType': 'Магазины',
        'pgTableName': 'shops',
        'fields': [
          { 'name': 'Id', 'databaseName': 'Id', 'pgColumnName': 'id', 'type': 'String', 'isPrimary': 'true' },
          { 'name': 'Photo', 'databaseName': 'Фото', 'pgColumnName': 'photo', 'type': 'Reference<FileItem>' },
        ],
      });
      gen.dataItems['ShopItem'] = shop;
      // Нет isTableRow-сущностей → ownersMap пуст.
      expect(NsgGenNetcore.computeTableRowOwners(gen), isEmpty);
      final config = NsgGenNetcore.emitConfiguration(gen, shop);
      expect(config, contains('.OnDelete(DeleteBehavior.Restrict)'));
      expect(config, isNot(contains('Cascade')));
    });

    test('emitDbContext: AppDbContext.cs is one-shot (not overwritten)', () async {
      final gen = NsgGenerator.fromJson({
        'targetFramework': 'net10.0',
        'cSharpNamespace': 'NsgDiscountsServer',
        'cSharpPath': 'out_cs',
        'dartPath': 'out_dart',
        'serverEmitKind': 'netcore',
        'netcoreOutputPath':
            '${Directory.systemTemp.path}/nsg_oneshot_test_${DateTime.now().microsecondsSinceEpoch}',
        'controller': <dynamic>[],
      });
      final shop = NsgGenDataItem.fromJson({
        'typeName': 'ShopItem',
        'databaseType': 'Магазины',
        'pgTableName': 'shops',
        'fields': [
          {
            'name': 'Id',
            'databaseName': 'Id',
            'pgColumnName': 'id',
            'type': 'String',
            'isPrimary': 'true',
          },
        ],
      });
      gen.dataItems['ShopItem'] = shop;

      try {
        // 1) First emit — оба файла создаются.
        await NsgGenNetcore.emitDbContext(gen);
        final manualPath = '${gen.netcoreOutputPath}/AppDbContext.cs';
        final manualFile = File(manualPath);
        expect(await manualFile.exists(), isTrue);

        // 2) Симулируем ручные правки.
        const manualEdit = '// manual edit — must survive regeneration\n';
        await manualFile.writeAsString(manualEdit);

        // 3) Re-emit без forceOverwrite — manual не трогается.
        await NsgGenNetcore.emitDbContext(gen);
        expect(await manualFile.readAsString(), equals(manualEdit));

        // 4) Designer всегда перезаписывается.
        final designerPath =
            '${gen.netcoreOutputPath}/AppDbContext.Designer.cs';
        final designerContent = await File(designerPath).readAsString();
        expect(designerContent, contains('public partial class AppDbContext'));
        expect(designerContent, contains('DbSet<ShopItem>'));
      } finally {
        await Directory(gen.netcoreOutputPath).delete(recursive: true);
      }
    });
  });
}
