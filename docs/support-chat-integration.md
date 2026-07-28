# Интеграция чата поддержки (Chatista Connect) в продукт NSG

Как встроить чат поддержки в продукт на платформе NSG: сервер (ASP.NET) +
клиент (Flutter). Схема — «вариант C, issued-token»: продуктовый сервер
обменивает свою сессию пользователя на одноразовый токен Chatista, клиент
подключается этим токеном.

Что **уже готово на платформе** и делать не надо: сервер Chatista, комнаты
поддержки, тикеты, команда операторов, бот. Задача продукта — один endpoint
(генерируется) + кнопка в UI.

Эталонная реализация: `titan_lk` (продукт «ТИТАН Личный кабинет»).

---

## 1. Архитектура: кто за что отвечает

| Слой | Где живёт | Что делает |
|---|---|---|
| Клиент Chatista | `NsgServerClasses/ChatistaConnectClient.cs` | HTTP к Chatista, конфиг, разбор ответа, таксономия ошибок, гигиена секрета |
| Метаданные + генерация | `nsg_generator` (`supportChat`) | DTO, регистрация endpoint-а, рабочее тело метода |
| Продуктовый сервер | `<product>_server` | только хук `ResolveSupportChatUser` + ключи в конфиге |
| Продуктовый клиент | `<product>_app` (Flutter) | SDK `nsg_messenger`, провайдер токена, кнопки в UI |

Ключевой принцип: **секрет живёт только на сервере**. Клиент никогда его не
видит — он получает лишь одноразовый токен (TTL 5 минут).

---

## 2. Шаг 0 — Chatista (делает админ, один раз)

1. Chatista → **Настройки → Платформа**.
2. Убедиться, что есть **тенант** организации, он **включён** и у него
   **задан секрет** (`cst_…`). Секрет показывается **один раз** при генерации;
   потерян — перевыпускать.
3. **Внутри тенанта зарегистрировать продукт** с `externalKey` продукта
   (например `titan_lk`).

> ⚠️ **Тенант и продукт — разные сущности, и их ключи могут совпадать.**
> На экране «Платформа» перечислены **тенанты**. Если продукт внутри тенанта
> не заведён, Chatista вернёт `ProductNotFoundException`, причём в теле будут
> оба ключа — легко принять это за «перепутали tenant с product». Смотрите на
> смысл: ошибка означает «в тенанте X нет продукта Y», даже если X == Y.

---

## 3. Шаг 1 — сервер продукта

### 3.1. Флаг в `generation_config.json`

```json
"applicationName": "titan_lk",
"supportChat": {
    "enabled": true
}
```

Опционально:

| поле | по умолчанию | зачем |
|---|---|---|
| `productExternalKey` | `applicationName` | если ключ продукта в Chatista отличается от имени приложения |
| `typeName` | `ConnectToken` | имя генерируемого DTO (в titan_lk — `TitanConnectToken`) |

Флаг разворачивается в обычные метаданные (описание DTO, регистрация типа в
`method[]`, функция в `functions[]`) **до** разбора контроллеров, поэтому
дальше работает штатный конвейер генерации. Отдельный json-файл для DTO
не нужен.

Если продукт уже описал эти записи руками, генератор их не трогает —
ручное описание приоритетнее.

### 3.2. Генерация

```bash
dart run bin/nsgCodeGenerator.dart <путь к GeneratorConfig> -csharp -dart -dontAsk
```

Что появится:

- `Models/<TypeName>.cs` / `.Designer.cs` — DTO (token, externalUserId,
  displayName, expiresAt, tenantExternalKey, productExternalKey, apiBaseUrl);
- регистрация `POST /Api/IssueConnectToken`;
- **рабочее тело** `OnIssueConnectToken` с вызовом `ChatistaConnectClient`;
- объявление хука `partial void ResolveSupportChatUser(...)` в
  `DataControllerImplementation.Designer.cs`.

> `DataControllerImplementation.cs` (рукописная часть) генератором
> **не перезаписывается**, если уже существует. В новом продукте тело метода
> появится само; в существующем — скопируйте его из сгенерированного файла
> нового проекта или из `titan_lk`.

### 3.3. Хук (единственный обязательный код продукта)

В рукописной части `DataControllerImplementation.cs`:

```csharp
partial void ResolveSupportChatUser(INsgTokenExtension user,
                                    ref string externalUserId,
                                    ref string displayName)
{
    var userDB = (user as ServerTokenItem)?.пользователь;
    if (userDB == null) return;
    externalUserId = userDB.Идентификатор.ToString();
    displayName = $"{userDB.Фамилия} {userDB.Имя}".Trim();
    if (string.IsNullOrWhiteSpace(displayName))
        displayName = userDB.Телефон;
}
```

