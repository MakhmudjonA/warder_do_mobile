import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/login_with_telegram.dart';
import '../../features/auth/domain/usecases/logout_user.dart';
import '../../features/auth/domain/usecases/register_user.dart';
import '../../features/auth/domain/usecases/restore_session.dart';
import '../../features/auth/domain/usecases/update_profile.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/groups/data/datasources/groups_remote_data_source.dart';
import '../../features/groups/data/repositories/groups_repository_impl.dart';
import '../../features/groups/domain/repositories/groups_repository.dart';
import '../../features/groups/domain/usecases/group_usecases.dart';
import '../../features/groups/presentation/bloc/groups_bloc.dart';
import '../../features/habits/data/datasources/habits_remote_data_source.dart';
import '../../features/habits/data/datasources/progress_remote_data_source.dart';
import '../../features/habits/data/repositories/habits_repository_impl.dart';
import '../../features/habits/data/repositories/progress_repository_impl.dart';
import '../../features/habits/domain/repositories/habits_repository.dart';
import '../../features/habits/domain/repositories/progress_repository.dart';
import '../../features/habits/domain/usecases/habit_usecases.dart';
import '../../features/habits/presentation/bloc/habits_bloc.dart';
import '../../features/habits/presentation/bloc/organizer_bloc.dart';
import '../../features/habits/presentation/bloc/quick_add_cubit.dart';
import '../../features/programs/data/datasources/programs_remote_data_source.dart';
import '../../features/programs/data/repositories/programs_repository_impl.dart';
import '../../features/programs/domain/repositories/programs_repository.dart';
import '../../features/programs/domain/usecases/program_usecases.dart';
import '../../features/programs/presentation/bloc/program_import_bloc.dart';
import '../../features/stats/data/datasources/stats_remote_data_source.dart';
import '../../features/stats/data/repositories/stats_repository_impl.dart';
import '../../features/stats/domain/repositories/stats_repository.dart';
import '../../features/stats/domain/usecases/stats_usecases.dart';
import '../../features/stats/presentation/bloc/stats_bloc.dart';
import '../network/dio_client.dart';
import '../network/session_notifier.dart';
import '../storage/token_storage.dart';
import '../telegram/telegram.dart';
import '../../features/auth/domain/usecases/telegram_app_login.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Bog'liqliklarni ro'yxatdan o'tkazadi.
///
/// Tartib muhim: pastki qatlamlar (storage, dio) avval, ular ustidagi
/// data sourcelar, keyin repository, use case va oxirida bloc.
///
/// [storageOverride] — testda `InMemoryTokenStorage` berish uchun.
Future<void> initDependencies({TokenStorage? storageOverride}) async {
  // --- Core ---
  sl.registerLazySingleton<SessionNotifier>(SessionNotifier.new);

  // Telegram Mini App ichida — haqiqiy SDK, qolgan joyda `NoTelegram`.
  sl.registerLazySingleton<TelegramPlatform>(createTelegramPlatform);

  sl.registerLazySingleton<TokenStorage>(
    () => storageOverride ?? SecureTokenStorage(const FlutterSecureStorage()),
  );

  sl.registerLazySingleton<Dio>(
    () => DioClient.create(
      storage: sl<TokenStorage>(),
      sessionNotifier: sl<SessionNotifier>(),
    ),
  );

  // --- Data sources ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<TokenStorage>()),
  );

  // --- Repository ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  // --- Use cases ---
  sl.registerLazySingleton(() => RegisterUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateProfile(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RestoreSession(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginWithTelegram(sl<AuthRepository>()));
  sl.registerLazySingleton(() => StartTelegramLogin(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CheckTelegramLogin(sl<AuthRepository>()));

  // --- Bloc ---
  // Singleton, chunki auth holati butun ilova uchun bitta va router ham
  // shu instansiyaga qaraydi.
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      registerUser: sl(),
      loginUser: sl(),
      logoutUser: sl(),
      getCurrentUser: sl(),
      updateProfile: sl(),
      restoreSession: sl(),
      sessionNotifier: sl<SessionNotifier>(),
      loginWithTelegram: sl(),
      telegram: sl<TelegramPlatform>(),
      startTelegramLogin: sl(),
      checkTelegramLogin: sl(),
    ),
  );

  _registerHabits();
  _registerGroups();
  _registerPrograms();
  _registerStats();
}

