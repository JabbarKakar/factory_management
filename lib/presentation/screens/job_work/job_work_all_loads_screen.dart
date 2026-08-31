import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/job_work_load_repository.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/job_work/job_work_load_list_tile.dart';
import '../../widgets/tile_options_menu.dart';

class JobWorkAllLoadsScreen extends StatefulWidget {
  const JobWorkAllLoadsScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  @override
  State<JobWorkAllLoadsScreen> createState() => _JobWorkAllLoadsScreenState();
}

class _JobWorkAllLoadsScreenState extends State<JobWorkAllLoadsScreen> {
  final _scrollController = ScrollController();
  static const _pageSize = 20;
  int _visibleCount = _pageSize;
  bool _isLoadingMore = false;
  String? _busyLoadId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.85) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    final blocState = context.read<JobWorkFormBloc>().state;
    if (_visibleCount < blocState.loads.length) {
      setState(() {
        _isLoadingMore = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _visibleCount += _pageSize;
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  Future<void> _openEditLoad(BuildContext context, JobWorkLoad load) async {
    if (load.isVirtual) return;
    final saved = await context.push<bool>(
      RoutePaths.jobWorkEditLoad(
        jobWorkId: widget.jobWorkId,
        loadId: load.id,
      ),
    );
    if (saved == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(widget.jobWorkId));
    }
  }

  Future<void> _confirmDeleteLoad(
    BuildContext context,
    JobWorkLoad load, {
    required bool isLastLoad,
  }) async {
    if (load.isVirtual || _busyLoadId != null) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isLastLoad
          ? AppStrings.deleteLastLoadTitle
          : AppStrings.deleteLoadTitle,
      message: isLastLoad
          ? AppStrings.deleteLastLoadMessage
          : AppStrings.deleteLoadMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final bloc = context.read<JobWorkFormBloc>();

    setState(() => _busyLoadId = load.id);
    try {
      final deletedJobWork =
          await getIt<JobWorkLoadRepository>().deleteLoad(load.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deletedJobWork
                ? AppStrings.loadAndJobWorkDeleted
                : AppStrings.loadDeleted,
          ),
        ),
      );
      if (deletedJobWork) {
        context.go(RoutePaths.jobWork);
      } else {
        bloc.add(JobWorkFormLoadRequested(widget.jobWorkId));
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.loadDeleteError),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyLoadId = null);
      }
    }
  }

  List<TileMenuAction> _loadMenuActions(
    BuildContext context,
    JobWorkLoad load, {
    required bool canEdit,
    required bool canDelete,
    required bool isLastLoad,
    required List<JobWorkCollection> collections,
  }) {
    if (load.isVirtual) return const [];

    final actions = <TileMenuAction>[];
    final hasOutput = load.output?.isRecorded == true;
    final canRecord = canEdit &&
        load.status.canRecordOutput &&
        (hasOutput || load.status != JobWorkStatus.agreed);
    final canCollect = canEdit &&
        JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          load,
          collections,
        );
    final canQc = canEdit && hasOutput;

    if (canEdit) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editLoad,
          icon: Icons.edit_outlined,
          onSelected: () => _openEditLoad(context, load),
        ),
      );
    }
    if (canRecord) {
      actions.add(
        TileMenuAction(
          label: hasOutput ? AppStrings.editOutput : AppStrings.recordOutput,
          icon: Icons.analytics_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.jobWorkLoadRecordOutput(
                jobWorkId: widget.jobWorkId,
                loadId: load.id,
              ),
            );
            if (context.mounted) {
              context
                  .read<JobWorkFormBloc>()
                  .add(JobWorkFormLoadRequested(widget.jobWorkId));
            }
          },
        ),
      );
    }
    if (canCollect) {
      actions.add(
        TileMenuAction(
          label: AppStrings.collectMaterial,
          icon: Icons.handshake_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.jobWorkLoadCollectMaterial(
                jobWorkId: widget.jobWorkId,
                loadId: load.id,
              ),
            );
            if (context.mounted) {
              context
                  .read<JobWorkFormBloc>()
                  .add(JobWorkFormLoadRequested(widget.jobWorkId));
            }
          },
        ),
      );
    }
    if (canQc) {
      actions.add(
        TileMenuAction(
          label: AppStrings.recordQcInspection,
          icon: Icons.verified_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.qualityChecksAddForReference(
                refType: QcReferenceType.jobWorkLoad,
                referenceId: load.id,
              ),
            );
            if (context.mounted) {
              context
                  .read<JobWorkFormBloc>()
                  .add(JobWorkFormLoadRequested(widget.jobWorkId));
            }
          },
        ),
      );
    }
    if (canDelete) {
      actions.add(
        TileMenuAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onSelected: () => _confirmDeleteLoad(
            context,
            load,
            isLastLoad: isLastLoad,
          ),
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.userCanEdit(AppModule.jobWork);
    final canDelete = context.userCanDelete(AppModule.jobWork);

    return BlocBuilder<JobWorkFormBloc, JobWorkFormState>(
      builder: (context, state) {
        final titleText = '${AppStrings.allLoads} (${state.loads.length})';

        return Scaffold(
          appBar: AppBar(title: Text(titleText)),
          body: Builder(
            builder: (context) {
              if (state.status == JobWorkFormStatus.initial ||
                  state.status == JobWorkFormStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final loads = List<JobWorkLoad>.from(state.loads)
                ..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
              if (loads.isEmpty) {
                return const Center(child: Text(AppStrings.noLoadsYet));
              }

              final visibleLoads = loads.take(_visibleCount).toList();
              final hasMore = _visibleCount < loads.length;

              final financeMap = state.order == null
                  ? null
                  : JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
                      order: state.order!,
                      loads: state.loads,
                      invoices: state.invoices.isNotEmpty
                          ? state.invoices
                          : (state.invoice == null
                              ? const []
                              : [state.invoice!]),
                      payments: state.payments,
                      alreadyScoped: true,
                    );

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                itemCount: visibleLoads.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == visibleLoads.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  final load = visibleLoads[index];
                  return JobWorkLoadListTile(
                    load: load,
                    paidAmount: financeMap?[load.id]?.paid,
                    dueAmount: financeMap?[load.id]?.due,
                    creditAmount: financeMap?[load.id]?.credit,
                    isBusy: _busyLoadId == load.id,
                    menuActions: _loadMenuActions(
                      context,
                      load,
                      canEdit: canEdit,
                      canDelete: canDelete,
                      isLastLoad: loads.length <= 1,
                      collections: state.collections,
                    ),
                    onTap: load.isVirtual
                        ? null
                        : () async {
                            await context.push(
                              RoutePaths.jobWorkLoadDetail(
                                jobWorkId: widget.jobWorkId,
                                loadId: load.id,
                              ),
                            );
                            if (context.mounted) {
                              context.read<JobWorkFormBloc>().add(
                                    JobWorkFormLoadRequested(widget.jobWorkId),
                                  );
                            }
                          },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}


