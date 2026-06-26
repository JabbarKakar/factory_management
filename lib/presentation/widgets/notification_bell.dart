import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/notification/notification_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../routes/route_paths.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      bloc: getIt<NotificationBloc>(),
      buildWhen: (prev, curr) => prev.unreadCount != curr.unreadCount,
      builder: (context, state) {
        final unread = state.unreadCount;

        return IconButton(
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: AppStrings.notifications,
          onPressed: () => context.push(RoutePaths.notifications),
        );
      },
    );
  }
}
