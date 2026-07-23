import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/factory_repository.dart';
import '../../data/services/factory_display_service.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/factory_profile.dart';
import '../../domain/enums/business_profile_enums.dart';

part 'business_profile_event.dart';
part 'business_profile_state.dart';

class BusinessProfileBloc
    extends Bloc<BusinessProfileEvent, BusinessProfileState> {
  BusinessProfileBloc({
    required FactoryRepository repository,
    required FactoryDisplayService displayService,
  })  : _repository = repository,
        _displayService = displayService,
        super(const BusinessProfileInitial()) {
    on<FetchBusinessProfile>(_onFetchBusinessProfile);
    on<UpdateBusinessProfileSection>(_onUpdateSection);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<AddBankAccount>(_onAddBankAccount);
    on<UpdateBankAccount>(_onUpdateBankAccount);
    on<DeleteBankAccount>(_onDeleteBankAccount);
    on<_BusinessProfileUpdated>(_onProfileUpdated);
    on<_BusinessProfileWatchFailed>(_onWatchFailed);
  }

  final FactoryRepository _repository;
  final FactoryDisplayService _displayService;

  StreamSubscription<FactoryProfile?>? _subscription;

  Future<void> _onFetchBusinessProfile(
    FetchBusinessProfile event,
    Emitter<BusinessProfileState> emit,
  ) async {
    emit(const BusinessProfileLoading());

    await _subscription?.cancel();
    _subscription = _repository.watchFactory(event.factoryId).listen(
          (profile) => add(_BusinessProfileUpdated(profile)),
          onError: (_) => add(const _BusinessProfileWatchFailed()),
        );
  }

  Future<void> _onUpdateSection(
    UpdateBusinessProfileSection event,
    Emitter<BusinessProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BusinessProfileLoaded) return;

    emit(currentState.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.updateSection(
        factoryId: event.profile.id,
        section: event.section,
        profile: event.profile,
      );
      _displayService.invalidateCache(event.profile.id);

      emit(
        currentState.copyWith(
          isSaving: false,
          profile: event.profile,
          successMessage: '${event.section.title} updated successfully.',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to update section: $e',
        ),
      );
    }
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImage event,
    Emitter<BusinessProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BusinessProfileLoaded) return;

    emit(
      currentState.copyWith(
        uploadingImageType: event.type,
        clearMessages: true,
      ),
    );

    try {
      final downloadUrl = await _repository.uploadProfileImage(
        factoryId: currentState.profile.id,
        imageFile: event.imageFile,
        type: event.type,
      );

      FactoryProfile updatedProfile = currentState.profile;

      switch (event.type) {
        case ImageType.logo:
          updatedProfile = updatedProfile.copyWith(
            identity: updatedProfile.identity.copyWith(logoUrl: downloadUrl),
          );
          await _repository.updateSection(
            factoryId: updatedProfile.id,
            section: ProfileSection.identity,
            profile: updatedProfile,
          );
          break;
        case ImageType.signature:
          updatedProfile = updatedProfile.copyWith(
            invoiceSettings: updatedProfile.invoiceSettings.copyWith(
              signatureImageUrl: downloadUrl,
            ),
          );
          await _repository.updateSection(
            factoryId: updatedProfile.id,
            section: ProfileSection.invoiceSettings,
            profile: updatedProfile,
          );
          break;
        case ImageType.stamp:
          updatedProfile = updatedProfile.copyWith(
            invoiceSettings: updatedProfile.invoiceSettings.copyWith(
              stampImageUrl: downloadUrl,
            ),
          );
          await _repository.updateSection(
            factoryId: updatedProfile.id,
            section: ProfileSection.invoiceSettings,
            profile: updatedProfile,
          );
          break;
      }

      _displayService.invalidateCache(updatedProfile.id);

      emit(
        currentState.copyWith(
          clearUploading: true,
          profile: updatedProfile,
          successMessage: '${event.type.label} uploaded successfully.',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          clearUploading: true,
          errorMessage: 'Failed to upload ${event.type.label}: $e',
        ),
      );
    }
  }

  Future<void> _onAddBankAccount(
    AddBankAccount event,
    Emitter<BusinessProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BusinessProfileLoaded) return;

    emit(currentState.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.addBankAccount(currentState.profile.id, event.account);
      _displayService.invalidateCache(currentState.profile.id);

      emit(
        currentState.copyWith(
          isSaving: false,
          successMessage: 'Bank account added successfully.',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to add bank account: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateBankAccount(
    UpdateBankAccount event,
    Emitter<BusinessProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BusinessProfileLoaded) return;

    emit(currentState.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.updateBankAccount(
        currentState.profile.id,
        event.account,
      );
      _displayService.invalidateCache(currentState.profile.id);

      emit(
        currentState.copyWith(
          isSaving: false,
          successMessage: 'Bank account updated successfully.',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to update bank account: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteBankAccount(
    DeleteBankAccount event,
    Emitter<BusinessProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BusinessProfileLoaded) return;

    emit(currentState.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.deleteBankAccount(
        currentState.profile.id,
        event.accountId,
      );
      _displayService.invalidateCache(currentState.profile.id);

      emit(
        currentState.copyWith(
          isSaving: false,
          successMessage: 'Bank account removed successfully.',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to remove bank account: $e',
        ),
      );
    }
  }

  void _onProfileUpdated(
    _BusinessProfileUpdated event,
    Emitter<BusinessProfileState> emit,
  ) {
    final profile = event.profile;
    if (profile == null) {
      emit(const BusinessProfileFailure('Failed to load business profile.'));
      return;
    }

    final currentState = state;
    if (currentState is BusinessProfileLoaded && currentState.isSaving) {
      return;
    }

    emit(BusinessProfileLoaded(profile));
  }

  void _onWatchFailed(
    _BusinessProfileWatchFailed event,
    Emitter<BusinessProfileState> emit,
  ) {
    emit(const BusinessProfileFailure('Error connecting to business profile.'));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
