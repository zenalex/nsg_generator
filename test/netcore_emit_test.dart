import 'package:test/test.dart';

import '../bin/nsgGenDataItem.dart';
import '../bin/nsgGenDataItemField.dart';

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
}
