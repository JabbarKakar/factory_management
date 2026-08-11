import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/sales_order.dart';
import '../../routes/route_paths.dart';
import '../../widgets/paged_list_footer.dart';
import '../../widgets/sales/sales_order_list_tile.dart';

class SalesAllOrdersScreen extends StatefulWidget {
  const SalesAllOrdersScreen({required this.agreementId, super.key});

  final String agreementId;

  @override
  State<SalesAllOrdersScreen> createState() => _SalesAllOrdersScreenState();
}

class _SalesAllOrdersScreenState extends State<SalesAllOrdersScreen> {
  static const _pageSize = 20;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.allOrders)),
      body: BlocBuilder<SalesAgreementDetailBloc, SalesAgreementDetailState>(
        builder: (context, state) {
          if (state.status == SalesAgreementDetailStatus.initial ||
              state.status == SalesAgreementDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = List<SalesOrder>.from(state.orders)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (orders.isEmpty) {
            return const Center(child: Text(AppStrings.noOrdersUnderAgreement));
          }

          final totalPages = (orders.length / _pageSize).ceil();
          final safePage = _page.clamp(0, totalPages - 1) as int;
          final start = safePage * _pageSize;
          final pageOrders = orders.skip(start).take(_pageSize).toList();

          return ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              for (final order in pageOrders)
                SalesOrderListTile(
                  order: order,
                  onTap: () async {
                    await context.push(
                      RoutePaths.salesOrderDetail(
                        agreementId: widget.agreementId,
                        salesOrderId: order.id,
                      ),
                    );
                    if (context.mounted) {
                      context.read<SalesAgreementDetailBloc>().add(
                            const SalesAgreementDetailRefreshRequested(),
                          );
                    }
                  },
                ),
              PagedListFooter(
                currentPage: safePage,
                totalPages: totalPages,
                totalItems: orders.length,
                onPageChanged: (page) => setState(() => _page = page),
              ),
            ],
          );
        },
      ),
    );
  }
}
