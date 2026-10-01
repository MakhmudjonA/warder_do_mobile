import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Odat/guruh ikonkasi kaliti → Phosphor (Fill) glif.
///
/// Kalitlar backendda oddiy string (`"water_drop"`) sifatida saqlanadi va
/// AI ham shu ro'yxatdan tanlaydi (backend: `app/services/quick_add.py`).
/// Emoji o'rniga glif: har platformada (iOS, Android, Telegram Desktop) bir
/// xil ko'rinadi va odat rangidagi kvadrat ichida iOS uslubida chiziladi.
class HabitIcons {
  const HabitIcons._();

  static const IconData fallback = PhosphorIconsFill.circle;

  static const Map<String, IconData> glyphs = {
    'sparkles': PhosphorIconsFill.sparkle,
    // --- Здоровье ---
    'health': PhosphorIconsFill.heart,
    'fitness': PhosphorIconsFill.sneakerMove,
    'exercise': PhosphorIconsFill.personSimpleRun,
    'workout': PhosphorIconsFill.barbell,
    'gym': PhosphorIconsFill.barbell,
    'water_drop': PhosphorIconsFill.drop,
    'vitamins': PhosphorIconsFill.pill,
    'stretching': PhosphorIconsFill.personArmsSpread,
    'run': PhosphorIconsFill.personSimpleRun,
    'walk': PhosphorIconsFill.personSimpleWalk,
    'bike': PhosphorIconsFill.personSimpleBike,
    'swim': PhosphorIconsFill.personSimpleSwim,
    'sleep': PhosphorIconsFill.moonStars,
    'nutrition': PhosphorIconsFill.forkKnife,
    'healthy_food': PhosphorIconsFill.carrot,
    'fruit': PhosphorIconsFill.orangeSlice,
    'no_smoking': PhosphorIconsFill.cigaretteSlash,
    'no_alcohol': PhosphorIconsFill.prohibit,
    'weight': PhosphorIconsFill.scales,
    'heart_pulse': PhosphorIconsFill.heartbeat,
    // --- Разум ---
    'mind': PhosphorIconsFill.brain,
    'meditation': PhosphorIconsFill.flowerLotus,
    'spiritual': PhosphorIconsFill.handsPraying,
    'mental_health': PhosphorIconsFill.smiley,
    'deep_work': PhosphorIconsFill.lightbulb,
    'book': PhosphorIconsFill.book,
    'reading': PhosphorIconsFill.bookOpenText,
    'study': PhosphorIconsFill.graduationCap,
    'school': PhosphorIconsFill.backpack,
    'journal': PhosphorIconsFill.notebook,
    'language': PhosphorIconsFill.translate,
    'music': PhosphorIconsFill.musicNotes,
    'instrument': PhosphorIconsFill.guitar,
    'art': PhosphorIconsFill.palette,
    'hobby': PhosphorIconsFill.puzzlePiece,
    'code': PhosphorIconsFill.code,
    // --- Рутина ---
    'morning': PhosphorIconsFill.sunHorizon,
    'day': PhosphorIconsFill.sun,
    'evening': PhosphorIconsFill.cloudMoon,
    'night': PhosphorIconsFill.moon,
    'routine': PhosphorIconsFill.arrowsClockwise,
    'daily_routine': PhosphorIconsFill.listChecks,
    'morning_routine': PhosphorIconsFill.sunHorizon,
    'evening_routine': PhosphorIconsFill.moonStars,
    'alarm': PhosphorIconsFill.alarm,
    'sun': PhosphorIconsFill.sun,
    'bed': PhosphorIconsFill.bed,
    'toothbrush': PhosphorIconsFill.tooth,
    'wash_face': PhosphorIconsFill.handSoap,
    'shower': PhosphorIconsFill.shower,
    'hygiene': PhosphorIconsFill.bathtub,
    'self_care': PhosphorIconsFill.handHeart,
    'clean': PhosphorIconsFill.broom,
    'chores': PhosphorIconsFill.washingMachine,
    'home': PhosphorIconsFill.house,
    // --- Жизнь ---
    'life': PhosphorIconsFill.tree,
    'personal': PhosphorIconsFill.userCircle,
    'work': PhosphorIconsFill.briefcase,
    'productivity': PhosphorIconsFill.lightning,
    'money': PhosphorIconsFill.piggyBank,
    'family': PhosphorIconsFill.usersThree,
    'relationship': PhosphorIconsFill.heartStraight,
    'pets': PhosphorIconsFill.pawPrint,
    'travel': PhosphorIconsFill.airplaneTilt,
    'community': PhosphorIconsFill.globe,
    'friends': PhosphorIconsFill.users,
    'phone_call': PhosphorIconsFill.phoneCall,
    'no_phone': PhosphorIconsFill.deviceMobileSlash,
    'phone_off': PhosphorIconsFill.phoneSlash,
    'shopping': PhosphorIconsFill.shoppingCart,
    'coffee': PhosphorIconsFill.coffee,
    'plant': PhosphorIconsFill.plant,
    'gratitude': PhosphorIconsFill.handHeart,
    'mail': PhosphorIconsFill.envelopeSimple,
    'calendar': PhosphorIconsFill.calendar,
    'pen': PhosphorIconsFill.pen,
    'smoke_free': PhosphorIconsFill.cigaretteSlash,
    'no_sweets': PhosphorIconsFill.cookie,
    'checklist': PhosphorIconsFill.listChecks,
    'plan_tomorrow': PhosphorIconsFill.notePencil,
    // --- Другое ---
    'weekend': PhosphorIconsFill.confetti,
    'daily': PhosphorIconsFill.calendarCheck,
    'weekly': PhosphorIconsFill.calendarDots,
    'monthly': PhosphorIconsFill.calendarBlank,
    'yearly': PhosphorIconsFill.calendarStar,
    'check': PhosphorIconsFill.checkCircle,
    'star': PhosphorIconsFill.star,
    'fire': PhosphorIconsFill.fire,
    'target': PhosphorIconsFill.target,
    'folder': PhosphorIconsFill.folderSimple,
  };

  static IconData resolve(String? key) => glyphs[key] ?? fallback;
}
