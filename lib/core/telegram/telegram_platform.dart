import 'dart:ui';

/// Telegram Mini App muhiti bilan aloqa.
///
/// Ilova ikki xil ishga tushadi: oddiy Android/iOS ilova sifatida va
/// Telegram ichida (Flutter web, Mini App). Qolgan kod qaysi biri ekanini
/// bilmaydi — faqat shu interfeysga qaraydi. Telegram tashqarisida
/// [NoTelegram] ishlaydi va hamma metodlar hech narsa qilmaydi.
abstract class TelegramPlatform {
  /// Ilova Telegram ichida ochilganmi (imzolangan `initData` bormi).
  bool get isAvailable;

  /// `Telegram.WebApp.initData` — o'zgartirmasdan serverga yuboriladi,
  /// server imzoni bot token bilan tekshiradi.
  String get initData;

  /// Telegram foydalanuvchi id'si (faqat UI qarorlari uchun — ishonchli
  /// manba emas, haqiqiyligini server tekshiradi).
  int? get userId;

  /// Mini App tayyorligini aytadi, to'liq balandlikka yoyadi va Telegram
  /// panellarini ilova rangiga bo'yaydi.
  void prepare({required Color background});

  /// Telegram'ning tepadagi "orqaga" tugmasi.
  void setBackButtonVisible(bool visible);
  void onBackButtonPressed(VoidCallback callback);

  /// Yengil tebranish (checkbox bosilganda).
  void hapticLight();

  /// `https://t.me/...` havolasini Telegram ichida ochadi (Mini App yopilmaydi).
  void openTelegramLink(String url);

  /// Telegram'ning pastdagi katta tugmasi (formalarda "Сохранить").
  /// Qayta chaqirilsa matn, holat va bosish amali yangilanadi.
  void showMainButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
  });

  void hideMainButton();
}

/// Telegram tashqarisida: Android, iOS va oddiy brauzer.
class NoTelegram implements TelegramPlatform {
  const NoTelegram();

  @override
  bool get isAvailable => false;

  @override
  String get initData => '';

  @override
  int? get userId => null;

  @override
  void prepare({required Color background}) {}

  @override
  void setBackButtonVisible(bool visible) {}

  @override
  void onBackButtonPressed(VoidCallback callback) {}

  @override
  void hapticLight() {}

  @override
  void openTelegramLink(String url) {}

  @override
  void showMainButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
  }) {}

  @override
  void hideMainButton() {}
}
