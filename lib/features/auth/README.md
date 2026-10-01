# Auth moduli (WarderDo)

Backenddagi `/api/v1/auth/*` endpointlarining Flutter tomondagi to'liq
implementatsiyasi. Clean Architecture: `domain` → `data` → `presentation`.

## Qatlamlar va bog'liqlik yo'nalishi

```
presentation  →  domain  ←  data
   (BLoC)      (kontrakt)  (Dio, storage)
```

`domain` hech kimga bog'lanmaydi — unda Flutter ham, Dio ham yo'q.
`data` va `presentation` faqat `domain` ga qaraydi. Shuning uchun backendni
yoki UI ni almashtirish ikkinchisiga tegmasdan mumkin.

| Papka | Nima turadi | Nimaga bog'lanadi |
| --- | --- | --- |
| `domain/entities` | `User`, `AuthToken` — sof Dart obyektlari | hech nimaga |
| `domain/repositories` | `AuthRepository` — abstrakt kontrakt | entities |
| `domain/usecases` | Har biri bitta amal: login, register, logout… | repository |
| `data/models` | `UserModel`, `AuthTokenModel` — JSON ↔ entity | entities |
| `data/datasources` | `remote` (Dio), `local` (secure storage) | models |
| `data/repositories` | `AuthRepositoryImpl` — exception → `Failure` | ikkala datasource |
| `presentation/bloc` | `AuthBloc` — global auth holati | usecases |
| `presentation/pages` | Splash, Welcome, Login, Register, Profile | bloc |

## Xatoliklar qanday oqadi

```
Dio  →  DioException
     →  ErrorMapper       (core/network) → ServerException / NetworkException
     →  guardApi / mapServerException (core/error) → UnauthorizedFailure,
                                           ConflictFailure, ValidationFailure,
                                           NetworkFailure…
     →  AuthBloc                         → AuthState.failure
     →  AuthNoticeListener               → snackbar
        WdTextField(errorText:)          → maydon ostidagi qizil matn
```

Backend status kodlari (UI matnlari rus tilida, `AppStrings` da):

| Kod | `Failure` | UI da |
| --- | --- | --- |
| 401 `/auth/login`, `/auth/token` | `UnauthorizedFailure` | `errInvalidCredentials` — "email yoki parol noto'g'ri" |
| 401 boshqa joyda | `UnauthorizedFailure` | `errSessionExpired` — "sessiya tugadi" |
| 403 | `ForbiddenFailure` | `errAccountBlocked` — "hisob bloklangan" |
| 404 | `NotFoundFailure` | `errNotFound` |
| 409 `/auth/register` | `ConflictFailure` | `errEmailTaken` — "email band" |
| 409 `/programs` | `ConflictFailure` | `errProgramExists` — "faol dastur allaqachon bor" |
| 422 | `ValidationFailure` | maydon ostida aniq xato (`fieldErrors`) |
| 5xx | `ServerFailure` | `errServer` |

Bir xil status turli endpointda turli ma'noga ega — shuning uchun
`ErrorMapper` so'rov yo'liga ham qaraydi.

## Sessiya hayoti

1. **Ilova ochiladi** → `AuthStarted` → `RestoreSession`.
   Token yo'q yoki muddati tugagan bo'lsa — tarmoqqa umuman chiqilmaydi.
   Token bor bo'lsa `GET /auth/me` bilan tekshiriladi (foydalanuvchi
   bloklangan bo'lishi mumkin — server 403 qaytaradi).
   Access token eskirgan, lekin refresh token tirik bo'lsa ham `/me`
   chaqiriladi — interceptor avval jimgina refresh qiladi.
2. **Login / Register** → access + refresh token secure storage ga yoziladi
   → `/me` → `User`. Register `/login` ni o'zi chaqiradi, chunki backend
   `/register` token qaytarmaydi.
3. **Har bir so'rov** → `AuthInterceptor` `Authorization: Bearer <access>`
   qo'shadi.
4. **401 `"Access token has expired"` kelsa** → interceptor `/auth/refresh`
   ni chaqiradi (alohida "yalang'och" Dio orqali, bir vaqtda faqat bitta
   refresh — single-flight), yangi tokenlarni saqlaydi va asl so'rovni
   qayta yuboradi. Foydalanuvchi hech narsani sezmaydi.
5. **Boshqa 401/403 yoki refresh muvaffaqiyatsiz** → tokenlar o'chiriladi,
   `SessionNotifier` xabar beradi → `AuthBloc` `unauthenticated` ga o'tadi
   → router login ekraniga olib boradi.
6. **Logout** → `/auth/logout` ga refresh token yuboriladi (best-effort —
   internet bo'lmasa ham lokal chiqish to'xtamaydi), keyin lokal tokenlar
   o'chiriladi.

Muddatlar: access — `expires_in` (default 1 soat), refresh —
`refresh_expires_in` (default 30 kun). Refresh token bir martalik: server
har refreshda yangisini beradi, eskisini qayta ishlatish barcha
sessiyalarni bekor qiladi.

## Sozlash

Backend manzili build vaqtida beriladi:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1   # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1  # iOS simulator
flutter build apk --dart-define=API_BASE_URL=https://api.warderdo.uz/api/v1
```

Default qiymat — Heroku'dagi server. Emulyatorda `10.0.2.2` = host
mashinaning `localhost`i. Barcha manzillar:
`core/constants/api_constants.dart`.

## Yangi himoyalangan feature qo'shish

Token haqida o'ylash shart emas — `AuthInterceptor` uni o'zi qo'shadi,
refresh va 401 ni o'zi boshqaradi. Kerak bo'lgani:

```dart
// data/datasources/habit_remote_data_source.dart
class HabitRemoteDataSourceImpl implements HabitRemoteDataSource {
  const HabitRemoteDataSourceImpl(this._dio);   // sl<Dio>() — o'sha instansiya

  final Dio _dio;

  @override
  Future<List<HabitModel>> getHabits() async {
    try {
      final response = await _dio.get<List<dynamic>>('/habits');
      return response.data!
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);   // xatolar bir xil tarjima qilinadi
    }
  }
}
```

So'ng `injection_container.dart` ga ro'yxatdan o'tkazing.

## Timezone

`User.timezone` shunchaki ma'lumot emas: server "bugun" qaysi kun ekanini,
streak va statistikani shu qiymat bo'yicha hisoblaydi. Ro'yxatdan o'tishda
`DeviceTimezone.resolve()` qurilmaning IANA nomini yuboradi
(`DateTime.timeZoneName` **yaramaydi** — u IANA emas). Profildan
o'zgartirish mumkin.

## Testlar

```bash
flutter test
```

- `test/core/validators_test.dart` — parol 72-bayt qoidasi, email formati
- `test/core/error_mapper_test.dart` — 401/409/422 javoblarini endpointga qarab tarjima qilish
- `test/features/auth/auth_repository_impl_test.dart` — sessiya oqimi, offline
- `test/features/auth/auth_bloc_test.dart` — holat o'tishlari
- `test/core/wd_widgets_test.dart` — tugma va input

Barchasi soxta (fake) datasource/repository ustida ishlaydi, tarmoq talab
qilmaydi.

## Backendda hali yo'q va shuning uchun UI da ham yo'q

Parolni tiklash, email tasdiqlash, parol o'zgartirish, 2FA.
`/auth/logout-all` backendda bor, lekin UI da hali tugma yo'q.
Backend qo'shganda: yangi use case + bloc event + ekran — qolgan qatlamlar
o'zgarmaydi.
