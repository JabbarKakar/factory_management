import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../routes/route_paths.dart';

/// Deep-link shim: resolves a bare sales order id to agreement-scoped route.
class SalesOrderLinkRedirectScreen extends StatefulWidget {
  const SalesOrderLinkRedirectScreen({
    required this.salesOrderId,
    super.key,
  });

  final String salesOrderId;

  @override
  State<SalesOrderLinkRedirectScreen> createState() =>
      _SalesOrderLinkRedirectScreenState();
}

class _SalesOrderLinkRedirectScreenState
    extends State<SalesOrderLinkRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    try {
      final order =
          await getIt<SalesOrderRepository>().getSalesOrder(widget.salesOrderId);
      if (!mounted) return;

      final agreementId = order?.agreementId?.trim() ?? '';
      if (order != null && agreementId.isNotEmpty) {
        context.go(
          RoutePaths.salesOrderDetail(
            agreementId: agreementId,
            salesOrderId: widget.salesOrderId,
          ),
        );
        return;
      }

      context.go(RoutePaths.sales);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sales order is not linked to an agreement.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      context.go(RoutePaths.sales);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.salesLoadError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sales)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
