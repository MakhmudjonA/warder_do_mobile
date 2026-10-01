import 'telegram_platform.dart';
import 'telegram_stub.dart'
    if (dart.library.js_interop) 'telegram_web.dart'
    as impl;

export 'telegram_platform.dart';

/// Platformaga mos [TelegramPlatform]: web'da haqiqiy SDK, qolgan joyda
/// [NoTelegram].
TelegramPlatform createTelegramPlatform() => impl.createTelegramPlatform();
