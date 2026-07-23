part of 'business_profile_bloc.dart';

sealed class BusinessProfileEvent extends Equatable {
  const BusinessProfileEvent();

  @override
  List<Object?> get props => [];
}

final class FetchBusinessProfile extends BusinessProfileEvent {
  const FetchBusinessProfile(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class UpdateBusinessProfileSection extends BusinessProfileEvent {
  const UpdateBusinessProfileSection({
    required this.profile,
    required this.section,
  });

  final FactoryProfile profile;
  final ProfileSection section;

  @override
  List<Object?> get props => [profile, section];
}

final class UploadProfileImage extends BusinessProfileEvent {
  const UploadProfileImage({
    required this.imageFile,
    required this.type,
  });

  final File imageFile;
  final ImageType type;

  @override
  List<Object?> get props => [imageFile, type];
}

final class AddBankAccount extends BusinessProfileEvent {
  const AddBankAccount(this.account);

  final BankAccount account;

  @override
  List<Object?> get props => [account];
}

final class UpdateBankAccount extends BusinessProfileEvent {
  const UpdateBankAccount(this.account);

  final BankAccount account;

  @override
  List<Object?> get props => [account];
}

final class DeleteBankAccount extends BusinessProfileEvent {
  const DeleteBankAccount(this.accountId);

  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

final class _BusinessProfileUpdated extends BusinessProfileEvent {
  const _BusinessProfileUpdated(this.profile);

  final FactoryProfile? profile;

  @override
  List<Object?> get props => [profile];
}

final class _BusinessProfileWatchFailed extends BusinessProfileEvent {
  const _BusinessProfileWatchFailed();
}
