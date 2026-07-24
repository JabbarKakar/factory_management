import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/factory_repository.dart';
import '../../data/services/factory_display_service.dart';
import '../../domain/entities/factory_profile.dart';

part 'factory_profile_event.dart';
part 'factory_profile_state.dart';

class FactoryProfileBloc extends Bloc<FactoryProfileEvent, FactoryProfileState> {
  FactoryProfileBloc({
    required FactoryRepository repository,
    required FactoryDisplayService displayService,
  })  : _repository = repository,
        _displayService = displayService,
        super(const FactoryProfileState()) {
    on<FactoryProfileWatchStarted>(_onWatchStarted);
    on<FactoryProfileSaveRequested>(_onSaveRequested);
    on<_FactoryProfileUpdated>(_onProfileUpdated);
    on<_FactoryProfileWatchFailed>(_onWatchFailed);
  }

  final FactoryRepository _repository;
  final FactoryDisplayService _displayService;
  StreamSubscription<FactoryProfile?>? _subscription;

  Future<void> _onWatchStarted(
    FactoryProfileWatchStarted event,
    Emitter<FactoryProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FactoryProfileStatus.loading,
        factoryId: event.factoryId,
        clearMessages: true,
      ),
    );

    await _subscription?.cancel();
    _subscription = _repository.watchFactory(event.factoryId).listen(
          (profile) => add(_FactoryProfileUpdated(profile)),
          onError: (_) => add(const _FactoryProfileWatchFailed()),
        );
  }

  Future<void> _onSaveRequested(
    FactoryProfileSaveRequested event,
    Emitter<FactoryProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null) return;

    emit(state.copyWith(status: FactoryProfileStatus.saving, clearMessages: true));
    try {
      final updated = current.copyWith(
        name: event.name.trim(),
        phone: _optionalText(event.phone),
        address: _optionalText(event.address),
        ownerName: _optionalText(event.ownerName),
      );
      await _repository.updateFactory(updated);
      _displayService.invalidateCache(updated.id);
      emit(
        state.copyWith(
          status: FactoryProfileStatus.saved,
          profile: updated,
          successMessage: AppStrings.factoryProfileSaved,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FactoryProfileStatus.failure,
          errorMessage: AppStrings.factoryProfileSaveError,
        ),
      );
    }
  }

  void _onProfileUpdated(
    _FactoryProfileUpdated event,
    Emitter<FactoryProfileState> emit,
  ) {
    final profile = event.profile;
    if (profile == null) {
      emit(
        state.copyWith(
          status: FactoryProfileStatus.failure,
          errorMessage: AppStrings.factoryProfileLoadError,
        ),
      );
      return;
    }

    if (state.status == FactoryProfileStatus.saving) return;

    Formatters.activeCurrency = profile.invoiceSettings.currency;

    emit(
      state.copyWith(
        status: FactoryProfileStatus.loaded,
        profile: profile,
        errorMessage: null,
      ),
    );
  }

  void _onWatchFailed(
    _FactoryProfileWatchFailed event,
    Emitter<FactoryProfileState> emit,
  ) {
    emit(
      state.copyWith(
        status: FactoryProfileStatus.failure,
        errorMessage: AppStrings.factoryProfileLoadError,
      ),
    );
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
