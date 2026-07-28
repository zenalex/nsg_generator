/// Поддержка чата Chatista Connect в продукте — «сахар» над метаданными.
///
/// Вместо трёх ручных записей в generation_config.json (файл описания DTO,
/// регистрация типа в `method` и функция в `functions`) продукт пишет:
///
/// ```json
/// "supportChat": {
///   "enabled": true,
///   "productExternalKey": "titan_lk",   // необязательно, по умолчанию applicationName
///   "typeName": "ConnectToken"          // необязательно, по умолчанию ConnectToken
/// }
/// ```
///
/// Серверная реализация endpoint-а обращается к
/// NsgServerClasses.ChatistaConnectClient — конфиг, HTTP, разбор ответа и
/// таксономия ошибок живут там, в продукте остаётся только маппинг
/// пользователя (постоянный externalUserId и displayName).
class NsgGenSupportChat {
  static const String defaultTypeName = 'ConnectToken';
  static const String functionName = 'IssueConnectToken';

  final bool enabled;
  final String productExternalKey;
  final String typeName;

  NsgGenSupportChat({
    required this.enabled,
    required this.productExternalKey,
    required this.typeName,
  });

  /// Разбирает секцию `supportChat`. Допускает как объект, так и `true`.
  factory NsgGenSupportChat.fromJson(dynamic raw, String applicationName) {
    if (raw == null) {
      return NsgGenSupportChat(
          enabled: false,
          productExternalKey: applicationName,
          typeName: defaultTypeName);
    }
    if (raw is bool) {
      return NsgGenSupportChat(
          enabled: raw,
          productExternalKey: applicationName,
          typeName: defaultTypeName);
    }
    if (raw is Map) {
      final map = raw;
      final enabled = map['enabled'] == null ? true : map['enabled'] == true;
      final product = (map['productExternalKey'] ?? '').toString();
      final type = (map['typeName'] ?? '').toString();
      return NsgGenSupportChat(
        enabled: enabled,
        productExternalKey: product.isEmpty ? applicationName : product,
        typeName: type.isEmpty ? defaultTypeName : type,
      );
    }
    throw Exception(
        'supportChat: ожидается объект или true, получено ${raw.runtimeType}');
  }

  /// Описание DTO — то, что раньше лежало отдельным json-файлом.
  Map<String, dynamic> get dataTypeJson => {
        'typeName': typeName,
        'fields': [
          {'name': 'Id', 'type': 'String', 'isPrimary': true},
          {
            'name': 'Token',
            'description': 'одноразовый connect-token (TTL 5 мин)',
            'type': 'String'
          },
          {
            'name': 'ExternalUserId',
            'description': 'постоянный id пользователя в продукте',
            'type': 'String'
          },
          {
            'name': 'DisplayName',
            'description': 'имя пользователя для отображения оператору',
            'type': 'String'
          },
          {
            'name': 'ExpiresAt',
            'description': 'момент истечения токена (UTC)',
            'type': 'DateTime'
          },
          {
            'name': 'TenantExternalKey',
            'description': 'tenant Chatista (чтобы клиент не хардкодил)',
            'type': 'String'
          },
          {
            'name': 'ProductExternalKey',
            'description': 'ключ продукта в тенанте',
            'type': 'String'
          },
          {
            'name': 'ApiBaseUrl',
            'description': 'базовый адрес Chatista для клиента',
            'type': 'String'
          },
        ]
      };

  /// Регистрация типа в списке `method`.
  Map<String, dynamic> get methodJson => {
        'name': typeName,
        'description': 'Токен подключения к чату поддержки (Chatista Connect)',
        'authorize': 'user',
        'getterType': 'post',
        'allowPost': true,
        'allowDelete': true,
        'dataType': dataTypeJson,
      };

  /// Функция выдачи токена.
  Map<String, dynamic> get functionJson => {
        'name': functionName,
        'description': 'Выдаёт одноразовый токен чата поддержки',
        'type': 'Reference<$typeName>',
        'authorize': 'user',
      };

