import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';

/// Serverdan olingan access va refresh tokenlar hamda ularning muddatlari.
///
/// Access token qisqa umrli (~1 soat), refresh token uzoq umrli (~30 kun).
/// Access token tuganda `/auth/refresh` orqali jimgina yangilanadi, shuning
/// uchun foydalanuvchi 30 kun login qilmasa ham chiqib ketmaydi.
class AuthToken extends Equatable {
  const AuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  final String accessToken;

  /// Amalda doim `bearer`.
  final String tokenType;

  final DateTime expiresAt;

  /// Yangi access token olish uchun ishlatiladi. **Bir martalik** — har
  /// `/auth/refresh` yangisini qaytaradi va eskisini o'ldiradi.
  final String refreshToken;

  final DateTime refreshExpiresAt;

  /// Tugashiga [ApiConstants.expiryLeeway] qolganda ham "eskirgan" deymiz —
  /// so'rov yo'lda ketayotganda tugab qolishining oldini oladi.
  bool get isExpired =>
      DateTime.now().toUtc().add(ApiConstants.expiryLeeway).isAfter(expiresAt);

  /// Refresh token ham tugagan bo'lsa — sessiyani tiklab bo'lmaydi.
  bool get isRefreshExpired => DateTime.now()
      .toUtc()
      .add(ApiConstants.expiryLeeway)
      .isAfter(refreshExpiresAt);

  String get authorizationHeader => 'Bearer $accessToken';

  @override
  List<Object?> get props => [
    accessToken,
    tokenType,
    expiresAt,
    refreshToken,
    refreshExpiresAt,
  ];
}
