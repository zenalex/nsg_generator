# Создание клиент-серверной модели данных для обмена данными между клиентами, написанными на FLUTTER и сервером NET5

[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE)


## Порядок действий для генерации модели обмена данных

1.	Непосредственно генерацию осуществляет данный проект (nsg_generator https://github.com/zenalex/nsg_generator.git)
2.	Создайте или подготовьте следующие проекты: Flutter  - для генерации клиента, NET5 – для генерации сервера
3.	В проекте Flutter создаем папку сonfig (название любое) вне папки lib (для того, чтобы файлы в ней не были включены в конечный проект). В этой папке (будем называеть её config) будем создавать файлы-описатели классов и вызываемых функций в формате json

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
            "api_prefix": "Api",
            "class_name": "DataController",
            "useAuthorization": "true",
            "dataType": "NsgDataItem",
            "serverUri": "http://127.0.0.1:5000",
            "method": [
                {
                    "name": "BrandItem",
                    "description": "Марка",
                    "api_prefix": "BrandItem",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "brand_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "ModelItem",
                    "description": "Модель",
                    "api_prefix": "ModelItem",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "model_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "SizeItem",
                    "description": "Размеры",
                    "api_prefix": "SizeItem",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "size_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "OrderItem",
                    "description": "Заказ",
                    "api_prefix": "OrderItem",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "order_item.json",
                    "allowPost": "true",
                    "allowDelete": "true"
                },
                {
                    "name": "OrderTableItem",
                    "description": "Заказ.Таблица",
                    "api_prefix": "OrderTableItem",
                    "authorize": "user",
                    "getterType": "post",
                    "dataTypeFile": "order_table_item.json"
                },
                {
                    "name": "ToolsItem",
                    "description": "Инструменты",
                    "api_prefix": "ToolsItem",
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
                    "api_prefix": "GetBrandOfModel",
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
            "class_name": "EDaysOfWeek",
            "description": "Дни недели",
            "dataTypeFile": "e_days_of_week.json"
        },
        {
            "class_name": "ERole",
            "description": "Роль",
            "dataTypeFile": "e_role.json"
        },
        {
            "class_name": "EPriority",
            "description": "Приоритет",
            "dataTypeFile": "e_priority.json"
        }
    ]
}
```
</details>

Версия .NET, под которую будет создана серверная часть (поддерживаются net5 и net472, по умолчанию net5)  
```json
"targetFramework": "net5",
```  

Путь к папке проекта .NET для генерации классов 
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
"api_prefix": "Api",
```

Имя класса контроллера  
```json
"class_name": "DataController",
```

Имя класса, содержащего реализации функций контроллера  
```json
"impl_controller_name": "DataControllerImplementation",
```

Имя класса, реализующего функции аутентификации  
```json
"impl_auth_controller_name": "AuthControllerImplementation",
```

Использует ли контроллер проверку пользователей  
```json
"useAuthorization": "true",
```

Тип контроллера (пока единственный из доступных)  
```json
"dataType": "NsgDataItem",
```

Uri сервера  
```json
"serverUri": "http://server.name:5000",
```

Массив классов данных  
```json
"method": []
```

#

### 1. 1. 1. Описание структуры классов данных (method)

Имя класса данных  
```json
"name": "UserData",
```

Описание класса данных для чтения человеком  
```json
"description" : "Get user data",
```

Префикс web-api для запроса операций чтения и записи с данным классом  
```json
"api_prefix": "UserData",
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

Генерировать метод для чтения (по умолчанию true)  
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

#

>###### \*1.
>Поле referenceType нужно заполнять, если type
>- ссылочный (```"type": "Reference"```)
>- список объектов (```"type": "List<Reference>"```)
>- перечисление (```"type": "Enum"```)

#

### 1. 1. 2. Описание структуры функции (function)

Имя функции  
```json
"name": "UserData",
```

Тип выходных данных функции  
```json
"type": "int",
```

Если тип - генерируемый объект, необходимо указать тип генерируемого объекта ([*1](#1))  
```json
"referenceType": "DayOfWeek",
```

Уровень прав, требуемый для обращения к функции:  
- anonymous
- user

```json
"authorize": "user",
```

Префикс для вызова web-api  
```json
"api_prefix": "Api",
```

Описание функции для чтения человеком  
```json
"description" : "Get user data",
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

Если тип - генерируемый объект, необходимо указать тип генерируемого объекта ([*1](#1))  
```json
"referenceType": "DayOfWeek",
```

Массив генерируемых перечислений  
```json
"enums": []
```

#

### 1. 2. Описание структуры перечисления (enum)  

Имя класса перечисления  
```json
"class_name": "DaysOfWeek",
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
            "name": "MachineryBrandId",
            "description": "Марка",
            "databaseName": "Владелец",
            "type": "Reference",
            "referenceName": "MachineryBrand",
            "referenceType": "MachineryBrandItem"
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

Описание поля для чтения человеком  
```json
"description" : "Some item",
```

Имя типа объекта метаданных (при наличии)  
```json
"databaseType": "Команды",
```

.NET namespace объекта метаданных (при наличии)  
```json
"databaseTypeNamespace": "TechControl.Метаданные.Мониторинг",
```

Перегрузка методов ToString()  
```json
"presentation": "name",
```

Максимальное число объектов, возвращаемое сервером (не больше 100)  
```json
"maxHttpGetItems": 100,
```

Поля объекта  
```json
"fields": []
```

#

### 2. 1. Описание структуры полей объекта (fields)

Имя поля  
```json
"name": "Id",
```

Тип поля  
```json
"type": "String",
```

Имя поля в объекте метаданных (при наличии)  
```json
"databaseName": "Идентификатор",
```

Тип поля в объекте метаданных (при наличии)  
```json
"databaseType": "ДеньНедели",
```

Макс. длина строки или значение числа  
```json
"maxLength": 50,
```

Описание поля для чтения человеком  
```json
"description" : "Some value",
```

Если тип поля Image (изображение), для его получения нужен префикс api  
```json
"api_prefix": "pic0"
```

Признак ключевого поля  
```json
"isPrimary": "true"
```

Если тип - генерируемый объект, можно указать имя ссылки для Flutter ([*1](#1))  
```json
"referenceName": "Position",
```

Если тип поля - генерируемый объект, необходимо указать тип генерируемого объекта ([*1](#1))  
```json
"referenceType": "TeamItemMembersTable",
```

Можно указывать человекочитаемые имена полей  
```json
"userVisibility": "true",
"userName": "The Field!",
```

Если тип поля - генерируемый объект ([*1](#1)), можно указать, нужно ли получать с сервера значение вложенным в сам объект.  
(Крч, если false, то поставится ```[JsonIgnore]```; по умолчанию false)
```json
"alwaysReturnNested": "true",
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

## Запуск
Генерацию можно запустить прямо из консоли PowerShell:
```
dart bin\nsgCodeGenerator.dart C:\GeneratorConfig [-csharp] [-dart] [-force|-overwrite|-forceoverwrite] [csharp:] [dart:]
```
### Аргументы командной строки:
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
- Указать путь для генерации проекта C# (вместо указанного в [generation_config.json](#1-описание-структуры-generation_config))
```
csharp:C:\Server
```
- Указать путь для генерации файлов Dart (вместо указанного в [generation_config.json](#1-описание-структуры-generation_config))
```
dart:C:\Client\lib
```
