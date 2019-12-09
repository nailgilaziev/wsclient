/// index [EN,RU,...]
int _ = 1;
const _langs = {'en': 0, 'ru': 1};

//TODO(n): for debug reason created each time - use Texts.instance instead;
Texts get txt => Texts();

class Texts {
  /// Use before accessing / initializing to instance
  static void setLocale(String localeCode) {
    _ = _langs[localeCode];
    _instance = Texts();
  }

  static Texts _instance = Texts();
  static Texts get instance => _instance;



  var connSecsBeforeReconnect = [
    '',
    'Повторное соединение через',
  ][_];
}




