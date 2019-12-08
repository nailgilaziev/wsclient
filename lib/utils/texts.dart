/// index [EN,RU,...]
int lang = 1;
const _langs = {'en': 0, 'ru': 1};

class Texts {
  Texts._();

  static void initInstance(String localeCode) {
    lang = _langs[localeCode];
    _instance = Texts._();
  }

  static Texts get instance => _instance;

  static Texts _instance = Texts._();

  final lineStatus = _LineStatusTexts();

  var connSecsBeforeReconnect = [
    '',
    'Повторное соединение через',
  ][lang];
}

Texts get txt =>
    Texts
        ._(); //TODO(n): for debug reason created eachtime - use this Texts.instance;

class _LineStatusTexts {
  final disconnected = ['Disconnected', 'Не подключено'][lang];

  final connecting = ['Connecting', 'Подключение'][lang];

  final fetching = ['Fetching', 'Обновление'][lang];

  final disconnecting = ['Disconnecting', 'Отключение'][lang];

  final problemsTitle = ['', 'Проблема с соединением'][lang];

  final maintenanceTitle = ['', 'Обслуживание системы'][lang];

  final secsBeforeReconnect = ['', 'Повторная попытка через'][lang];

  final searchingTitle = ['', 'Ожидание сети'][lang];

  final searchingSubtitle = ['', 'Обеспечьте доступ'][lang];

  final lastSyncPrefix = ['Synchronized', 'Cинхронизировано'][lang];

  final idle = ['Connected', 'Подключено'][lang];

  final searchingExplanation = [
    '-',
    '''WiFi или сотовое соединение в данный момент отсутствует. 
Обеспечьте хотя бы один канал выхода в интернет.
Если включен режим "в самолете", то сотовая сеть недоступна,
но можно использовать WiFi подключения при их наличии.
Если на устройстве есть механизы ограничения доступа к сети,
убедитесь что приложению выданы все разрешения. 
Убедитесь, что в системе отсутствуют возможные ограничения на доступ к интернету''',
  ][lang];
}
