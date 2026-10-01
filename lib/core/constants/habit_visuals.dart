import 'package:flutter/material.dart';

/// Icon va rang **faqat client tomonda** ma'noga ega.
///
/// Backend ularni oddiy string sifatida saqlaydi va hech qanday tekshirmaydi.
/// Shuning uchun yangi icon qo'shish uchun serverni o'zgartirish shart emas —
/// shu fayldagi jadvalga bitta qator qo'shiladi, xolos.
///
/// [HabitEmoji.catalog] — ikonka **kalitlari** ro'yxati va ularning emoji
/// ko'rinishi (endi faqat zaxira sifatida). Ekranda odat ikonkasi
/// `HabitIconTile` bilan chiziladi: odat rangidagi kvadrat + Phosphor glifi
/// (`habit_icons.dart`). Emoji har platformada har xil ko'rinardi (Apple,
/// Noto, Telegram Desktop'da xira Segoe) — glif hamma joyda bir xil.
class HabitEmoji {
  const HabitEmoji._();

  /// Noma'lum kalit uchun default.
  ///
  /// Ilovaning eski versiyasi yangi kalitni tanimasligi mumkin — bunday
  /// holatda ekran buzilmasligi kerak.
  static const String fallback = '❓';

  /// Kalit — backendga yoziladigan string, qiymat — ko'rsatiladigan emoji.
  static const Map<String, String> catalog = {
    // Faqat ilova ichidagi belgi (AI tugmasi), odatlar uchun tanlanmaydi.
    'sparkles': '✨',
    // --- Sog'liq ---
    'health': '❤️',
    'fitness': '🤸',
    'exercise': '🏃',
    'workout': '🏋️',
    'gym': '🏋️',
    'water_drop': '💧',
    'vitamins': '💊',
    'stretching': '🧘',
    'run': '🏃',
    'walk': '🚶',
    'bike': '🚲',
    'swim': '🏊',
    'sleep': '😴',
    'nutrition': '🍴',
    'healthy_food': '🥗',
    'fruit': '🍎',
    'no_smoking': '🚭',
    'no_alcohol': '🚫',
    'weight': '⚖️',
    'heart_pulse': '💓',

    // --- Ong va o'sish ---
    'mind': '🧘',
    'meditation': '🧘',
    'spiritual': '🧘',
    'mental_health': '🧠',
    'deep_work': '🧠',
    'book': '📖',
    'reading': '📖',
    'study': '📘',
    'school': '🎓',
    'journal': '📝',
    'language': '🗣️',
    'music': '🎵',
    'instrument': '🎸',
    'art': '🎨',
    'hobby': '🧩',
    'code': '💻',

    // --- Kundalik tartib ---
    'morning': '🌅',
    'day': '☀️',
    'evening': '🌇',
    'night': '🌙',
    'routine': '⏰',
    'daily_routine': '🔁',
    'morning_routine': '🌅',
    'evening_routine': '🌙',
    'alarm': '⏰',
    'sun': '☀️',
    'bed': '🛏️',
    'toothbrush': '🪥',
    'wash_face': '🧼',
    'shower': '🚿',
    'hygiene': '🚿',
    'self_care': '👑',
    'clean': '🧹',
    'chores': '🧺',
    'home': '🏠',

    // --- Hayot sohalari ---
    'life': '🫙',
    'personal': '🫙',
    'work': '👷',
    'productivity': '🕐',
    'money': '💵',
    'family': '👨‍👩‍👧',
    'relationship': '❤️',
    'pets': '🐾',
    'travel': '✈️',
    'community': '👥',
    'friends': '🤝',
    'phone_call': '📞',
    'no_phone': '📵',
    'shopping': '🛒',

    // --- Davriylik ---
    'weekend': '🏁',
    'daily': '🔁',
    'weekly': '🔁',
    'monthly': '🔁',
    'yearly': '🔁',

    // --- Serverdagi shablonlar ishlatadigan kalitlar ---
    'pen': '🖊️',
    'smoke_free': '🚭',
    'phone_off': '📵',
    'no_sweets': '🍬',
    'checklist': '✅',
    'mail': '📧',
    'calendar': '📅',
    'coffee': '☕',
    'plant': '🪴',
    'gratitude': '🙏',

    // --- Umumiy ---
    'check': '✅',
    'star': '⭐',
    'fire': '🔥',
    'target': '🎯',
    'plan_tomorrow': '✅',
    'folder': '🫙',
  };

  static String resolve(String? key) => catalog[key] ?? fallback;

  /// Emoji picker uchun kategoriyalar bo'yicha guruhlangan kalitlar.
  static const Map<String, List<String>> categorized = {
    'Здоровье': [
      'health',
      'fitness',
      'exercise',
      'workout',
      'gym',
      'water_drop',
      'vitamins',
      'stretching',
      'run',
      'walk',
      'bike',
      'swim',
      'sleep',
      'nutrition',
      'healthy_food',
      'fruit',
      'no_smoking',
      'no_alcohol',
      'weight',
      'heart_pulse',
    ],
    'Разум': [
      'mind',
      'meditation',
      'spiritual',
      'mental_health',
      'deep_work',
      'book',
      'reading',
      'study',
      'school',
      'journal',
      'language',
      'music',
      'instrument',
      'art',
      'hobby',
      'code',
    ],
    'Рутина': [
      'morning',
      'day',
      'evening',
      'night',
      'routine',
      'daily_routine',
      'alarm',
      'sun',
      'bed',
      'toothbrush',
      'wash_face',
      'shower',
      'hygiene',
      'self_care',
      'clean',
      'chores',
      'home',
    ],
    'Жизнь': [
      'life',
      'personal',
      'work',
      'productivity',
      'money',
      'family',
      'relationship',
      'pets',
      'travel',
      'community',
      'friends',
      'phone_call',
      'no_phone',
      'shopping',
      'coffee',
      'plant',
      'gratitude',
      'mail',
      'calendar',
    ],
    'Другое': [
      'weekend',
      'daily',
      'weekly',
      'monthly',
      'yearly',
      'check',
      'star',
      'fire',
      'target',
      'folder',
    ],
  };
}

/// Habit va guruh ranglari. Backendga hex string ko'rinishida boradi.
class HabitColors {
  const HabitColors._();

  static const List<String> palette = [
    '#6C7BF5',
    '#4FA8E8',
    '#B84FF5',
    '#E8C94F',
    '#4FE8C9',
    '#4FE87A',
    '#F5A64F',
    '#F54F6C',
    '#F5F5F5',
    '#8E8E93',
  ];

  static const Color fallback = Color(0xFF6C7BF5);

  /// `"#4FC3F7"`, `"4FC3F7"`, `"#FF4FC3F7"` — hammasini tushunadi.
  ///
  /// Buzuq qiymatda ilova qulamasligi kerak: backend rangni tekshirmaydi,
  /// ya'ni u yerda istalgan matn bo'lishi mumkin.
  static Color parse(String? hex) {
    if (hex == null) return fallback;

    var value = hex.trim().replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
