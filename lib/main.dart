import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/telegram/telegram_platform.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/groups/presentation/bloc/groups_bloc.dart';
import 'features/habits/presentation/bloc/habits_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await initDependencies();

  runApp(const WarderDoApp());
}

class WarderDoApp extends StatefulWidget {
  const WarderDoApp({super.key});

  @override
  State<WarderDoApp> createState() => _WarderDoAppState();
}

class _WarderDoAppState extends State<WarderDoApp> {
  // Bloc va router bir-biriga bog'langan, shuning uchun ikkalasi ham
  // `State` ichida bir marta yaratiladi (build'da emas).
  late final AuthBloc _authBloc = sl<AuthBloc>()..add(const AuthStarted());
  late final HabitsBloc _habitsBloc = sl<HabitsBloc>();
  late final GroupsBloc _groupsBloc = sl<GroupsBloc>();
  late final AppRouter _appRouter = AppRouter(_authBloc);
  final TelegramPlatform _telegram = sl<TelegramPlatform>();

  @override
  void initState() {
    super.initState();
    if (_telegram.isAvailable) {
      // Telegram panellari ilova foni bilan bir xil rangda bo'lsin.
      _telegram.prepare(background: AppColors.background);
      // Telegram'ning "orqaga" tugmasi — router stack'i bo'yicha.
      _telegram.onBackButtonPressed(() {
        if (_appRouter.router.canPop()) _appRouter.router.pop();
      });
      _appRouter.router.routerDelegate.addListener(_syncBackButton);
    }
  }

  void _syncBackButton() {
    _telegram.setBackButtonVisible(_appRouter.router.canPop());
  }

  @override
  void dispose() {
    if (_telegram.isAvailable) {
      _appRouter.router.routerDelegate.removeListener(_syncBackButton);
    }
    _authBloc.close();
    _habitsBloc.close();
    _groupsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<HabitsBloc>.value(value: _habitsBloc),
        BlocProvider<GroupsBloc>.value(value: _groupsBloc),
      ],
      // Foydalanuvchi kirgach odatlar ro'yxatini bir marta yuklaymiz.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == AuthStatus.authenticated,
        listener: (context, state) {
          _habitsBloc.add(const HabitsRequested());
          // Группы нужны главному экрану, чтобы разложить привычки по секциям.
          _groupsBloc.add(const GroupsRequested());
        },
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
