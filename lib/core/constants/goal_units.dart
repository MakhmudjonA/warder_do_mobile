/// Maqsad birligi: serverga **inglizcha kalit** ketadi, ekranda — qisqa
/// ruscha yozuv.
///
/// Kalit inglizcha bo'lishi shart: backend timer odatlarida sekundlarni
/// `minute`/`hour` bo'yicha o'giradi, AI va shablonlar ham shu kalitlarni
/// yozadi. Ilgari forma ruscha so'zni ("минут") saqlardi — bunday eski
/// qiymatlar ham buzilmaydi, shundayligicha ko'rsatiladi.
class GoalUnits {
  const GoalUnits._();

  static const Map<String, String> labels = {
    'time': 'раз',
    'minute': 'мин',
    'hour': 'ч',
    'liter': 'л',
    'glass': 'стак.',
    'cup': 'чаш.',
    'page': 'стр.',
    'km': 'км',
    'step': 'шагов',
    'kcal': 'ккал',
    'rep': 'повт.',
  };

  /// Formadagi tanlov tartibi.
  static const List<String> choices = [
    'time',
    'minute',
    'hour',
    'liter',
    'glass',
    'page',
    'km',
    'step',
    'kcal',
  ];

  static String label(String? unit) {
    if (unit == null || unit.isEmpty) return '';
    final key = unit.toLowerCase();
    // "minutes" kabi ko'plik shakllari ham tanilsin.
    return labels[key] ??
        labels[key.endsWith('s') ? key.substring(0, key.length - 1) : key] ??
        unit;
  }
}