> 🚨 **`externalUserId` обязан быть ПОСТОЯННЫМ идентификатором пользователя.**
> Не передавайте `user.UserId` из `INsgTokenExtension` — это **guid токена**
> (`GetUserToken` ищет запись по нему), он меняется при каждом входе. Chatista
> склеивает историю обращений именно по `externalUserId`: с непостоянным
> значением при каждом логине заводится новый пользователь, история теряется,
> оператор видит незнакомца. Универсального «id пользователя» во фреймворке
> нет — поэтому хук обязателен, дефолта у него быть не может.

### 3.4. Конфиг сервера

| ключ | обязателен | значение |
|---|---|---|
| `ChatistaTenantKey` | да | `externalKey` тенанта в Chatista |
| `ChatistaServiceSecret` | да | секрет `cst_…` |
| `ChatistaUrl` | нет | по умолчанию `https://api.chatista.me` |

**Куда писать на проде:** в `<Приложение>.exe.config` рядом с exe —
`app.config` это исходник, при сборке он превращается в `exe.config`.

```xml
<appSettings>
  <add key="ChatistaTenantKey" value="ВАШ_TENANT" />
  <add key="ChatistaServiceSecret" value="cst_ВАШ_СЕКРЕТ" />
</appSettings>
```

Затем перезапустить сервер.

> ⚠️ **При следующем деплое `exe.config` перезапишется из `app.config`, и
> секрет пропадёт** — чат отвалится не сразу, а после обновления. Надёжнее
> вынести секрет во внешний файл, который деплой не трогает:
> `<appSettings file="chatista.config">` и рядом `chatista.config` с теми же
> ключами. Если файла нет — ничего не падает, ключи просто пустые.

Без ключей endpoint осознанно отвечает «Чат поддержки не настроен» и пишет об
этом в лог — диагностика однозначная.

---

## 4. Шаг 2 — клиент (Flutter)

### 4.1. Зависимость

```yaml
dependencies:
  nsg_messenger:
    path: ../nsg-connect-sdk/nsg_messenger

dependency_overrides:
  # record 5.x тянет record_linux 0.7.2, который не реализует
  # record_platform_interface 1.6.0 (нет startStream, у hasPermission
  # нет именованного request). Валит kernel_snapshot — в том числе
  # при сборке под Android. dart analyze при этом чистый.
  record_linux: ^1.3.1
```

### 4.2. Провайдер токена и инициализация

```dart
class _ProductAuthTokenProvider implements AuthTokenProvider {
  @override
  Future<MessengerAuthContext> getAuthContext() async {
    final t = await Get.find<DataController>().issueConnectToken();
    if (t == null || t.token.isEmpty) {
      throw StateError('IssueConnectToken вернул пустой токен');
    }
    return MessengerAuthContext(
      tenantExternalKey: t.tenantExternalKey,   // из ответа сервера, не хардкод
      productExternalKey: t.productExternalKey,
      identityProvider: IdentityProvider.customer,
      externalUserId: t.externalUserId,
      accessToken: t.token,
    );
  }
}

await NsgMessenger.init(
  apiBaseUrl: 'https://api.chatista.me',
  authTokenProvider: _ProductAuthTokenProvider(),
  mode: MessengerMode.embeddedProduct,
  productExternalKey: 'titan_lk',
  errorReporter: _GlitchErrorReporter(),   // ошибки SDK в свой трекер
);
```

`tenantExternalKey` и `apiBaseUrl` приходят с сервера в DTO — клиент их
не хардкодит, при смене тенанта пересобирать приложение не нужно.

Инициализацию удобно делать **лениво**, при первом обращении к поддержке:
пользователь к этому моменту уже авторизован.

### 4.3. Открытие чата

```dart
final room = await NsgMessenger.rooms.openSupportChat(
  productExternalKey: 'titan_lk',
  contextId: kind,            // 'general' | 'bug' | 'idea'
);
await NsgMessenger.openRoom(context, room.id);
```

Плюс «Мои обращения»: `NsgMessenger.openMyTickets(context)`.

> 🚨 **Две ловушки SDK:**
> 1. Не вызывайте статический `NsgMessenger.openSupportChat(context, contextId:)`
>    — это экран-заглушка (TASK39). Нужен `NsgMessenger.rooms.openSupportChat(...)`
>    (RPC), а затем `openRoom`.
> 2. `ChatScreen` **не экспортируется** из пакета — открывать комнату надо
>    публичным `NsgMessenger.openRoom(context, room.id)`, он сам её и рисует.

