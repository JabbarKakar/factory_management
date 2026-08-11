import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/sales_order.dart';
import '../../routes/route_paths.dart';
import '../../widgets/sales/sales_order_list_tile.dart';

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

