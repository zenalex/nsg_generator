# Создание клиент-серверной модели данных для обмена данными между клиентами, написанными на FLUTTER и сервером ASP.NET

[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE)

Данная утилита позволяет быстро создавть клиент-серверное кроссплатформенное приложение.  
Результатом генерации являются:
1.	проект сервера ASP.NET на языке C#
2.	модели данных для клиентского приложения Flutter на языке Dart

## Порядок действий для генерации модели обмена данных

1.	Непосредственно генерацию осуществляет данный проект (nsg_generator https://github.com/zenalex/nsg_generator.git)
2.	Создайте или подготовьте следующие проекты: Flutter - для генерации клиента, ASP.NET - для генерации сервера, Windows Forms - [метаданные](#объект-метаданных) (при необходимости)
3.	В проекте Flutter создаем папку сonfig (название любое) вне папки lib (для того, чтобы файлы в ней не были включены в конечный проект). В этой папке (будем называеть её config) будем создавать файлы-описатели классов и вызываемых функций в формате json (кодировка utf-8)

## Объект метаданных
Генерируемые классы на стороне сервера являются "оболочкой" для классов библиотеки, создаваемой при помощи NsgConfigurator.
Данную библиотеку классов (приложение Windows Forms) здесь мы называем метаданными
#  

## Создание конфигурационных файлов

Все данные файлы создаются в папке config и имеют формат json.
generation_config.json - Основной файл, содержащий описание всех генерируемых типов данных.

#

### 1. Описание структуры generation_config:

#### Пример готового файла:
<details>
  <summary>generation_config.json</summary>
  
```json
{
    "targetFramework": "net472",
    "cSharpPath": "C:/Users/SergeiFdrv/source/repos/MyApp/Server",
    "cSharpNamespace": "TechControlServer",
    "dartPath": "C:/Users/SergeiFdrv/source/repos/MyApp/Client/lib/model",
    "applicationName": "my_app",
    "controller": [
        {
            "apiPrefix": "Api",
            "className": "DataController",
            "useAuthorization": "true",
            "dataType": "NsgDataItem",
            "serverUri": "http://127.0.0.1:5000",
            "method": [
                {
                    "name": "BrandItem",
                    "description": "Марка",
                    "apiPrefix": "Brand",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "brand_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "ModelItem",
                    "description": "Модель",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "model_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "SizeItem",
                    "description": "Размеры",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "size_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "OrderItem",
                    "description": "Заказ",
                    "apiPrefix": "Order",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "order_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "OrderTableItem",
                    "description": "Заказ.Таблица",
                    "allowGetter": "false",
                    "dataTypeFile": "order_table_item.json"
                },
                {
                    "name": "ToolsItem",
                    "description": "Инструменты",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "tools_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                }
            ],
            "functions": [
                {
                    "name": "GetBrandOfModel",
                    "description": "Получение бренда, выпускающего данную модель",
                    "type": "Reference",
                    "referenceType": "BrandItem",
                    "authorize": "user",
                    "params": [
                        {
                            "name": "modelId",
                            "type": "String"
                        },
                        {
                            "name": "someDate",
                            "type": "DateTime"
                        },
                        {
                            "name": "someString",
                            "type": "String"
                        },
                        {
                            "name": "someInt",
                            "type": "int"
                        }
                    ]
                }
            ]
        }
    ],
    "enums": [
        {
            "className": "EDaysOfWeek",
            "description": "Дни недели",
            "dataTypeFile": "e_days_of_week.json"
        },
        {
            "className": "ERole",
            "description": "Роль",
            "dataTypeFile": "e_role.json"
        },
        {
            "className": "EPriority",
            "description": "Приоритет",
            "dataTypeFile": "e_priority.json"
        }
    ]
}
```
</details>

[Версия .NET](https://learn.microsoft.com/en-us/dotnet/standard/frameworks#supported-target-frameworks), под которую будет создана серверная часть. По умолчанию равна net5.0  
```json
"targetFramework": "net5.0",
```  

Путь к папке проекта .NET для генерации серверной части  
```json
"cSharpPath": "X:/Path/",
```

.NET namespace для генерации классов  
```json
"cSharpNamespace": "namespace",
```

Путь к папке проекта FLUTTER для генерации классов  
```json
"dartPath": "X:/Path",
```

Название приложения FLUTTER  
```json
"applicationName": "app",
```

Массив генерируемых контроллеров  
```json
"controller": []
```

Массив генерируемых перечислений  
```json
"enums": []
```

#

### 1. 1. Описание структуры контроллеров controller

Префикс для вызова web-api  
```json
"apiPrefix": "Api",
```

Имя класса контроллера. По умолчанию "DataController"   
```json
"className": "DataController",
```

Имя класса, содержащего реализации функций контроллера. По умолчанию className + "Implementation"  
```json
"implControllerName": "DataControllerImplementation",
```

Имя класса, реализующего функции аутентификации. По умолчанию "AuthControllerImplementation"  
```json
"implAuthControllerName": "AuthControllerImplementation",
```

Тип контроллера (пока единственный из доступных)  
```json
"dataType": "NsgDataItem",
```

Uri сервера  
```json
"serverUri": "http://server.name:5000",
```

Использует ли контроллер проверку пользователей  
```json
"useAuthorization": "true",
```

[не используется]
```json
"uploadEnabled": "true",
```

Требует ли контроллер авторизации пользователей. По умолчанию true  
```json
"loginRequired": "true",
```

Нужно ли создавать данный контроллер в клиентской части. По умолчанию true  
```json
"writeOnClient": "true",
```

Массив методов работы с объектами данных.
Для каждого элемента будет наздан набор методов  
```json
"method": []
```

#

### 1. 1. 1. Описание структуры методов работы с объектами данных (method)

Имя класса данных  
```json
"name": "UserDataItem",
```

Описание класса данных для чтения человеком  
```json
"description" : "User data item",
```

Префикс web-api для запроса операций чтения и записи с данным классом. По умолчанию равен name  
```json
"apiPrefix": "UserDataItem",
```

Уровень прав, требуемый для обращения к данным:  
- anonymous
- user

```json
"authorize": "user",
```

Тип HTTP-запроса на чтение (GET или POST)  
```json
"getterType": "get",
```

Имя файла описания структуры полей данного класса  
```json
"dataTypeFile": "userItem.json",
```

Генерировать метод для чтения. По умолчанию true  
```json
"allowGetter": "false"
```

Генерировать метод для записи  
```json
"allowPost": "true"
```

Перед записью проверять время предыдущей записи данного объекта.  
Если за время редактирования объект был записан параллельно, запись будет отменена, сервер вернет ошибку.  
Дата предыдущей записи должна храниться в самом объекте.  
```json
"checkLastModifiedDate": "true"
```

Генерировать метод для удаления  
```json
"allowDelete": "true"
```

Функции  
```json
"functions": []
```

### 1. 1. 1. 1. Настройки пользователей (UserSettings)

Сервер позволяет управлять настройками пользователей. Для этого необходимо добавить метод под названием UserSettings
и указать [файл объекта](#2-файл-описания-структуры-объекта) с привязкой к объекту [метаданных](#объект-метаданных).  
Требуемые поля:  
- ключевое поле (тип String или Guid)
- Settings (тип String)
- UserId (тип String или Guid)

Для UserSettings всегда создаются методы GET, POST и DELETE

#

### 1. 1. 2. Описание структуры функции (function)

Имя функции  
```json
"name": "UserData",
```

Типы метода HTTP. Поддерживаются GET и POST. Можно через запятую: ```"get, post"```. По умолчанию "post"
```json
"apiType": "get",
```

Вместо apiType можно указать поддержку методов по отдельности. По умолчанию httpGet = false, httpPost = true
```json
"httpGet": "true",
"httpPost": "true",
```

Тип выходных данных функции. Если [Image или Binary](#ссылочные-типы-данных),
функция будет создана только на сервере и параметры будут читаться из URI (например, ```function?id=123```)
```json
"type": "int",
```

Если тип - [генерируемый объект](#ссылочные-типы-данных), необходимо указать тип генерируемого объекта  
```json
"referenceType": "DayOfWeek",
```

Уровень прав, требуемый для обращения к функции:  
- anonymous
- user

```json
"authorize": "user",
```

Префикс для вызова web-api. По умолчанию равен name  
```json
"apiPrefix": "GetUserData",
```

Описание функции для чтения человеком  
```json
"description" : "Get user data",
```

Текст загрузочного окна во время запроса  
```json
"dialogText" : "Getting user data...",
```

Входные параметры функции  
```json
"params": []
```

#

### 1. 1. 2. 1. Описание структуры входных параметров функции (params)

Имя параметра  
```json
"name": "UserData",
```

Тип данных параметра  
```json
"type": "int",
```

Если тип - [генерируемый объект](#ссылочные-типы-данных), необходимо указать тип генерируемого объекта  
```json
"referenceType": "DayOfWeek",
```

#

### 1. 2. Описание структуры перечисления (enum)  

Имя класса перечисления  
```json
"className": "DaysOfWeek",
```

Описание перечисления для чтения человеком  
```json
"description": "Дни недели",
```

Имя файла описания структуры полей данного перечисления  
```json
"dataTypeFile": "days_of_week.json"
```

#

### 2. Файл описания структуры объекта

#### Пример готового файла:
<details>
  <summary>model_item.json</summary>
  
```json
{
    "typeName": "ModelItem",
    "databaseType": "Модель",
    "databaseTypeNamespace": "MyApp.Метаданные.Мониторинг",
    "fields": [
        {
            "name": "Id",
            "databaseName": "Идентификатор",
            "type": "String",
            "isPrimary": "true"
        },
        {
            "name": "Name",
            "databaseName": "Наименование",
            "type": "String"
        },
        {
            "name": "BrandId",
            "description": "Марка",
            "databaseName": "Владелец",
            "type": "Reference",
            "referenceName": "Brand",
            "referenceType": "BrandItem"
        },
        {
            "name": "Category",
            "databaseName": "Категория",
            "type": "Reference",
            "referenceType": "CategoryItem"
        },
        {
            "name": "IsFolder",
            "databaseName": "ЭтоГруппа",
            "type": "bool"
        },
        {
            "name": "ParentId",
            "databaseName": "ИдентификаторРодителя",
            "type": "Guid"
        }
    ]
}
```
</details>

Имя типа генерируемого объекта  
```json
"typeName": "TeamItem",
```

Предопределенная сущность генерируемого объекта. Возможный вариант
userSettings - класс для хранения настроек пользователя
Если не указана, будет сгенерирован обычный класс данных
```json
"entityType": "userSettings",
```

Описание поля для чтения человеком. По умолчанию равен databaseType  
```json
"description" : "Some item",
```

Имя типа объекта [метаданных](#объект-метаданных) (при наличии)  
```json
"databaseType": "Команды",
```

.NET namespace объекта [метаданных](#объект-метаданных) (при наличии)  
```json
"databaseTypeNamespace": "TechControl.Метаданные.Мониторинг",
```

Перегрузка методов ToString()  
```json
"presentation": "{Name} ({LicensePlate})",
```

Максимальное число объектов, возвращаемое сервером. По умолчанию 100  
```json
"maxHttpGetItems": 100,
```

Стандартное название поля для поиска по периоду  
```json
"periodFieldName": "period",
```

На стороне сервера использовать названия полей объектов [метаданных](#объект-метаданных) из статического класса Names  
```json
"useStaticDatabaseNames": "true",
```

Поля объекта  
```json
"fields": []
```

#

### 2. 1. Описание структуры полей объекта (fields)

Имя поля (в C# имя поля не может совпадать с названием класса)  
```json
"name": "Id",
```

Тип поля  
```json
"type": "String",
```

Имя поля в объекте [метаданных](#объект-метаданных) (при наличии)  
```json
"databaseName": "Идентификатор",
```

Тип поля в объекте [метаданных](#объект-метаданных) (при наличии)  
```json
"databaseType": "ДеньНедели",
```

Макс. длина строки или значение числа. По умолчанию 0 (без ограничения)  
```json
"maxLength": 50,
```

Описание поля для чтения человеком. По умолчанию равен databaseName  
```json
"description" : "Some value",
```

Если тип поля Image (изображение), для его получения нужен префикс api. По умолчанию равен name  
```json
"apiPrefix": "pic0"
```

Признак ключевого поля  
```json
"isPrimary": "true"
```

Если тип - [генерируемый объект](#ссылочные-типы-данных), можно указать имя ссылки для Flutter. Значение не должно совпадать с name и referenceName других полей данного объекта. Также в C# имя поля не может совпадать с названием класса. По умолчанию равен name без "Id" в конце  
```json
"referenceName": "Position",
```

Если тип поля - [генерируемый объект](#ссылочные-типы-данных), необходимо указать тип генерируемого объекта  
```json
"referenceType": "TeamItemMembersTable",
```

Если тип - [нетипизированная ссылка](#ссылочные-типы-данных), можно указать тип генерируемого объекта по умолчанию.
По умолчанию равен ```referenceType``` или первому из ```referenceTypes```  
```json
"defaultReferenceType": "TeamItem",
```

Если тип поля - [нетипизированная ссылка](#ссылочные-типы-данных), необходимо указать допустимые типы генерируемого объекта  
```json
"referenceTypes": [],
```

Можно указывать человекочитаемые имена полей  
```json
"userVisibility": "true",
"userName": "The Field!",
```

Генерировать поле на клиенте. По умолчанию true  
```json
"writeOnClient": "false",
```

Генерировать поле на сервере. По умолчанию true  
```json
"writeOnServer": "false",
```

Нужно ли при Post заполнять данное поле значением, полученным от клиента. По умолчанию true  
```json
"allowPost": "false",
```

#

### 3. Файл описания структуры перечисления  

#### Пример готового файла:
<details>
  <summary>e_days_of_week.json</summary>
  
```json
{
    "values": [
        {
            "codeName": "Monday",
            "name": "Понедельник",
            "value": "0"
        },
        {
            "codeName": "Tuesday",
            "name": "Вторник",
            "value": "1"
        },
        {
            "codeName": "Wednesday",
            "name": "Среда",
            "value": "2"
        },
        {
            "codeName": "Thursday",
            "name": "Четверг",
            "value": "3"
        },
        {
            "codeName": "Friday",
            "name": "Пятница",
            "value": "4"
        },
        {
            "codeName": "Saturday",
            "name": "Суббота",
            "value": "5"
        },
        {
            "codeName": "Sunday",
            "name": "Воскресенье",
            "value": "6"
        }
    ]
}
```
</details>

Список возможных значений  
```json
"values": []
```

#

### 3. 1. Описание структуры значения перечисления

Имя для кода  
```json
"codeName": "Unknown",
```

Имя для человека  
```json
"name": "Неизвестно",
```

Числовой индекс  
```json
"value": "0"
```

#

## Типы данных  
| тип | Описание |
| - | - |
| ```String``` | строка |
| ```int``` | целое число |
| ```bool``` | логическое |
| ```double``` | вещественное число (в [метаданных](#объект-метаданных) используется decimal) |
| ```DateTime``` | дата и время |
| ```Reference``` | ссылка на объект |
| ```UntypedReference``` | нетипизированная ссылка на объект |
| ```List<Reference>``` | список объектов (в [метаданных](#объект-метаданных) - табличная часть) |
| ```Enum``` | перечисление |
| ```Image``` | изображение |
| ```Binary``` | двоичные данные |

## Ссылочные типы данных
Поле referenceType нужно заполнять, если type:
- объект (```"type": "Reference"```)
- список объектов (```"type": "List<Reference>"```)
- перечисление (```"type": "Enum"```)

Для нетипизированных ссылок (```"type": "UntypedReference"```) заполняется массив referenceTypes:

Название для клиента  
```json
"alias": "playerItem",
```

Название типа в [метаданных](#объект-метаданных)  
```json
"databaseType": "Игроки"
```

Пространство имен  
```json
"namespace": "FootballersDiary.Метаданные.Справочники"
```

#  

## Запуск
Генерацию можно запустить прямо из консоли PowerShell:
```
dart bin\nsgCodeGenerator.dart C:\GeneratorConfig [-csharp] [-dart] [-force|-overwrite|-forceoverwrite] [csharp:] [dart:]
```
, где
- ```bin\nsgCodeGenerator.dart``` - путь к точке входа программы,
- ```C:\GeneratorConfig``` - путь к папке config

### Аргументы командной строки:
Путь к папке config всегда идет первым агрументом. Все остальные - в произвольном порядке.
- Генерировать только C# (если не указано также `-dart`)
```
-csharp
```
- Генерировать только Dart (если не указано также `-csharp`)
```
-dart
```
- Принудительная перезапись (без этого аргумента при повторной генерации некоторые файлы не перезаписываются)
```
-force
-overwrite
-forceoverwrite
```
- Если в папке найден файл .csproj, скопировать его
```
-copyCsproj
```
- Если в папке найден файл Program.cs, скопировать его
```
-copyProgramCs
```
- Если в папке найден файл Startup.cs, скопировать его
```
-copyStartupCs
```
- Не переспрашивать. По умолчанию при использовании forceOverwrite потребуется подтверждение перезаписи
```
-dontAsk
```
- Указать путь для генерации проекта C# (вместо указанного в [generation_config.json](#1-описание-структуры-generation_config))
```
csharp:C:\Server
```
- Указать путь для генерации файлов Dart (вместо указанного в [generation_config.json](#1-описание-структуры-generation_config))
```
dart:C:\Client\lib
```
