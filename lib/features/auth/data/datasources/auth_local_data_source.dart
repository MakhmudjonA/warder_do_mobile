import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Token va foydalanuvchi cache'i.
///
/// Token — maxfiy ma'lumot, shuning uchun `SharedPreferences` emas,
/// Keychain / EncryptedSharedPreferences ustida turadi.
abstract class AuthLocalDataSource {
  Future<void> cacheToken(AuthTokenModel token);
  Future<AuthTokenModel?> getToken();

  /// Faqat refresh token satri — interceptorda yangilash uchun.
  Future<String?> getRefreshToken();

  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getUser();

  /// Chiqishda hammasini birdan o'chiradi.
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  final TokenStorage _storage;

  @override
  Future<void> cacheToken(AuthTokenModel token) async {
    await _storage.write(StorageKeys.accessToken, token.accessToken);
    await _storage.write(StorageKeys.tokenType, token.tokenType);
    await _storage.write(StorageKeys.tokenExpiresAt, token.expiresAtIso);
    await _storage.write(StorageKeys.refreshToken, token.refreshToken);
    await _storage.write(
      StorageKeys.refreshExpiresAt,
      token.refreshExpiresAtIso,
    );
  }

  @override
  Future<AuthTokenModel?> getToken() async {
    final accessToken = await _storage.read(StorageKeys.accessToken);
    final expiresAt = await _storage.read(StorageKeys.tokenExpiresAt);
    final refreshToken = await _storage.read(StorageKeys.refreshToken);
    final refreshExpiresAt = await _storage.read(StorageKeys.refreshExpiresAt);

    // Access token bo'lmasa sessiya yo'q deb hisoblaymiz.
    if (accessToken == null || accessToken.isEmpty || expiresAt == null) {
      return null;
    }

    try {
      return AuthTokenModel.fromStorage(
        accessToken: accessToken,
        tokenType: await _storage.read(StorageKeys.tokenType) ?? 'bearer',
        expiresAtIso: expiresAt,
        refreshToken: refreshToken ?? '',
        // Eski o'rnatishlarda refresh muddati bo'lmasligi mumkin — o'tmish
        // sanani beramiz, shunda "eskirgan" deb hisoblanadi.
        refreshExpiresAtIso:
            refreshExpiresAt ?? DateTime.utc(1970).toIso8601String(),
      );
    } on FormatException {
      // Buzilgan yozuv — tozalab, sessiya yo'q deymiz.
      await clearSession();
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() => _storage.read(StorageKeys.refreshToken);

  @override
  Future<void> cacheUser(UserModel user) =>
      _storage.write(StorageKeys.cachedUser, jsonEncode(user.toJson()));

  @override
  Future<UserModel?> getUser() async {
    final raw = await _storage.read(StorageKeys.cachedUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Exception {
      await _storage.delete(StorageKeys.cachedUser);
      throw const CacheException('Cache buzilgan');
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.tokenType);
    await _storage.delete(StorageKeys.tokenExpiresAt);
    await _storage.delete(StorageKeys.refreshToken);
    await _storage.delete(StorageKeys.refreshExpiresAt);
    await _storage.delete(StorageKeys.cachedUser);
  }
}