  /// Тело серверного endpoint-а: вся работа с Chatista — в общем
  /// NsgServerClasses.ChatistaConnectClient, здесь только маппинг
  /// пользователя через продуктовый хук.
  static void generateImplBody(
      List<String> codeList, dynamic nsgGenerator, String typeName) {
    final chat = nsgGenerator.supportChat as NsgGenSupportChat;
    codeList.add('string externalUserId = null, displayName = null;');
    codeList.add(
        'ResolveSupportChatUser(user, ref externalUserId, ref displayName);');
    codeList.add('if (string.IsNullOrWhiteSpace(externalUserId))');
    codeList.add(
        'throw new Exception("Чат поддержки: не определён пользователь (реализуйте ResolveSupportChatUser)");');
    codeList.add('try');
    codeList.add('{');
    codeList.add(
        'var issued = await ChatistaConnectClient.IssueToken("${chat.productExternalKey}", externalUserId, displayName);');
    codeList.add('return new[]');
    codeList.add('{');
    codeList.add('new $typeName');
    codeList.add('{');
    codeList.add('Token = issued.Token,');
    codeList.add('ExternalUserId = externalUserId,');
    codeList.add('DisplayName = displayName,');
    codeList.add('ExpiresAt = issued.ExpiresAt,');
    codeList.add('TenantExternalKey = ChatistaConnectClient.TenantKey,');
    codeList.add('ProductExternalKey = "${chat.productExternalKey}",');
    codeList.add('ApiBaseUrl = ChatistaConnectClient.BaseAddress');
    codeList.add('}');
    codeList.add('};');
    codeList.add('}');
    codeList.add('catch (Exception ee)');
    codeList.add('{');
    codeList.add('// Настоящая причина (в т.ч. issue_denied) — только в лог:');
    codeList.add('// наружу Chatista отдаёт единый код, клиенту детали не нужны.');
    codeList.add(
        'NsgTracer.WriteErrorWithCallstack(\$"{DateTime.Now} $functionName. User {externalUserId}.", ee);');
    codeList.add('throw new Exception(ChatistaConnectClient.IsConfigured');
    codeList.add('? "Не удалось подключиться к чату поддержки"');
    codeList.add(': "Чат поддержки не настроен");');
    codeList.add('}');
  }

  /// Продуктовый хук. Универсального постоянного id в фреймворке нет:
  /// INsgTokenExtension.UserId — это guid ТОКЕНА, он меняется при каждом
  /// входе, и Chatista завела бы нового пользователя, потеряв историю.
  static void generateImplHook(List<String> codeList) {
    codeList.add('');
    codeList.add('/// <summary>');
    codeList.add(
        '/// Продуктовый хук чата поддержки: откуда брать ПОСТОЯННЫЙ идентификатор');
    codeList.add(
        '/// пользователя и его имя. Реализуйте в своей part-части класса, напр.:');
    codeList.add('/// <code>');
    codeList.add(
        '/// partial void ResolveSupportChatUser(INsgTokenExtension user, ref string externalUserId, ref string displayName)');
    codeList.add('/// {');
    codeList.add('///     var userDB = (user as ServerTokenItem)?.пользователь;');
    codeList.add('///     if (userDB == null) return;');
    codeList.add('///     externalUserId = userDB.Идентификатор.ToString();');
    codeList.add('///     displayName = \$"{userDB.Фамилия} {userDB.Имя}".Trim();');
    codeList.add('/// }');
    codeList.add('/// </code>');
    codeList.add(
        '/// НЕ передавайте user.UserId — это guid токена, он меняется при каждом входе.');
    codeList.add('/// </summary>');
    codeList.add(
        'partial void ResolveSupportChatUser(INsgTokenExtension user, ref string externalUserId, ref string displayName);');
  }

  /// Дописывает синтезированные метаданные в первый контроллер конфига.
  /// Если продукт уже описал их руками — не трогаем (ручное описание
  /// приоритетнее, чтобы флаг не ломал существующие проекты).
  void injectInto(Map<String, dynamic> parsedJson) {
    if (!enabled) return;
    final controllers = parsedJson['controller'];
    if (controllers is! List || controllers.isEmpty) {
      throw Exception('supportChat: в конфиге нет ни одного controller');
    }
    final controller = controllers.first as Map<String, dynamic>;

    final methods = (controller['method'] ??= <dynamic>[]) as List;
    final hasType = methods.any((m) => m is Map && m['name'] == typeName);
    if (!hasType) methods.add(methodJson);

    final functions = (controller['functions'] ??= <dynamic>[]) as List;
    final hasFunction =
        functions.any((f) => f is Map && f['name'] == functionName);
    if (!hasFunction) functions.add(functionJson);
  }
}
