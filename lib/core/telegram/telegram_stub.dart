import 'telegram_platform.dart';

/// Android/iOS: Telegram SDK yo'q.
TelegramPlatform createTelegramPlatform() => const NoTelegram();
