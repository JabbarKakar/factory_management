part of 'business_profile_bloc.dart';

sealed class BusinessProfileState extends Equatable {
  const BusinessProfileState();

  @override
  List<Object?> get props => [];
}

final class BusinessProfileInitial extends BusinessProfileState {
  const BusinessProfileInitial();
}

final class BusinessProfileLoading extends BusinessProfileState {
  const BusinessProfileLoading();
}

final class BusinessProfileLoaded extends BusinessProfileState {
  const BusinessProfileLoaded(
    this.profile, {
    this.isSaving = false,
    this.uploadingImageType,
    this.successMessage,
    this.errorMessage,
  });

  final FactoryProfile profile;
  final bool isSaving;
  final ImageType? uploadingImageType;
  final String? successMessage;
  final String? errorMessage;

  BusinessProfileLoaded copyWith({
    FactoryProfile? profile,
    bool? isSaving,
    ImageType? uploadingImageType,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    bool clearUploading = false,
  }) {
    return BusinessProfileLoaded(
      profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      uploadingImageType: clearUploading
          ? null
          : uploadingImageType ?? this.uploadingImageType,
      successMessage:
          clearMessages ? null : successMessage ?? this.successMessage,
      errorMessage:
          clearMessages ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        isSaving,
        uploadingImageType,
        successMessage,
        errorMessage,
      ];
}

final class BusinessProfileFailure extends BusinessProfileState {
  const BusinessProfileFailure(this.errorMessage);

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
