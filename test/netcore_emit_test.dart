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
}
