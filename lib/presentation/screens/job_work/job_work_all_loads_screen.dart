import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../routes/route_paths.dart';
import '../../widgets/job_work/job_work_load_list_tile.dart';
import '../../widgets/paged_list_footer.dart';

class JobWorkAllLoadsScreen extends StatefulWidget {
  const JobWorkAllLoadsScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  @override
  State<JobWorkAllLoadsScreen> createState() => _JobWorkAllLoadsScreenState();
}

class _JobWorkAllLoadsScreenState extends State<JobWorkAllLoadsScreen> {
  static const _pageSize = 20;
  int _page = 0;

  void _changePage(int page) {
    setState(() => _page = page);
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

          final totalPages = (loads.length / _pageSize).ceil();
          final safePage = _page.clamp(0, totalPages - 1) as int;
          final start = safePage * _pageSize;
          final pageLoads = loads.skip(start).take(_pageSize).toList();
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

          return ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              for (final load in pageLoads)
                JobWorkLoadListTile(
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
                ),
              PagedListFooter(
                currentPage: safePage,
                totalPages: totalPages,
                totalItems: loads.length,
                onPageChanged: _changePage,
              ),
            ],
          );
        },
      ),
    );
  }
}
