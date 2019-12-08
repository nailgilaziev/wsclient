//TODO Code based on ru locale date format. Check how does it work on other locales
String formattedDateTime(DateTime dt, {bool adaptiveToNow: false}) {
  if (dt == null) return null;
  var t = dt.toString();
  var lastIndexOf = t.lastIndexOf(':');
  if (lastIndexOf < 0) return null;
  var formatted = t.substring(0, lastIndexOf);
  if (adaptiveToNow) {
    var now = DateTime.now();
    if (dt.day == now.day)
      formatted = formatted.substring(formatted.indexOf(' ') + 1);
  }
  return formatted;
}

String formattedTime(int t, {bool adaptiveToNow: false}) {
  if (t == null) return null;
  var dateTime = DateTime.fromMillisecondsSinceEpoch(t);
  return formattedDateTime(dateTime, adaptiveToNow: adaptiveToNow);
}

String hhMmFromTime(int t) {
  assert(t != null);
  var minute = 1000 * 60;
  var hour = minute * 60;
  if (t < hour) {
    var minutes = (t / minute).round();
    return "$minutes мин";
  }
  var hours = t ~/ hour;
  var minutes = ((t - hour * hours) / minute).round();
  return "$hours ч $minutes мин";
}

String beautyTime(int secs) {
  if (secs < 60) return secs.toString();
  final ss = secs % 60;
  final minuteSeconds = ss < 10 ? '0$ss' : '$ss';
  final minutes = secs ~/ 60;
  if (minutes < 60) return '$minutes:$minuteSeconds';
  final mm = minutes % 60;
  final hourMinutes = mm < 10 ? '0$mm' : '$mm';
  final hours = minutes ~/ 60;
  return '$hours:$hourMinutes:$minuteSeconds';
}

String minutesPassed(DateTime past) {
  final now = DateTime.now();
  if (past.millisecondsSinceEpoch > now.millisecondsSinceEpoch)
    return 'в будущем';
  if (past.millisecondsSinceEpoch > now.millisecondsSinceEpoch - 60000)
    return 'совсем недавно';
  if (past.millisecondsSinceEpoch > now.millisecondsSinceEpoch - 2 * 60000)
    return 'минуту назад';
  return formattedDateTime(past, adaptiveToNow: true);
}

//TODO use function extensions!
//create separate module!
