part of 'habits_bloc.dart';

enum HabitsStatus { initial, loading, ready, failure }

class HabitsState extends Equatable {
  HabitsState({
    this.status = HabitsStatus.initial,
    DateTime? selectedDate,
    this.habits = const [],
    this.failure,
    this.notice,
    this.noticeId = 0,
    this.newlyUnlocked = const [],
    this.unlockId = 0,
    this.pendingIds = const {},
    this.isSubmitting = false,
    this.createdHabit,
    this.updatedHabit,
  }) : selectedDate = selectedDate ?? ApiDate.dayOnly(DateTime.now());

  final HabitsStatus status;

  /// Hafta kalendarida tanlangan kun (vaqtsiz).
  final DateTime selectedDate;

  final List<DailyHabit> habits;

  /// Ro'yxatni yuklashdagi xatolik — ekran o'rtasida ko'rsatiladi.
  final Failure? failure;

  /// Bir martalik xabar (masalan optimistik yangilash orqaga qaytarilganda).
  final String? notice;
  final int noticeId;

  /// Bo'sh bo'lmasa — "Yangi yutuq!" oynasi ochiladi.
  final List<Achievement> newlyUnlocked;
  final int unlockId;

  /// Hozir serverga so'rov ketayotgan odatlar — ular ustida ikkinchi marta
  /// bosish bloklanadi, aks holda "+0,5" ikki marta yozilib qolardi.
  final Set<String> pendingIds;

  /// Odat yaratish formasi javob kutmoqda.
  final bool isSubmitting;

  /// Oxirgi muvaffaqiyatli yaratilgan odat — forma ekranini yopish uchun.
  final Habit? createdHabit;

  /// Oxirgi muvaffaqiyatli tahrirlangan odat — tahrirlash formasini yopish uchun.
  final Habit? updatedHabit;

  /// Formadagi maydonlar ostida ko'rsatiladigan server xatolari.
  Map<String, String> get fieldErrors => failure?.fieldErrors ?? const {};

  bool get isEmpty => habits.isEmpty;

  int get completedCount => habits.where((h) => h.isCompleted).length;

  /// 0.0–1.0. Bugun bajariladigan ish bo'lmasa — to'liq.
  double get dayProgress => habits.isEmpty ? 1 : completedCount / habits.length;

  bool isPending(String habitId) => pendingIds.contains(habitId);

  HabitsState copyWith({
    HabitsStatus? status,
    DateTime? selectedDate,
    List<DailyHabit>? habits,
    Failure? failure,
    String? notice,
    int? noticeId,
    List<Achievement>? newlyUnlocked,
    int? unlockId,
    Set<String>? pendingIds,
    bool? isSubmitting,
    Habit? createdHabit,
    Habit? updatedHabit,
    bool clearFailure = false,
    bool clearNotice = false,
    bool clearUnlocked = false,
  }) {
    return HabitsState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      habits: habits ?? this.habits,
      failure: clearFailure ? null : (failure ?? this.failure),
      notice: clearNotice ? null : (notice ?? this.notice),
      noticeId: noticeId ?? this.noticeId,
      newlyUnlocked: clearUnlocked
          ? const []
          : (newlyUnlocked ?? this.newlyUnlocked),
      unlockId: unlockId ?? this.unlockId,
      pendingIds: pendingIds ?? this.pendingIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdHabit: clearNotice ? null : (createdHabit ?? this.createdHabit),
      updatedHabit: clearNotice ? null : (updatedHabit ?? this.updatedHabit),
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedDate,
    habits,
    failure,
    notice,
    noticeId,
    newlyUnlocked,
    unlockId,
    pendingIds,
  ];
}
