import 'package:hugeicons/hugeicons.dart';

/// HugeIcons ikonka ma'lumoti turi.
///
/// Paket ikonkalarni `IconData` emas, SVG path'lar ro'yxati
/// (`List<List<dynamic>>`) ko'rinishida beradi. Shu typedef bilan uni ilova
/// bo'ylab toza nom ostida olib yuramiz — xom turni hech joyda yozmaymiz.
typedef AppIconData = List<List<dynamic>>;

/// Ilovadagi barcha **interfeys** ikonkalari — bitta joyda.
///
/// Bu yerdan foydalanishning ma'nosi: keyinchalik ikonkani almashtirish uchun
/// faqat shu jadval o'zgaradi, ekranlar tegilmaydi. Ikonka chizishni [WdIcon]
/// bajaradi.
///
/// Odat va guruh ikonkalari bu yerda **yo'q**: ular emoji (`HabitEmoji`).
class AppIcons {
  const AppIcons._();

  // --- Umumiy amallar ---
  static const AppIconData close = HugeIcons.strokeRoundedCancel01;
  static const AppIconData add = HugeIcons.strokeRoundedAdd01;
  static const AppIconData remove = HugeIcons.strokeRoundedMinusSign;
  static const AppIconData removeCircle = HugeIcons.strokeRoundedRemoveCircle;
  static const AppIconData check = HugeIcons.strokeRoundedTick02;
  static const AppIconData search = HugeIcons.strokeRoundedSearch01;
  static const AppIconData list = HugeIcons.strokeRoundedListView;
  static const AppIconData import = HugeIcons.strokeRoundedFileImport;
  static const AppIconData edit = HugeIcons.strokeRoundedEdit02;
  static const AppIconData delete = HugeIcons.strokeRoundedDelete02;
  static const AppIconData archive = HugeIcons.strokeRoundedArchive02;
  static const AppIconData logout = HugeIcons.strokeRoundedLogout01;

  // --- Navigatsiya / strelkalar ---
  static const AppIconData chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const AppIconData chevronLeft = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIconData arrowUp = HugeIcons.strokeRoundedArrowUp01;
  static const AppIconData unfoldMore = HugeIcons.strokeRoundedArrowUpDown;
  static const AppIconData dragHandle = HugeIcons.strokeRoundedDragDropVertical;

  // --- Holat / bildirishnoma ---
  static const AppIconData alert = HugeIcons.strokeRoundedAlert02;
  static const AppIconData checkCircle =
      HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIconData fire = HugeIcons.strokeRoundedFire;

  // --- Forma maydonlari ---
  static const AppIconData eye = HugeIcons.strokeRoundedView;
  static const AppIconData eyeOff = HugeIcons.strokeRoundedViewOffSlash;
  static const AppIconData email = HugeIcons.strokeRoundedMail01;
  static const AppIconData lock = HugeIcons.strokeRoundedLock;
  static const AppIconData lockConfirm =
      HugeIcons.strokeRoundedSquareLockCheck01;
  static const AppIconData user = HugeIcons.strokeRoundedUser;
  static const AppIconData globe = HugeIcons.strokeRoundedGlobal;
  static const AppIconData clock = HugeIcons.strokeRoundedClock01;
  static const AppIconData bell = HugeIcons.strokeRoundedNotification01;
  static const AppIconData folder = HugeIcons.strokeRoundedFolder01;
  static const AppIconData chat = HugeIcons.strokeRoundedBubbleChat;
  static const AppIconData telegram = HugeIcons.strokeRoundedTelegram;

  // --- Pastki panel (asosiy bo'limlar) ---
  static const AppIconData habits = HugeIcons.strokeRoundedTask01;
  static const AppIconData stats = HugeIcons.strokeRoundedChartColumn;
  static const AppIconData settings = HugeIcons.strokeRoundedSettings01;

  // --- Xush kelibsiz ekrani ---
  static const AppIconData book = HugeIcons.strokeRoundedBookOpen01;
  static const AppIconData water = HugeIcons.strokeRoundedDroplet;
  static const AppIconData meditation = HugeIcons.strokeRoundedYoga01;
}