void _registerStats() {
  sl.registerLazySingleton<StatsRemoteDataSource>(
    () => StatsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<StatsRepository>(
    () => StatsRepositoryImpl(sl<StatsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetStatsCalendar(sl<StatsRepository>()));
  sl.registerLazySingleton(() => GetStatsRecords(sl<StatsRepository>()));
  sl.registerLazySingleton(() => GetStatsWeekly(sl<StatsRepository>()));

  // Ekran IndexedStack ichida tirik qoladi — bitta instansiya yetarli.
  sl.registerFactory<StatsBloc>(
    () => StatsBloc(
      getCalendar: sl(),
      getRecords: sl(),
      getWeekly: sl(),
      getDailyHabits: sl(),
    ),
  );
}

void _registerPrograms() {
  sl.registerLazySingleton<ProgramsRemoteDataSource>(
    () => ProgramsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ProgramsRepository>(
    () => ProgramsRepositoryImpl(sl<ProgramsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GenerateProgram(sl<ProgramsRepository>()));
  sl.registerLazySingleton(() => SaveProgram(sl<ProgramsRepository>()));

  // Har ochilganda yangi holat kerak — shuning uchun factory.
  sl.registerFactory<ProgramImportBloc>(
    () => ProgramImportBloc(generateProgram: sl(), saveProgram: sl()),
  );
}

void _registerHabits() {
  sl.registerLazySingleton<HabitsRemoteDataSource>(
    () => HabitsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ProgressRemoteDataSource>(
    () => ProgressRemoteDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<HabitsRepository>(
    () => HabitsRepositoryImpl(sl<HabitsRemoteDataSource>()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(sl<ProgressRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetDailyHabits(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => LogHabit(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => UnlogHabit(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => CreateHabit(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => UpdateHabit(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => ParseHabitText(sl<HabitsRepository>()));
  // Har ochilganda toza holat.
  sl.registerFactory<QuickAddCubit>(() => QuickAddCubit(sl()));
  sl.registerLazySingleton(() => GetHabitTemplates(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => ReorderHabits(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => MoveHabitToGroup(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => DeleteHabit(sl<HabitsRepository>()));
  sl.registerLazySingleton(() => ArchiveHabit(sl<HabitsRepository>()));

  // Bosh ekran bloc'i — bitta instansiya, chunki tanlangan sana va ro'yxat
  // ekranlar orasida saqlanib qolishi kerak.
  sl.registerLazySingleton<HabitsBloc>(
    () => HabitsBloc(
      getDailyHabits: sl(),
      logHabit: sl(),
      unlogHabit: sl(),
      createHabit: sl(),
      updateHabit: sl(),
    ),
  );
}

void _registerGroups() {
  sl.registerLazySingleton<GroupsRemoteDataSource>(
    () => GroupsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<GroupsRepository>(
    () => GroupsRepositoryImpl(sl<GroupsRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetGroups(sl<GroupsRepository>()));
  sl.registerLazySingleton(() => SaveGroup(sl<GroupsRepository>()));
  sl.registerLazySingleton(() => DeleteGroup(sl<GroupsRepository>()));
  sl.registerLazySingleton(() => ReorderGroups(sl<GroupsRepository>()));

  // Экран «Изменить порядок» — свой блок: он держит черновик расстановки,
  // который не должен влиять на главный экран до сохранения.
  sl.registerFactory<OrganizerBloc>(
    () => OrganizerBloc(
      getDailyHabits: sl(),
      getGroups: sl(),
      reorderHabits: sl(),
      reorderGroups: sl(),
      moveHabitToGroup: sl(),
      deleteHabit: sl(),
      archiveHabit: sl(),
      deleteGroup: sl(),
    ),
  );

  sl.registerLazySingleton<GroupsBloc>(
    () => GroupsBloc(
      getGroups: sl(),
      saveGroup: sl(),
      deleteGroup: sl(),
      reorderGroups: sl(),
    ),
  );
}

/// Testlar orasida holatni tozalash uchun.
Future<void> resetDependencies() => sl.reset();
