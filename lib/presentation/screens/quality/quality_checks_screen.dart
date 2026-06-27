import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/quality/qc_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quality/qc_list_tile.dart';

class QualityChecksScreen extends StatefulWidget {
  const QualityChecksScreen({this.initialFilter, super.key});

  final QcListFilter? initialFilter;

  @override
  State<QualityChecksScreen> createState() => _QualityChecksScreenState();
}

class _QualityChecksScreenState extends State<QualityChecksScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter != null && filter != QcListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<QcListBloc>().add(QcListFilterChanged(filter));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.qualityControl)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-quality-checks',
        onPressed: () => context.push(RoutePaths.qualityChecksAdd),
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text(AppStrings.recordQcInspection),
      ),
      body: Column(
        children: [
          BlocBuilder<QcListBloc, QcListState>(
            buildWhen: (prev, curr) =>
                prev.monthlyInspectionCount != curr.monthlyInspectionCount ||
                prev.monthlyPassRate != curr.monthlyPassRate,
            builder: (context, state) {
              if (state.monthlyInspectionCount == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.assessment_outlined),
                    title: Text(AppStrings.qcThisMonth),
                    subtitle: Text(
                      '${state.monthlyInspectionCount} '
                      '${AppStrings.qcInspectionsThisMonth} · '
                      '${state.monthlyPassRate.toStringAsFixed(1)}% '
                      '${AppStrings.avgPassRate}',
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchQualityChecks,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<QcListBloc>()
                              .add(const QcListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<QcListBloc>().add(QcListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _QcFilterBar(),
          Expanded(
            child: BlocBuilder<QcListBloc, QcListState>(
              builder: (context, state) {
                if (state.status == QcListStatus.loading &&
                    state.checks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == QcListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.qcLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context
                              .read<QcListBloc>()
                              .add(QcListWatchStarted(factoryId));
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleChecks.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.fact_check_outlined,
                    title: state.checks.isEmpty
                        ? AppStrings.noQualityChecksYet
                        : AppStrings.noQualityChecksFound,
                    subtitle: state.checks.isEmpty
                        ? AppStrings.noQualityChecksHint
                        : null,
                    action: state.checks.isEmpty
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.qualityChecksAdd),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text(AppStrings.recordQcInspection),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId != null) {
                      context
                          .read<QcListBloc>()
                          .add(QcListWatchStarted(factoryId));
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: state.visibleChecks.length,
                    itemBuilder: (context, index) {
                      final check = state.visibleChecks[index];
                      return QcListTile(
                        check: check,
                        onTap: () =>
                            context.push(RoutePaths.qualityCheckDetail(check.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QcFilterBar extends StatelessWidget {
  const _QcFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QcListBloc, QcListState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: QcListFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: state.filter == filter,
                  onSelected: (_) {
                    context
                        .read<QcListBloc>()
                        .add(QcListFilterChanged(filter));
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
