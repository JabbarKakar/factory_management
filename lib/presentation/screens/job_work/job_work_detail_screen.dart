import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../routes/route_paths.dart';
import '../../widgets/job_work/job_work_status_badge.dart';
import '../../widgets/settings_section.dart';

class JobWorkDetailScreen extends StatelessWidget {
  const JobWorkDetailScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobWorkFormBloc, JobWorkFormState>(
      builder: (context, state) {
        if (state.status == JobWorkFormStatus.loading ||
            state.status == JobWorkFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkDetails)),
            body: Center(
              child: Text(state.errorMessage ?? 'Job work order not found'),
            ),
          );
        }

        final canEdit = order.status.isActive;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.jobWorkDetails),
            actions: [
              if (canEdit)
                IconButton(
                  onPressed: () =>
                      context.push(RoutePaths.jobWorkEdit(order.id)),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editJobWorkOrder,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.jobWorkNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          JobWorkStatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.pricingAgreement,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(
                        AppStrings.negotiatedAmount,
                        Formatters.currencyPkr(order.negotiatedFinalAmount),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.advanceReceived,
                        Formatters.currencyPkr(order.advanceReceived),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.balanceDue,
                        Formatters.currencyPkr(order.balanceDue),
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.paymentTerms,
                        order.paymentTerms.label,
                      ),
                      if (order.paymentDueDate != null) ...[
                        const SizedBox(height: 8),
                        _Row(
                          AppStrings.paymentDueDate,
                          DateFormat.yMMMd().format(order.paymentDueDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.inputMaterial,
                child: _DetailSection(
                  rows: [
                    _Row(AppStrings.marbleVariety, order.marbleVariety),
                    _Row(AppStrings.blockCount, '${order.blockCount}'),
                    _Row(
                      AppStrings.totalTons,
                      order.totalTons.toStringAsFixed(2),
                    ),
                    if (order.totalVolumeM3 != null)
                      _Row(
                        AppStrings.totalVolume,
                        order.totalVolumeM3!.toStringAsFixed(2),
                      ),
                    if (order.blockDimensions != null)
                      _Row(
                        AppStrings.blockDimensions,
                        order.blockDimensions!,
                      ),
                    if (order.conditionNotes != null)
                      _Row(AppStrings.conditionNotes, order.conditionNotes!),
                    if (order.vehicleNumber != null)
                      _Row(AppStrings.vehicleNumber, order.vehicleNumber!),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.cuttingSpecification,
                child: _DetailSection(
                  rows: [
                    _Row(
                      AppStrings.cuttingStrategy,
                      order.cuttingStrategy.label,
                    ),
                    _Row(AppStrings.targetProduct, order.targetProduct.label),
                    _Row(
                      AppStrings.tileSlabSizes,
                      order.sizes.join(', '),
                    ),
                    _Row(AppStrings.thickness, order.thickness),
                    _Row(AppStrings.finishRequired, order.finish.label),
                    if (order.expectedOutputSqFt != null)
                      _Row(
                        AppStrings.expectedOutput,
                        order.expectedOutputSqFt!.toStringAsFixed(0),
                      ),
                    if (order.specialInstructions != null)
                      _Row(
                        AppStrings.specialInstructions,
                        order.specialInstructions!,
                      ),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.customerAndDates,
                child: _DetailSection(
                  rows: [
                    _Row(
                      AppStrings.receivedDate,
                      DateFormat.yMMMd().format(order.receivedDate),
                    ),
                    if (order.expectedCompletionDate != null)
                      _Row(
                        AppStrings.expectedCompletion,
                        DateFormat.yMMMd()
                            .format(order.expectedCompletionDate!),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.outputRecordingSprint4,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