### 4.4. Обработка ошибок

Кнопка поддержки — единственная дверь пользователя к вам. Молча упавшая кнопка
означает, что он не сможет даже пожаловаться. Оборачивайте открытие в
`try/catch`: ошибку — в трекер, пользователю — понятный снек.

---

## 5. Контракт Chatista (для отладки)

`POST {apiBaseUrl}/connectToken/issueToken`

Запрос: `tenantExternalKey`, `productExternalKey`, `serviceSecret`,
`externalUserId`, `displayName`, опционально `claims` (`Map<String,String>`).

**Успех — HTTP 200, тело без конверта:**

```json
{"token":"3Qk7…","expiresAt":"2026-07-27T09:15:42.123Z"}
```

- `token` — base64url от 32 байт, одноразовый, TTL 5 минут;
- `expiresAt` — ISO-8601 **всегда в UTC**.

**Ошибка — HTTP 400, конверт с типом (это ДРУГОЙ формат):**

```json
{"className":"InvalidTokenException","data":{"reason":"issue_denied"}}
```

> 🚨 Парсер успеха на ошибке падает — форматы разные. Читайте `className`,
> а не `token`.

- `InvalidTokenException` / `issue_denied` — единый ответ на **любую** проблему
  авторизации (секрет, тенант, продукт, неактивный пользователь). Это осознанная
  защита от перебора: настоящая причина — только в логе Chatista.
  **Повторять бессмысленно.**
- `RateLimitExceededException` — 60 выдач/мин на тенант, 10 неверных секретов
  за 15 минут. Единственный случай, где ретрай осмыслен, с учётом
  `retryAfterSeconds` в `data`.

> ⚠️ `expiresAt` нельзя читать как строку через `.ToString()` у `JValue`:
> Newtonsoft распознаёт ISO-дату как `JTokenType.Date` и переформатирует её в
> локальный вид — время «уедет». Читайте значением (`Value<DateTime>()`).
> В `ChatistaConnectClient` это уже сделано правильно.

---

## 6. Диагностика

| Симптом | Причина | Что делать |
|---|---|---|
| «Чат поддержки не настроен» | нет `ChatistaTenantKey` / `ChatistaServiceSecret` | проверить `exe.config` рядом с exe и перезапуск |
| `ProductNotFoundException` | в тенанте нет продукта с таким `externalKey` | зарегистрировать продукт внутри тенанта (шаг 0.3) |
| `InvalidTokenException` / `issue_denied` | неверный секрет/тенант, продукт не привязан, пользователь неактивен | причина только в логе Chatista; проверить секрет и привязку |
| `RateLimitExceededException` | превышены лимиты тенанта | подождать `retryAfterSeconds`; проверить, не ретраит ли клиент |
| Комната создаётся, оператор её не видит | не тот тенант/продукт | сверить `tenantExternalKey` и `productExternalKey` |
| У пользователя каждый раз новая история | `externalUserId` непостоянный | в хуке отдавать постоянный id, **не** `user.UserId` |
| `kernel_snapshot failed`, `record_linux` | конфликт версий транзитивной зависимости | override `record_linux: ^1.3.1` |

---

## 7. Приёмка

1. Настройки → Поддержка → «Написать в поддержку» — комната создаётся.
2. Оператор видит обращение в Chatista, отвечает — ответ приходит в приложение.
3. **Повторное нажатие открывает ту же комнату**, а не новую.
4. Повторный вход в приложение — **та же** история обращений (проверка
   постоянства `externalUserId`).
5. «Мои обращения» показывает список.

---

## 8. Известные ограничения платформы

- **Регенерация клиента текущим генератором ломает сборку.** Генератор
  выпускает `schemaHash` в `NsgDataProvider` (коммит `d30d989`), а в `nsg_data`
  такого параметра ещё нет → `undefined_named_parameter`. Пока не поправлено —
  либо не перегенерировать Dart-часть, либо добавить поддержку в `nsg_data`.
- **Клиентский `issueConnectToken()` генерируется с `autoRepeate: true,
  autoRepeateCount: 3`.** При `RateLimitExceededException` это даёт лишние
  повторы. Если упрётесь в лимиты — регенерировать метод без авторетрая либо
  гасить на сервере.
- `NsgServerClasses` существует в двух копиях; канонический —
  `flutterServer/NsgServerClasses` (git, ветка `netFramework`).
  `net9/NsgServerClasses` — экспериментальная ветвь, не использовать.
