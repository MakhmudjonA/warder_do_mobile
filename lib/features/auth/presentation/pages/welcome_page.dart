import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/telegram/telegram_platform.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_button.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_notice_listener.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/telegram_login.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// Ilovaning birinchi ekrani. Asosiy yo'l — "Войти через Telegram":
/// Mini App'da avtomatik, telefonda bot orqali tasdiqlash (kod solishtirib).
/// Ikkalasida hisob bitta — kalit Telegram ID. Email — zaxira yo'l.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final inTelegram = sl<TelegramPlatform>().isAvailable;

    return AuthNoticeListener(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(AppStrings.welcomeTitle, style: AppTextStyles.display),
                const SizedBox(height: 14),
                Text(
                  AppStrings.welcomeSubtitle,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 36),

                // Ilova ichida nima kutayotganini ko'rsatuvchi namuna kartalar.
                const Expanded(child: _HabitPreviewStack()),

                BlocConsumer<AuthBloc, AuthState>(
                  // Kod olingan zahoti Telegram'ni ochamiz.
                  listenWhen: (p, c) =>
                      p.telegramLogin == null && c.telegramLogin != null,
                  listener: (context, state) =>
                      _openTelegram(context, state.telegramLogin!.botUrl),
                  builder: (context, state) {
                    final ticket = state.telegramLogin;
                    if (ticket != null) {
                      return _TelegramWaiting(
                        ticket: ticket,
                        onOpen: () => _openTelegram(context, ticket.botUrl),
                        onCancel: () => context.read<AuthBloc>().add(
                          const AuthTelegramAppLoginCancelled(),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Asosiy yo'l — Telegram: Mini App'da avtomatik,
                        // telefonda bot orqali tasdiqlash. Hisob ikkalasida
                        // bitta (kalit — Telegram ID).
                        _TelegramButton(
                          isLoading: state.isSubmitting,
                          onPressed: () => context.read<AuthBloc>().add(
                            inTelegram
                                ? const AuthTelegramRequested()
                                : const AuthTelegramAppLoginStarted(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          AppStrings.orEmail,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => context.push(AppRoutes.register),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                              color: AppColors.surfaceHigh,
                            ),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                          ),
                          child: const Text(AppStrings.getStarted),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: WdTextLink(
                            prefix: AppStrings.haveAccount,
                            label: AppStrings.signIn,
                            onPressed: () => context.push(AppRoutes.login),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openTelegram(BuildContext context, String url) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.telegramNotInstalled)),
      );
  }
}

const Color _telegramBlue = Color(0xFF2AABEE);

class _TelegramButton extends StatelessWidget {
  const _TelegramButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.textOnPrimary,
              ),
            )
          : const WdIcon(
              AppIcons.telegram,
              size: 22,
              color: AppColors.textOnPrimary,
            ),
      label: const Text(
        AppStrings.signInWithTelegram,
        style: AppTextStyles.button,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _telegramBlue,
        disabledBackgroundColor: _telegramBlue.withValues(alpha: 0.6),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
      ),
    );
  }
}

/// Bot'da tasdiqlashni kutish: kod, "Открыть Telegram", "Отмена".
class _TelegramWaiting extends StatelessWidget {
  const _TelegramWaiting({
    required this.ticket,
    required this.onOpen,
    required this.onCancel,
  });

  final TelegramLoginTicket ticket;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(AppStrings.telegramLoginTitle, style: AppTextStyles.title),
          const SizedBox(height: 6),
          const Text(
            AppStrings.telegramLoginBody,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 14),
          Text(
            ticket.displayCode.split('').join(' '),
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(
              letterSpacing: 6,
              color: _telegramBlue,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                AppStrings.telegramLoginWaiting,
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: _telegramBlue,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            child: const Text(
              AppStrings.openTelegram,
              style: AppTextStyles.button,
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dekorativ blok: haqiqiy odat kartalariga o'xshash namunalar.
class _HabitPreviewStack extends StatelessWidget {
  const _HabitPreviewStack();

  static const List<
    ({String title, String subtitle, String icon, int color, int streak})
  >
  _samples = [
    (
      title: 'Читать книгу',
      subtitle: 'Каждый день, 20 страниц',
      icon: 'reading',
      color: 4,
      streak: 12,
    ),
    (
      title: 'Пить воду',
      subtitle: 'Каждый день, 2 литра',
      icon: 'water_drop',
      color: 2,
      streak: 6,
    ),
    (
      title: 'Медитация',
      subtitle: 'Каждый день, 15 минут',
      icon: 'meditation',
      color: 7,
      streak: 22,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _samples.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sample = _samples[index];
        final color = AppColors.habitPalette[sample.color];

        return _PreviewCard(
          title: sample.title,
          subtitle: sample.subtitle,
          icon: sample.icon,
          color: color,
          streak: sample.streak,
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.streak,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          HabitIconTile(
            iconKey: icon,
            color:
                '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    WdIcon(AppIcons.fire, size: 14, color: color),
                    const SizedBox(width: 3),
                    Text(
                      '$streak',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: WdIcon(AppIcons.add, size: 20, color: color),
          ),
        ],
      ),
    );
  }
}
