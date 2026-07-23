import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/business_profile/business_profile_bloc.dart';
import '../../../core/di/injection.dart';
import 'business_profile_screen.dart';

class FactorySettingsScreen extends StatelessWidget {
  const FactorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const content = BusinessProfileScreen();

    final hasBlocInContext = context.read<BusinessProfileBloc?>() != null;

    if (!hasBlocInContext) {
      final authState = context.watch<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final factoryId = user?.factoryId;

      return BlocProvider(
        create: (_) {
          final bloc = getIt<BusinessProfileBloc>();
          if (factoryId != null && factoryId.isNotEmpty) {
            bloc.add(FetchBusinessProfile(factoryId));
          }
          return bloc;
        },
        child: content,
      );
    }

    return content;
  }
}
