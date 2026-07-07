part of 'factory_profile_bloc.dart';

enum FactoryProfileStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  failure,
}

class FactoryProfileState extends Equatable {
  const FactoryProfileState({
    this.status = FactoryProfileStatus.initial,
    this.factoryId,
    this.profile,
    this.errorMessage,
    this.successMessage,
  });

  final FactoryProfileStatus status;
  final String? factoryId;
  final FactoryProfile? profile;
  final String? errorMessage;
  final String? successMessage;

  FactoryProfileState copyWith({
    FactoryProfileStatus? status,
    String? factoryId,
    FactoryProfile? profile,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return FactoryProfileState(
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      profile: profile ?? this.profile,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        factoryId,
        profile,
        errorMessage,
        successMessage,
      ];
}
