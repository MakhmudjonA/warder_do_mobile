import 'package:equatable/equatable.dart';

/// Foydalanuvchi — domain qatlamining sof obyekti.
///
/// Bu yerda JSON ham, Dio ham, Flutter ham yo'q. Shuning uchun uni
/// backend o'zgarganda ham, UI o'zgarganda ham qayta yozish shart emas.
class User extends Equatable {
  const User({
    required this.id,
    required this.isActive,
    required this.timezone,
    required this.createdAt,
    this.email,
    this.telegramId,
    this.fullName,
    this.taskRemindBeforeMinutes,
  });

  /// UUID. JWT ichidagi `sub` claim shu qiymat.
  final String id;

  /// Har doim kichik harfda — backend registrni normallashtiradi.
  ///
  /// Telegram orqali yaratilgan hisobda `null` — u yerda email ham, parol
  /// ham yo'q, foydalanuvchini Telegram o'zi tasdiqlaydi.
  final String? email;

  /// Telegram foydalanuvchi id'si. Email bilan ro'yxatdan o'tganda `null`.
  final int? telegramId;

  bool get isTelegramAccount => telegramId != null;

  /// Vazifa eslatmasidan necha daqiqa oldin ogohlantirish. `null` — server
  /// standarti (10), `0` — o'chiq.
  final int? taskRemindBeforeMinutes;

  final String? fullName;

  /// `false` bo'lsa hisob bloklangan: server 403 qaytaradi.
  final bool isActive;

  /// IANA nomi, masalan `Asia/Tashkent`.
  ///
  /// Bu shunchaki ma'lumot emas: "bugun" qaysi kun ekanini, streak hisobini
  /// va statistikani aynan shu qiymat belgilaydi.
  final String timezone;

  final DateTime createdAt;

  /// UI'da ko'rsatish uchun ism: to'liq ism, bo'lmasa email'ning boshi.
  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final address = email;
    if (address != null && address.isNotEmpty) return address.split('@').first;
    return 'Telegram';
  }

  /// Avatar o'rniga chiqadigan bosh harflar.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final name = displayName;
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  User copyWith({
    String? id,
    String? email,
    int? telegramId,
    String? fullName,
    int? taskRemindBeforeMinutes,
    bool? isActive,
    String? timezone,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      telegramId: telegramId ?? this.telegramId,
      taskRemindBeforeMinutes:
          taskRemindBeforeMinutes ?? this.taskRemindBeforeMinutes,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    telegramId,
    fullName,
    taskRemindBeforeMinutes,
    isActive,
    timezone,
    createdAt,
  ];
}
