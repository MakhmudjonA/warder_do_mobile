# Habits + Groups modullari

Auth moduli bilan bir xil qatlamlar: `domain` → `data` → `presentation`,
BLoC + get_it + dio + dartz. Offline rejim yo'q — har bir amal serverga boradi.

## Nima uchun Riverpod/freezed emas

Spec'da "loyihada boshqasi ishlatilayotgan bo'lsa, o'shani ayt" deyilgan.
Loyihada allaqachon **BLoC** va qo'lda `fromJson` bor (auth moduli), shuning
uchun shu stack davom ettirildi:

| Spec taklifi | Bu loyihada | Sabab |
| --- | --- | --- |
| Riverpod | `flutter_bloc` | Auth moduli BLoC'da; ikkita state management bir ilovada — keraksiz murakkablik |
| freezed + json_serializable | Qo'lda `fromJson` | `build_runner` yo'q → build tez, generatsiya qilingan fayllar git'da yotmaydi |
| `AsyncValue` | `HabitsState.status` + `failure` | Bir xil ma'no, BLoC uslubida |
| `table_calendar` | `WeekStrip` (o'z widget'imiz) | Bizga faqat bitta hafta qatori kerak, butun kalendar paketi ortiqcha |

## Icon va rang

Backend `icon` va `color` ni oddiy string sifatida saqlaydi. Ma'nosini faqat
ilova biladi.

Ikonka iOS uslubida chiziladi: odat rangidagi yumaloq kvadrat, ichida
**Phosphor** (Fill) glifi — [HabitIconTile](../../core/widgets/habit_icon_tile.dart).
Kalit → glif jadvali: [habit_icons.dart](../../core/constants/habit_icons.dart).
Emoji o'rniga glif, chunki emoji har platformada boshqacha chizilardi.

```dart
HabitIconTile(iconKey: habit.icon, color: habit.color, size: 40)
HabitIconTile(iconKey: group.icon, onColor: true) // rangli fon ustida
```

Yangi ikonka qo'shish: `HabitIcons.glyphs` va `HabitEmoji.catalog` ga bitta
qatordan (test ikkalasi mosligini tekshiradi). AI ham tanlashi uchun backend
`app/services/quick_add.py: ICONS` ga ham qo'shing.

Maqsad birliklari serverga **inglizcha kalit** bilan ketadi (`liter`,
`minute`), ekranda esa ruscha qisqartma (`л`, `мин`) —
[goal_units.dart](../../core/constants/goal_units.dart).

## "Bugun" ekrani

- **"+"** — bitta tugma, pastdan menyu: AI bilan / shablonlar / o'zim /
  mashg'ulot dasturi.
- **Задачи** — vazifalar (`type: task`) alohida, eng tepada, vaqt bo'yicha;
  vaqti o'tgani qizil "просрочено".
- **Swipe**: o'ngga — bajarildi (4 soniya "Отменить"), chapga — tahrirlash.
- Telegram ichida formadagi "Сохранить" — Telegram'ning pastki MainButton'i.

## Optimistik yangilash

Bosh ekrandagi eng muhim qism — [habits_bloc.dart](presentation/bloc/habits_bloc.dart)
dagi `_optimistic()`:

1. UI **darhol** yangilanadi (vaqtinchalik `HabitLog` bilan)
2. Odat `pendingIds` ga qo'shiladi → takroriy bosish to'siladi
3. So'rov ketadi
4. Muvaffaqiyat → serverdagi haqiqiy log bilan almashtiriladi;
   `newly_unlocked` bo'sh bo'lmasa yutuq oynasi ochiladi
5. Xatolik → **rollback**: avvalgi ro'yxat qaytariladi + snackbar

Miqdor qo'shishda serverga **qo'shiladigan** miqdor ketadi, jami emas:
"+0,5 L" → `{"value": 0.5}`. Server o'zi qo'shadi va `completed` ni hisoblaydi.

## Sana bilan ishlash

Backend faqat `"YYYY-MM-DD"` qabul qiladi. `toIso8601String()` **yaramaydi** —
u vaqt va timezone qo'shadi. [core/utils/api_date.dart](../../core/utils/api_date.dart)
shu uchun bor: `ApiDate.format`, `ApiDate.parse`, `ApiDate.dayOnly`.

Hafta kunlari `1 = Dushanba … 7 = Yakshanba` — Dart'dagi `DateTime.weekday`
bilan aynan bir xil, konvertatsiya shart emas.

## Tahrirlash

