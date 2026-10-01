import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/groups/domain/entities/group.dart';
import '../../features/groups/presentation/pages/group_edit_page.dart';
import '../../features/groups/presentation/pages/groups_list_page.dart';
import '../../features/groups/presentation/pages/group_templates_page.dart';
import '../../features/habits/domain/entities/habit.dart';
import '../../features/habits/domain/entities/habit_template.dart';
import '../../features/habits/presentation/pages/habit_edit_page.dart';
import '../../features/habits/presentation/bloc/organizer_bloc.dart';
import '../../features/habits/presentation/pages/habit_picker_page.dart';
import '../../features/habits/presentation/pages/organizer_page.dart';
import '../../features/shell/presentation/pages/main_shell.dart';
import 'app_routes.dart';

/// Navigatsiya. Kirish/chiqish qarorini ekranlar emas, router qabul qiladi.
///
/// Shu sabab logout tugmasi hech qayerga `Navigator.push` qilmaydi — u faqat
/// bloc'ga event yuboradi, router esa holat o'zgarganini ko'rib o'zi ko'chiradi.
class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    // Bloc har o'zgarganda `redirect` qayta hisoblanadi.
    refreshListenable: _AuthRefreshNotifier(_authBloc.stream),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.today,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.habitPicker,
        builder: (context, state) => const HabitPickerPage(),
      ),
      GoRoute(
        path: AppRoutes.habitEdit,
        builder: (context, state) {
          // `extra` orqali shablon (yangi odat) yoki mavjud odat (tahrirlash).
          final extra = state.extra;
          return HabitEditPage(
            template: extra is HabitTemplate ? extra : null,
            habit: extra is Habit ? extra : null,
            draft: extra is NewHabitDraft ? extra.habit : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.organizer,
        builder: (context, state) {
          // Свой блок на экран: черновик расстановки не должен трогать
          // главный список, пока пользователь не нажал галочку.
          return BlocProvider<OrganizerBloc>(
            create: (_) => sl<OrganizerBloc>(),
            child: OrganizerPage(
              focusGroupId: state.uri.queryParameters['group'],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.groups,
        builder: (context, state) => const GroupsListPage(),
      ),
      GoRoute(
        path: AppRoutes.groupTemplates,
        builder: (context, state) => const GroupTemplatesPage(),
      ),
      GoRoute(
        path: AppRoutes.groupEdit,
        builder: (context, state) {
          // `extra` orqali shablon yoki mavjud guruh uzatiladi.
          final extra = state.extra;
          return GroupEditPage(
            template: extra is GroupTemplate ? extra : null,
            group: extra is Group ? extra : null,
          );
        },
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = _authBloc.state.status;
    final location = state.matchedLocation;

    // Sessiya hali tekshirilmoqda — splash'da ushlab turamiz.
    if (status == AuthStatus.unknown) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isPublic = AppRoutes.publicRoutes.contains(location);

    if (status == AuthStatus.unauthenticated) {
      // Kirmagan foydalanuvchi himoyalangan ekranga kira olmaydi.
      return isPublic ? null : AppRoutes.welcome;
    }

    // Kirgan foydalanuvchini login/register/splash'da ushlab turishning
    // ma'nosi yo'q.
    if (isPublic || location == AppRoutes.splash) return AppRoutes.today;

    return null;
  }
}

/// Bloc stream'ini `Listenable` ga aylantiradi — `GoRouter` aynan shuni kutadi.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
