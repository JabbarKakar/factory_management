import '../entities/app_user.dart';
import '../enums/user_enums.dart';

/// Tenancy and account-state helpers for onboarding (Phase 1).
extension AppUserTenancy on AppUser {
  static const String legacyDefaultFactoryId = 'default';

  bool get isActive => status == UserAccountStatus.active;

  bool get hasValidFactory =>
      factoryId.isNotEmpty && factoryId != legacyDefaultFactoryId;

  bool get needsOnboarding => !hasValidFactory;

  bool get canAccessFactoryData => isActive && hasValidFactory;
}
