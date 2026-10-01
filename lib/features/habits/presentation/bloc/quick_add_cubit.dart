import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/habit.dart';
import '../../domain/usecases/habit_usecases.dart';

enum QuickAddStatus { idle, loading, success, failure }

/// AI tezkor qo'shish: matn → odat qoralamasi.
///
/// Hech narsa saqlanmaydi — qoralama odat formasida ochiladi va foydalanuvchi
/// uni ko'rib, tuzatib, o'zi saqlaydi. Shuning uchun alohida bloc emas,
/// oddiy Cubit yetarli.
class QuickAddCubit extends Cubit<QuickAddState> {
  QuickAddCubit(this._parseHabit) : super(const QuickAddState());

  final ParseHabitText _parseHabit;

  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.length < 2 || state.status == QuickAddStatus.loading) return;

    emit(const QuickAddState(status: QuickAddStatus.loading));
    final result = await _parseHabit(trimmed);
    emit(
      result.fold(
        (failure) =>
            QuickAddState(status: QuickAddStatus.failure, failure: failure),
        (draft) => QuickAddState(status: QuickAddStatus.success, draft: draft),
      ),
    );
  }
}

class QuickAddState extends Equatable {
  const QuickAddState({
    this.status = QuickAddStatus.idle,
    this.draft,
    this.failure,
  });

  final QuickAddStatus status;
  final Habit? draft;
  final Failure? failure;

  @override
  List<Object?> get props => [status, draft, failure];
}
