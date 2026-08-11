import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../routes/route_paths.dart';
import '../../widgets/job_work/job_work_load_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.allLoads)),
      body: BlocBuilder<JobWorkFormBloc, JobWorkFormState>(
        builder: (context, state) {
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
  }
}

