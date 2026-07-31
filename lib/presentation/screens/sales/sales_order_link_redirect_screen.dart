import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/sales_agreement_repository.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../routes/route_paths.dart';

/// Deep-link shim: resolves a bare sales order id to agreement-scoped route.
///
/// Legacy orders missing `agreementId` are repaired via
/// [SalesAgreementRepository.ensureAgreementForOrder] before navigation.
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
      final orderRepo = getIt<SalesOrderRepository>();
      var order = await orderRepo.getSalesOrder(widget.salesOrderId);
      if (!mounted) return;

      if (order == null) {
        context.go(RoutePaths.sales);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.salesLoadError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      var agreementId = order.agreementId?.trim() ?? '';
      if (agreementId.isEmpty) {
        final agreement = await getIt<SalesAgreementRepository>()
            .ensureAgreementForOrder(order);
        agreementId = agreement.id;
        order = await orderRepo.getSalesOrder(widget.salesOrderId) ?? order;
      }

      if (!mounted) return;
      if (agreementId.isEmpty) {
        context.go(RoutePaths.sales);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.salesOrderAgreementLinkFailed),
          ),
        );
        return;
      }

      context.go(
        RoutePaths.salesOrderDetail(
          agreementId: agreementId,
          salesOrderId: widget.salesOrderId,
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
