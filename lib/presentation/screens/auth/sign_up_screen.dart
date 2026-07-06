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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _factoryNameController = TextEditingController();
  final _factoryPhoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _factoryNameController.dispose();
    _factoryPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            factoryName: _factoryNameController.text,
            factoryPhone: _factoryPhoneController.text.trim().isEmpty
                ? null
                : _factoryPhoneController.text,
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
                                AppStrings.signUp,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.signUpSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  labelText: AppStrings.yourName,
                                  labelStyle: TextStyle(fontSize: 12),
                                  prefixIcon: Icon(Icons.person_outline, size: 20),
                                  isDense: true,
                                ),
                                validator: (value) => Validators.requiredText(
                                  value,
                                  field: 'Name',
                                ),
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 12),
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
                                controller: _factoryNameController,
                                textInputAction: TextInputAction.next,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  labelText: AppStrings.factoryName,
                                  labelStyle: TextStyle(fontSize: 12),
                                  prefixIcon: Icon(
                                    Icons.factory_outlined,
                                    size: 20,
                                  ),
                                  isDense: true,
                                ),
                                validator: (value) => Validators.requiredText(
                                  value,
                                  field: 'Factory name',
                                ),
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _factoryPhoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.telephoneNumber],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  labelText: AppStrings.factoryPhoneOptional,
                                  labelStyle: TextStyle(fontSize: 12),
                                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                  isDense: true,
                                ),
                                validator: Validators.optionalPhone,
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.newPassword],
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
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.newPassword],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  labelText: AppStrings.confirmPassword,
                                  labelStyle: const TextStyle(fontSize: 12),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () => setState(
                                              () => _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                            ),
                                  ),
                                  isDense: true,
                                ),
                                validator: (value) => Validators.confirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                                enabled: !isLoading,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 16),
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
                                        AppStrings.signUp,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.go(RoutePaths.login),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.alreadyHaveAccount,
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
