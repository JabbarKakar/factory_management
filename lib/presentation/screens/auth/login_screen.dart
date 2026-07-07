import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../routes/route_paths.dart';
import '../../widgets/auth/login_brand_header.dart';
import '../../widgets/dashboard/dashboard_surface.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final theme = Theme.of(context);

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LoginBrandHeader(),
                      DashboardSurfaceCard(
                        compact: true,
                        borderRadius: 14,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.login,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  labelText: AppStrings.email,
                                  labelStyle: TextStyle(fontSize: 12),
                                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                                  isDense: true,
                                ),
                                validator: Validators.email,
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  labelText: AppStrings.password,
                                  labelStyle: const TextStyle(fontSize: 12),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                  ),
                                  isDense: true,
                                ),
                                validator: Validators.password,
                                enabled: !isLoading,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () =>
                                          context.push(RoutePaths.forgotPassword),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.push(RoutePaths.signUp),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.createFactoryAccount,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.login,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.push(RoutePaths.acceptInvite),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.haveInviteAccept,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