Bitta forma ([habit_edit_page.dart](presentation/pages/habit_edit_page.dart))
ikki rejimda ishlaydi: `extra` sifatida `HabitTemplate` kelsa — yangi odat,
`Habit` kelsa — tahrirlash. Tahrirlashda serverga **faqat o'zgargan
maydonlar** ketadi (`HabitModel.toChangesJson`): backend `exclude_unset`
bilan ishlaydi, yuborilmagan kalit — "o'zgarmasin", `null` — "tozalansin"
(`description`, `group_id`, `goal_value`). Hech narsa o'zgarmasa so'rov
umuman yuborilmaydi.

Kirish nuqtalari: "Bugun" ekranida kartani uzoq bosish → "Изменить";
tartiblash ekranida odat menyusi → "Изменить" (saqlanmagan tartib bo'lsa
yashiriladi, chunki qayta yuklash uni o'chirib yuborardi).

## AI tezkor qo'shish va bir martalik vazifa

"Выберите привычку" ekranida **"Описать словами (AI)"**: bitta gap yoziladi
("завтра в 15:00 к врачу"), `POST /habits/parse` undan qoralama yasaydi va u
odatdagi formada ([habit_edit_page.dart](presentation/pages/habit_edit_page.dart),
`NewHabitDraft`) ochiladi — foydalanuvchi ko'rib, tuzatib saqlaydi. Hech narsa
foydalanuvchi bilmasdan saqlanmaydi.

Aniq kunga bog'langan vazifa — `OnceRepeat` (`{"type": "once", "date": ...}`),
jadval panelida "Один раз": bugun / ertaga / boshqa sana.

AI dastur (`program_import_sheet.dart`) ham matndagi boshlanish kunini oladi
("с понедельника"); preview'dagi "Начало" qatorida uni o'zgartirsa bo'ladi.

## Dastur odatlari

Mashg'ulot dasturiga biriktirilgan odatning `repeat_rule` i
`{"type": "program"}` — [ProgramRepeat](domain/entities/repeat_rule.dart).
Qaysi kun mashq ekanini faqat server biladi, shuning uchun ilova bu qoidani
ko'rsatadi ("По программе"), lekin hech qachon o'zgartirmaydi va PATCH'da
yubormaydi.

## Ekranlar

| Ekran | Fayl | So'rovlar |
| --- | --- | --- |
| Bugun | [today_page.dart](presentation/pages/today_page.dart) | `GET /habits?date=` — **bitta** so'rov, loglar ichida keladi |
| Progress qo'shish | `LogValueSheet` | `POST /habits/{id}/logs` |
| Yutuq oynasi | `AchievementDialog` | so'rovsiz — `newly_unlocked` javobdan keladi |
| Odat tanlash | [habit_picker_page.dart](presentation/pages/habit_picker_page.dart) | so'rovsiz — katalog client'da |
| Odat formasi | [habit_edit_page.dart](presentation/pages/habit_edit_page.dart) | `POST /habits`, `PATCH /habits/{id}` |
| Tartiblash | [organizer_page.dart](presentation/pages/organizer_page.dart) | `GET /habits?all=true`, `POST /habits/reorder`, `PATCH/DELETE /habits/{id}`, `POST /habits/{id}/archive` |
| AI dastur | [program_import_sheet.dart](../programs/presentation/pages/program_import_sheet.dart) | `POST /programs/generate`, `POST /programs` |
| Statistika | [stats_page.dart](../stats/presentation/pages/stats_page.dart) | `GET /stats/calendar`, `/stats/records`, `/stats/weekly` |
| Shablonlar | [group_templates_page.dart](../groups/presentation/pages/group_templates_page.dart) | so'rovsiz — katalog client'da |
| Guruh formasi | [group_edit_page.dart](../groups/presentation/pages/group_edit_page.dart) | `POST/PATCH/DELETE /groups` |

Guruh shablonlari backendda **yo'q** (`GET /templates` faqat odatlar uchun),
shuning uchun katalog [group_template_catalog.dart](../groups/data/group_template_catalog.dart)
da — client tomonda. Tanlanganda forma oldindan to'ldiriladi, xolos.

## Hali qilinmagan

Backendda bor, lekin ilovada ekrani yo'q: timer ekrani, yutuqlar ro'yxati,
ta'til ekrani (`/vacations`), arxivdan qaytarish, odat tarixi
(`GET /habits/{id}/logs`), dasturlar ro'yxati va dasturni to'xtatish
(`GET/PATCH /programs`), lokal bildirishnomalar
(`flutter_local_notifications`). Ularning ko'pchiligi uchun **data va domain
qatlami tayyor** — `HabitsRepository`, `ProgressRepository` va
`GroupsRepository` da tegishli metodlar bor, faqat use case + bloc + ekran
qo'shiladi.
