part of 'factory_profile_bloc.dart';

sealed class FactoryProfileEvent extends Equatable {
  const FactoryProfileEvent();

  @override
  List<Object?> get props => [];
}

final class FactoryProfileWatchStarted extends FactoryProfileEvent {
  const FactoryProfileWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class FactoryProfileSaveRequested extends FactoryProfileEvent {
  const FactoryProfileSaveRequested({
    required this.name,
    this.phone,
    this.address,
    this.ownerName,
  });

  final String name;
  final String? phone;
  final String? address;
  final String? ownerName;

  @override
  List<Object?> get props => [name, phone, address, ownerName];
}

final class _FactoryProfileUpdated extends FactoryProfileEvent {
  const _FactoryProfileUpdated(this.profile);

  final FactoryProfile? profile;

  @override
  List<Object?> get props => [profile];
}

final class _FactoryProfileWatchFailed extends FactoryProfileEvent {
  const _FactoryProfileWatchFailed();
}
