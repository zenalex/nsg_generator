# Эмит netcore: что порождается

Режим включается ключом `serverEmitKind: "netcore"`. Реализация — `bin/nsgGenNetcore.dart`
(около 3000 строк). Результат — **самостоятельный сервер ASP.NET Core**, не зависящий от
`NsgServerClasses` и windows-приложения метаданных: PostgreSQL через EF Core, обмен по прежнему
wire-формату `nsg_data`.

## Состав вывода

Каталог задаётся ключом `netcoreOutputPath`.

| каталог / файл | что внутри |
|---|---|
| `Models/<Type>.cs` | сущности EF Core по описанию типа |
| `Configurations/<Type>Configuration.cs` | отображение сущности на таблицу и колонки (`pgTableName`, `pgColumnName`) |
| `Configurations/<Type>FieldMap.cs` | соответствие «поле обмена ↔ свойство C#»; wire-имя это `databaseName`, а не имя колонки |
| `Configurations/NsgTypeNameMap.cs` | соответствие имён типов обмена типам C# |
| `Configurations/NsgTypeFieldMapRegistry.cs` | реестр `FieldMap` по runtime-типу — нужен сериализатору |
| `Configurations/NsgGeneratedServicesExtensions.cs` | регистрация служб в контейнере |
| `Controllers/<Type>Controller.cs` | порождаемый контроллер (перезаписывается) |
| `Controllers/<Type>Controller.Custom.cs` | заготовка для своей логики (**не перезаписывается**) |
| `Wire/…` | трансляция запросов и сериализация (см. [wire-and-schema.md](wire-and-schema.md)) |
| `Auth/…` | JWT: `NsgLoginDto`, `NsgJwtOptions`, `IJwtTokenService`, `JwtTokenService`, обработчик сырого токена |
| `AppDbContext.Designer.cs` · `AppDbContext.cs` | контекст: порождаемая часть и ручная |
| `<Namespace>.csproj`, `Program.cs`, `appsettings.json`, `launchSettings.json` | размещение приложения |
| `<Namespace>.Tests/` | заготовка тестового проекта: smoke и round-trip обмена |
| `Enums/…` | перечисления |

## Что перезаписывается, а что нет

Разделение проведено намеренно и опирается на `_writeOneShot`: файл пишется, **только если его ещё
нет** (либо при `forceOverwrite`).

**Перезаписывается при каждой генерации:** модели, конфигурации, `FieldMap`, реестры, порождаемая
часть контроллера, wire-слой, `AppDbContext.Designer.cs`.

**Пишется один раз и далее не трогается:** `*.Controller.Custom.cs`, ручная часть `AppDbContext.cs`,
`csproj`, `Program.cs`, `appsettings.json`, `launchSettings.json`, файлы тестового проекта, файлы
аутентификации.

Практическое следствие: **своя логика живёт в `.Custom.cs`**, и перегенерация её не затирает. Правка
порождаемого файла будет потеряна при следующем запуске.

## Порождаемые операции контроллера

Состав определяется флагами метода (`allowGetter`, `allowCreate`, `allowPost`, `allowDelete` —
см. [config-reference.md](config-reference.md)).

| операция | маршрут | поведение |
|---|---|---|
| чтение | `POST Api/<Type>` | тело — параметры запроса `nsg_data`: фильтр `NsgCompare`, сортировка, `ReadReferences`, `Top` |
| запись | `POST Api/<Type>/Post` | принимает **массив** объектов; для каждого — поиск по первичному ключу: найден → обновление, не найден → вставка |
| удаление | `POST Api/<Type>/Delete` | массив идентификаторов |

Точки расширения в `.Custom.cs`: `CustomizeReadQuery`, `OnBeforeSave`, `OnBeforeDelete`.

### Режим записи

По умолчанию `Post` выполняет upsert: найденный по идентификатору объект обновляется присланным
содержимым. Для типов, которые пишутся один раз и не изменяются, задаётся `postMode: "insert-only"`
(см. [config-reference.md](config-reference.md)): совпадающее содержимое принимается как повтор,
отличающееся отклоняется с `409`.

Сравнение выполняет порождаемый `Wire/NsgWireComparer.cs` — по объектам обмена, а не по сущностям.
Перед отказом вызывается частичный метод `OnPostConflict(incoming, existing)`, в котором проект может
записать расхождение в свой журнал; заготовка объявлена в `.Custom.cs`.

## Проверка результата

Тестовый проект порождается заготовкой и содержит два вида проверок: smoke (приложение поднимается,
маршруты отвечают) и round-trip обмена (объект сериализуется и разбирается обратно без потерь).

Тесты самого генератора — `test/netcore_emit_test.dart`; запуск: `dart test`.
