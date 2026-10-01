import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/device_timezone.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/wd_button.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../../core/widgets/wd_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_notice_listener.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  /// Qurilma timezone'i. Ro'yxatdan o'tishda serverga yuboriladi, chunki
  /// aynan shu qiymat "bugun" qaysi kun ekanini va streak hisobini belgilaydi.
  String _timezone = DeviceTimezone.fallback;

  @override
  void initState() {
    super.initState();
    DeviceTimezone.resolve().then((tz) {
      if (mounted) setState(() => _timezone = tz);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
      AuthRegisterSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        timezone: _timezone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthNoticeListener(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final fieldErrors = state.fieldErrors;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: WdCircleBackButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.welcome),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        children: [
                          Text(
                            AppStrings.registerTitle,
                            style: AppTextStyles.display,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.registerSubtitle,
                            style: AppTextStyles.bodyMuted,
                          ),
                          const SizedBox(height: 32),
                          WdTextField(
                            controller: _nameController,
                            label: AppStrings.fullName,
                            hint: AppStrings.fullNameHint,
                            icon: AppIcons.user,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: Validators.fullName,
                            errorText: fieldErrors['full_name'],
                            enabled: !state.isSubmitting,
                            maxLength: 255,
                          ),
                          const SizedBox(height: 20),
                          WdTextField(
                            controller: _emailController,
                            label: AppStrings.email,
                            hint: AppStrings.emailHint,
                            icon: AppIcons.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newUsername],
                            validator: Validators.email,
                            errorText: fieldErrors['email'],
                            enabled: !state.isSubmitting,
                          ),
                          const SizedBox(height: 20),
                          WdTextField(
                            controller: _passwordController,
                            label: AppStrings.password,
                            hint: AppStrings.passwordHint,
                            icon: AppIcons.lock,
                            obscure: true,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: Validators.password,
                            errorText: fieldErrors['password'],
                            enabled: !state.isSubmitting,
                          ),
                          const SizedBox(height: 20),
                          WdTextField(
                            controller: _confirmController,
                            label: AppStrings.confirmPassword,
                            icon: AppIcons.lockConfirm,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            validator: (value) => Validators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                            enabled: !state.isSubmitting,
                            onSubmitted: _submit,
                          ),
                          const SizedBox(height: 20),
                          _TimezoneNote(timezone: _timezone),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      16 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      children: [
                        WdPrimaryButton(
                          label: AppStrings.registerAction,
                          isLoading: state.isSubmitting,
                          onPressed: _submit,
                        ),
                        WdTextLink(
                          prefix: AppStrings.haveAccount,
                          label: AppStrings.signIn,
                          onPressed: state.isSubmitting
                              ? () {}
                              : () => context.pushReplacement(AppRoutes.login),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Qaysi timezone yuborilayotganini ochiq ko'rsatamiz — keyinchalik
/// "streak nega noto'g'ri" degan savol tug'ilmasligi uchun.
class _TimezoneNote extends StatelessWidget {
  const _TimezoneNote({required this.timezone});

  final String timezone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const WdIcon(AppIcons.clock, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${AppStrings.timezone}: $timezone',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
