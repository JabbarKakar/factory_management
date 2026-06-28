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
import '../job_work/job_work_detail_section.dart';

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

        return JobWorkDetailSection(
          title: AppStrings.purchaseHistory,
          icon: Icons.receipt_long_outlined,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            Formatters.currencyPkr(total),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                  height: 1.15,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (purchases.isNotEmpty)
                      Text(
                        '${purchases.length} ${AppStrings.purchasesCount}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (purchases.isEmpty)
                  Text(
                    '${AppStrings.noPurchasesYet}\n${AppStrings.noPurchasesHint}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.35,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else ...[
                  for (var i = 0; i < visiblePurchases.length; i++) ...[
                    _PurchaseRow(expense: visiblePurchases[i]),
                    if (i < visiblePurchases.length - 1)
                      const SizedBox(height: 8),
                  ],
                  if (hasMore)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _showAll = !_showAll),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: Text(
                          _showAll
                              ? AppStrings.showLessPurchases
                              : AppStrings.viewAllPurchases,
                          style: const TextStyle(fontSize: 12),
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

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(expense.expenseDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.expenseEdit(expense.id)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.category.label} · $dateLabel',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontSize: 10,
                            height: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.currencyPkr(expense.amount),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
