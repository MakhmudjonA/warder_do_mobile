# WarderDo (mobil)

Odatlarni kuzatish ilovasi — Flutter client. Backend: FastAPI
(`warder_do_back`), `/api/v1`.

## Imkoniyatlar

- **Kirish Telegram orqali** (asosiy): Mini App'da avtomatik, telefonda bot orqali kod bilan tasdiqlash — hisob hamma joyda bitta (kalit Telegram ID). Email + parol — zaxira yo'l
- Access + refresh token (jimgina yangilanadi)
- "Bugun" ekrani: checkbox va miqdorli odatlar, optimistik belgilash, yutuqlar
- Odat yaratish (shablondan yoki noldan) va tahrirlash
- Guruhlar, tartiblash, arxiv, o'chirish
- AI orqali mashg'ulot dasturi yaratish
- Statistika: kalendar, rekordlar, haftalik jadval

UI matnlari rus tilida (`lib/core/constants/app_strings.dart`), tema — faqat dark.

## Stack

`flutter_bloc` · `get_it` · `dio` · `dartz` · `go_router` ·
`flutter_secure_storage` · `hugeicons`. Kod generatsiyasi yo'q (`fromJson`
qo'lda).

## Tuzilma

```
lib/
  core/        DI, router, network (Dio, AuthInterceptor, ErrorMapper),
               xatolar (Failure), tema, umumiy widgetlar
  features/
    auth/      README.md — sessiya, xatolar oqimi, sozlash
    habits/    README.md — optimistik yangilash, tahrirlash, ekranlar
    groups/  programs/  stats/  shell/
```

Har bir feature — Clean Architecture: `domain` (entity, repository
kontrakti, use case) ← `data` (model, datasource, repository impl) ←
`presentation` (bloc, sahifalar).

## Ishga tushirish

```bash
flutter pub get
flutter run                                                          # Heroku server
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1   # emulyator + lokal backend
```

Boshqa variantlar: `lib/core/constants/api_constants.dart`.

## Tekshirish

```bash
flutter analyze
flutter test
```

## Telegram Mini App

Xuddi shu kod Telegram ichida ham ishlaydi (Flutter web, bot
[@warder_do_bot](https://t.me/warder_do_bot)). Telegram ichida email/parol
so'ralmaydi — `Telegram.WebApp.initData` bilan `POST /auth/telegram` orqali
avtomatik kiriladi. Platformaga bog'liq kod: `lib/core/telegram/`
(Android/iOS'da `NoTelegram` — hech narsa qilmaydi).

```powershell
powershell -File tool/build_telegram_webapp.ps1   # build/web → warder_do_back/webapp
```

Backend tomoni, sozlamalar va deploy: `warder_do_back/docs/TELEGRAM.md`.

## Release (Android)

Application ID — `uz.warderdo.app` (iOS/macOS bundle ID ham shu).
`android/key.properties` yarating (git'ga tushmaydi):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:/path/to/upload-keystore.jks
```

Fayl bo'lmasa release build debug kaliti bilan imzolanadi — bu faqat lokal
sinov uchun, Play Store'ga yaramaydi.

```bash
flutter build appbundle --dart-define=API_BASE_URL=https://api.warderdo.uz/api/v1
```
