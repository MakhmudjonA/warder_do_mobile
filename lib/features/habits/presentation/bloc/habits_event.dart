part of 'habits_bloc.dart';

sealed class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

/// Ro'yxatni serverdan olish.
class HabitsRequested extends HabitsEvent {
  const HabitsRequested({this.silent = false});

  /// `true` — spinner ko'rsatilmaydi (pull-to-refresh yoki fonda yangilash).
  final bool silent;

  @override
  List<Object?> get props => [silent];
}

/// Hafta kalendaridan boshqa kun tanlandi.
class HabitsDateSelected extends HabitsEvent {
  const HabitsDateSelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// Checkbox bosildi: bajarilmagan bo'lsa belgilaydi, belgilangan bo'lsa oladi.
class HabitToggled extends HabitsEvent {
  const HabitToggled(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Miqdorli odatga qo'shish: "+0,5 litr".
class HabitValueAdded extends HabitsEvent {
  const HabitValueAdded({required this.habitId, required this.amount});

  final String habitId;

  /// **Qo'shiladigan** miqdor, jami emas.
  final double amount;

  @override
  List<Object?> get props => [habitId, amount];
}

/// Timer sessiyasi tugadi.
class HabitDurationAdded extends HabitsEvent {
  const HabitDurationAdded({required this.habitId, required this.seconds});

  final String habitId;
  final int seconds;

  @override
  List<Object?> get props => [habitId, seconds];
}

/// Kunlik yozuvni butunlay o'chirish.
class HabitLogCleared extends HabitsEvent {
  const HabitLogCleared(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Snackbar ko'rsatilgandan keyin xabarni tozalash.
class HabitsNoticeCleared extends HabitsEvent {
  const HabitsNoticeCleared();
}

/// Yutuq oynasi yopildi.
class HabitsUnlockDismissed extends HabitsEvent {
  const HabitsUnlockDismissed();
}

/// Tahrirlash formasi saqlandi.
class HabitUpdateSubmitted extends HabitsEvent {
  const HabitUpdateSubmitted({required this.original, required this.edited});

  final Habit original;
  final Habit edited;

  @override
  List<Object?> get props => [original, edited];
}

/// Formadan yangi odat yuborildi.
class HabitCreateSubmitted extends HabitsEvent {
  const HabitCreateSubmitted(this.draft);

  /// `id` bo'sh bo'lgan qoralama — server haqiqiy id beradi.
  final Habit draft;

  @override
  List<Object?> get props => [draft];
}
