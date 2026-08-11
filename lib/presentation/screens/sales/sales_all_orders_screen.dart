import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../../data/services/sales_order_dispatch_status_helper.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/sales/sales_order_list_tile.dart';
import '../../widgets/tile_options_menu.dart';

class SalesAllOrdersScreen extends StatefulWidget {
  const SalesAllOrdersScreen({required this.agreementId, super.key});

  final String agreementId;

  @override
  State<SalesAllOrdersScreen> createState() => _SalesAllOrdersScreenState();
}

class _SalesAllOrdersScreenState extends State<SalesAllOrdersScreen> {
  final _scrollController = ScrollController();
  static const _pageSize = 20;
  int _visibleCount = _pageSize;
  bool _isLoadingMore = false;
  String? _busyOrderId;

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
    final blocState = context.read<SalesAgreementDetailBloc>().state;
    if (_visibleCount < blocState.orders.length) {
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

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Future<void> _confirmDelete(SalesOrder order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteSalesOrderTitle,
      message: AppStrings.deleteSalesOrderMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyOrderId = order.id);

    try {
      await getIt<SalesOrderRepository>().deleteSalesOrder(order.id);
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderDeleted);
      context.read<SalesAgreementDetailBloc>().add(
            const SalesAgreementDetailRefreshRequested(),
          );
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderDeleteError, isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyOrderId = null);
      }
    }
  }

  Future<void> _confirmCancel(SalesOrder order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.cancelSalesOrderTitle,
      message: AppStrings.cancelSalesOrderMessage,
      confirmLabel: AppStrings.cancelOrder,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyOrderId = order.id);

    try {
      await getIt<SalesOrderRepository>().cancelSalesOrder(order.id);
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderCancelled);
      context.read<SalesAgreementDetailBloc>().add(
            const SalesAgreementDetailRefreshRequested(),
          );
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderCancelError, isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyOrderId = null);
      }
    }
  }

  List<TileMenuAction> _menuActionsFor(
    SalesOrder order, {
    required bool canEdit,
    required bool canDelete,
  }) {
    final status = order.status;
    final hasInvoice = order.invoiceId != null && order.invoiceId!.isNotEmpty;
    final canDispatch =
        SalesOrderDispatchStatusHelper.canScheduleDispatch(status);
    final actions = <TileMenuAction>[];
    final agreementId = order.agreementId?.trim().isNotEmpty == true
        ? order.agreementId!.trim()
        : widget.agreementId;

    if (canEdit) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editSalesOrder,
          icon: Icons.edit_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.salesOrderEdit(
                agreementId: agreementId,
                salesOrderId: order.id,
              ),
            );
            if (mounted) {
              context.read<SalesAgreementDetailBloc>().add(
                    const SalesAgreementDetailRefreshRequested(),
                  );
            }
          },
        ),
      );
    }

    if ((status == SalesOrderStatus.ready ||
            status == SalesOrderStatus.partiallyDispatched) &&
        !hasInvoice) {
      actions.add(
        TileMenuAction(
          label: AppStrings.generateInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.salesInvoice(
                agreementId: agreementId,
                salesOrderId: order.id,
              ),
            );
            if (mounted) {
              context.read<SalesAgreementDetailBloc>().add(
                    const SalesAgreementDetailRefreshRequested(),
                  );
            }
          },
        ),
      );
    }

    if (hasInvoice) {
      actions.add(
        TileMenuAction(
          label: AppStrings.viewInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.salesInvoice(
                agreementId: agreementId,
                salesOrderId: order.id,
              ),
            );
            if (mounted) {
              context.read<SalesAgreementDetailBloc>().add(
                    const SalesAgreementDetailRefreshRequested(),
                  );
            }
          },
        ),
      );
      if (order.balanceDue > 0 &&
          status != SalesOrderStatus.closed &&
          status != SalesOrderStatus.cancelled) {
        actions.add(
          TileMenuAction(
            label: AppStrings.recordPayment,
            icon: Icons.payments_outlined,
            onSelected: () async {
              await context.push(
                RoutePaths.salesRecordPayment(order.invoiceId!),
              );
              if (mounted) {
                context.read<SalesAgreementDetailBloc>().add(
                      const SalesAgreementDetailRefreshRequested(),
                    );
              }
            },
          ),
        );
      }
    }

    if (canDispatch) {
      actions.add(
        TileMenuAction(
          label: AppStrings.dispatchStock,
          icon: Icons.local_shipping_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.deliveriesAddForOrder(order.id),
            );
            if (mounted) {
              context.read<SalesAgreementDetailBloc>().add(
                    const SalesAgreementDetailRefreshRequested(),
                  );
            }
          },
        ),
      );
    }

    if (canEdit && status != SalesOrderStatus.cancelled) {
      actions.add(
        TileMenuAction(
          label: AppStrings.cancelOrder,
          icon: Icons.cancel_outlined,
          onSelected: () => _confirmCancel(order),
        ),
      );
    }

    if (canDelete) {
      actions.add(
        TileMenuAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onSelected: () => _confirmDelete(order),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.userCanEdit(AppModule.sales);
    final canDelete = context.userCanDelete(AppModule.sales);

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

          final visibleOrders = orders.take(_visibleCount).toList();
          final hasMore = _visibleCount < orders.length;

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: visibleOrders.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == visibleOrders.length) {
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

              final order = visibleOrders[index];
              return SalesOrderListTile(
                order: order,
                isBusy: _busyOrderId == order.id,
                menuActions: _menuActionsFor(
                  order,
                  canEdit: canEdit,
                  canDelete: canDelete,
                ),
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
              );
            },
          );
        },
      ),
    );
  }
}


