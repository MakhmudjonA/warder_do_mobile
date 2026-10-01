import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'telegram_platform.dart';

/// Web: `web/index.html` dagi `telegram-web-app.js` qo'shgan
/// `window.Telegram.WebApp` obyekti.
///
/// Skript oddiy brauzerda ham yuklanadi, lekin u yerda `initData` bo'sh —
/// shuning uchun "Telegram ichidami" degan savolga faqat `initData` javob
/// beradi.
TelegramPlatform createTelegramPlatform() {
  final telegram = globalContext.getProperty<JSObject?>('Telegram'.toJS);
  final webApp = telegram?.getProperty<JSObject?>('WebApp'.toJS);
  if (webApp == null) return const NoTelegram();

  final app = _WebApp(webApp);
  if (app.initData.isEmpty) return const NoTelegram();
  return _WebTelegram(app);
}

class _WebTelegram implements TelegramPlatform {
  _WebTelegram(this._app);

  final _WebApp _app;
  JSFunction? _backHandler;
  JSFunction? _mainHandler;

  @override
  bool get isAvailable => true;

  @override
  String get initData => _app.initData;

  @override
  int? get userId => _app.initDataUnsafe.user?.id;

  @override
  void prepare({required Color background}) {
    _app.ready();
    _app.expand();

    final hex = _hex(background);
    // Eski Telegram versiyalarida bu metodlar yo'q — chaqirilsa faqat
    // konsolga ogohlantirish chiqadi, shunga qaramay tekshirib chaqiramiz.
    if (_app.isVersionAtLeast('6.1')) {
      _app.setHeaderColor(hex);
      _app.setBackgroundColor(hex);
    }
    if (_app.isVersionAtLeast('7.10')) _app.setBottomBarColor(hex);
    // Ro'yxatni pastga surganda Mini App yopilib qolmasin.
    if (_app.isVersionAtLeast('7.7')) _app.disableVerticalSwipes();
  }

  @override
  void setBackButtonVisible(bool visible) {
    if (!_app.isVersionAtLeast('6.1')) return;
    visible ? _app.backButton.show() : _app.backButton.hide();
  }

  @override
  void onBackButtonPressed(VoidCallback callback) {
    if (!_app.isVersionAtLeast('6.1')) return;
    final previous = _backHandler;
    if (previous != null) _app.backButton.offClick(previous);
    final handler = callback.toJS;
    _backHandler = handler;
    _app.backButton.onClick(handler);
  }

  @override
  void hapticLight() {
    if (_app.isVersionAtLeast('6.1')) {
      _app.hapticFeedback.impactOccurred('light');
    }
  }

  @override
  void openTelegramLink(String url) {
    if (_app.isVersionAtLeast('6.1')) _app.openTelegramLink(url);
  }

  @override
  void showMainButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    final button = _app.mainButton;
    button.setParams(
      {
        'text': text,
        'color': '#6C63F0',
        'text_color': '#FFFFFF',
        'is_visible': true,
        'is_active': !loading,
      }.jsify()!,
    );
    loading ? button.showProgress(false) : button.hideProgress();

    final previous = _mainHandler;
    if (previous != null) button.offClick(previous);
    final handler = onPressed.toJS;
    _mainHandler = handler;
    button.onClick(handler);
  }

  @override
  void hideMainButton() {
    final button = _app.mainButton;
    final previous = _mainHandler;
    if (previous != null) button.offClick(previous);
    _mainHandler = null;
    button.hideProgress();
    button.hide();
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

// --- Telegram.WebApp JS API ---------------------------------------------------
// https://core.telegram.org/bots/webapps#initializing-mini-apps

extension type _WebApp(JSObject _) implements JSObject {
  external String get initData;
  external _InitDataUnsafe get initDataUnsafe;
  external bool isVersionAtLeast(String version);
  external void ready();
  external void expand();
  external void setHeaderColor(String color);
  external void setBackgroundColor(String color);
  external void setBottomBarColor(String color);
  external void disableVerticalSwipes();
  external void openTelegramLink(String url);

  @JS('BackButton')
  external _BackButton get backButton;

  @JS('HapticFeedback')
  external _HapticFeedback get hapticFeedback;

  @JS('MainButton')
  external _MainButton get mainButton;
}

extension type _MainButton(JSObject _) implements JSObject {
  external void setParams(JSAny params);
  external void show();
  external void hide();
  external void showProgress(bool leaveActive);
  external void hideProgress();
  external void onClick(JSFunction callback);
  external void offClick(JSFunction callback);
}

extension type _InitDataUnsafe(JSObject _) implements JSObject {
  external _TelegramUser? get user;
}

extension type _TelegramUser(JSObject _) implements JSObject {
  external int get id;
}

extension type _BackButton(JSObject _) implements JSObject {
  external void show();
  external void hide();
  external void onClick(JSFunction callback);
  external void offClick(JSFunction callback);
}

extension type _HapticFeedback(JSObject _) implements JSObject {
  external void impactOccurred(String style);
}
