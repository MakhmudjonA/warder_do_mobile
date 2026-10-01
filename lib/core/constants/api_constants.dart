/// Backend bilan bog'liq barcha manzillar shu yerda.
///
/// `--dart-define=API_BASE_URL=https://api.warderdo.uz` orqali build vaqtida
/// almashtirsa bo'ladi. Default qiymat lokal development uchun.
class ApiConstants {
  const ApiConstants._();

  /// Default — Heroku'dagi server, shuning uchun ilova hech qanday
  /// sozlamasiz ishga tushadi.
  ///
  /// Lokal backend bilan ishlash uchun build vaqtida almashtiriladi:
  ///   * USB (haqiqiy qurilma) — avval `adb reverse tcp:8000 tcp:8000`, keyin
  ///     `--dart-define=API_BASE_URL=http://localhost:8000/api/v1`
  ///   * Android emulyator     — `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
  ///   * Wi-Fi orqali          — `--dart-define=API_BASE_URL=http://192.168.0.200:8000/api/v1`
  ///   * Production            — `--dart-define=API_BASE_URL=https://api.warderdo.uz/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://warderdo-60a1aac98088.herokuapp.com/api/v1',
  );

  // --- Auth ---
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String token = '/auth/token';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String telegramAuth = '/auth/telegram';
  static const String telegramLoginRequest = '/auth/telegram/login-request';
  static const String telegramLoginPoll = '/auth/telegram/login-poll';

  /// Access token muddati tuganda backend aynan shu matnni qaytaradi.
  /// Boshqa 401 lardan farqlash uchun: bunda refresh qilamiz, chiqarmaymiz.
  static const String accessExpiredDetail = 'Access token has expired';

  // --- Habits ---
  static const String habits = '/habits';
  static String habit(String id) => '/habits/$id';
  static String habitArchive(String id) => '/habits/$id/archive';
  static String habitUnarchive(String id) => '/habits/$id/unarchive';
  static String habitLogs(String id) => '/habits/$id/logs';
  static String habitStreak(String id) => '/habits/$id/streak';
  static const String habitsReorder = '/habits/reorder';
  static const String habitsParse = '/habits/parse';

  // --- Groups ---
  static const String groups = '/groups';
  static String group(String id) => '/groups/$id';
  static const String groupsReorder = '/groups/reorder';

  // --- Programs (AI planlar) ---
  static const String programs = '/programs';
  static const String programsGenerate = '/programs/generate';
  static String program(String id) => '/programs/$id';
  static String programShift(String id) => '/programs/$id/shift';

  // --- Qolganlari ---
  static const String vacations = '/vacations';
  static String vacation(String id) => '/vacations/$id';
  static const String statsOverview = '/stats/overview';
  static const String statsCalendar = '/stats/calendar';
  static const String statsRecords = '/stats/records';
  static const String statsWeekly = '/stats/weekly';
  static const String achievements = '/achievements';
  static const String templates = '/templates';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// `/programs/generate` uchun. Backend AI'ni 60 s × 2 urinishgacha kutadi.
  /// Diqqat: Heroku router'i baribir 30 s da uzadi (H12) — to'liq kutish
  /// faqat Heroku'dan tashqaridagi serverda ishlaydi.
  static const Duration aiReceiveTimeout = Duration(seconds: 130);

  /// Token muddati tugashiga shuncha vaqt qolganda uni "eskirgan" deb hisoblaymiz.
  /// Eskirgan access token interceptor tomonidan `/auth/refresh` orqali
  /// yangilanadi; refresh token ham eskirgan bo'lsa — login ekrani.
  static const Duration expiryLeeway = Duration(seconds: 30);
}
