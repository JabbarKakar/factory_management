import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/entities/expense.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../settings_section.dart';

class SupplierPurchasesSection extends StatefulWidget {
  const SupplierPurchasesSection({
    required this.supplierId,
    super.key,
  });

  final String supplierId;

  static const int previewLimit = 10;

  @override
  State<SupplierPurchasesSection> createState() =>
      _SupplierPurchasesSectionState();
}

class _SupplierPurchasesSectionState extends State<SupplierPurchasesSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final factoryId = readFactoryId(context);
    if (factoryId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Expense>>(
      stream: getIt<ExpenseRepository>().watchExpenses(factoryId),
      builder: (context, snapshot) {
        final purchases = (snapshot.data ?? const <Expense>[])
            .where((expense) => expense.supplierId == widget.supplierId)
            .toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

        final total = purchases.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );

        final hasMore = purchases.length > SupplierPurchasesSection.previewLimit;
        final visiblePurchases = _showAll || !hasMore
            ? purchases
            : purchases.take(SupplierPurchasesSection.previewLimit).toList();

        return SettingsSection(
          title: AppStrings.purchaseHistory,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.totalPurchases,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currencyPkr(total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (purchases.isNotEmpty)
                      Text(
                        '${purchases.length} ${AppStrings.purchasesCount}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (purchases.isEmpty)
                  Text(
                    '${AppStrings.noPurchasesYet}\n${AppStrings.noPurchasesHint}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else ...[
                  ...visiblePurchases.map(
                    (expense) => _PurchaseTile(expense: expense),
                  ),
                  if (hasMore)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _showAll = !_showAll),
                        child: Text(
                          _showAll
                              ? AppStrings.showLessPurchases
                              : AppStrings.viewAllPurchases,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(expense.description),
      subtitle: Text(
        '${expense.category.label} · ${DateFormat.yMMMd().format(expense.expenseDate)}',
        style: TextStyle(color: muted),
      ),
      trailing: Text(
        Formatters.currencyPkr(expense.amount),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      onTap: () => context.push(RoutePaths.expenseEdit(expense.id)),
    );
  }
}
