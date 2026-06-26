import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';

String? readFactoryId(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  if (state is AuthAuthenticated) {
    return state.user.factoryId;
  }
  return null;
}
