import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_confirm_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/delivery.dart';
import '../../widgets/delivery/dispatch_stock_form_controller.dart';
import '../../widgets/delivery/dispatch_stock_recording_panel.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  const ConfirmDeliveryScreen({required this.deliveryId, super.key});

  final String deliveryId;

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  final _notesController = TextEditingController();
  final _receiverNameController = TextEditingController();
  DispatchStockFormController? _stockController;
  DateTime _actualDate = DateTime.now();
  bool _receiverInitialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    _receiverNameController.dispose();
    _stockController?.dispose();
    super.dispose();
  }

  void _initController(Delivery delivery) {
    if (_stockController == null) {
      _stockController = DispatchStockFormController.forConfirm(
        lineItems: delivery.lineItems,
      );
      _stockController!.addListenerSafe(() {
        if (mounted) setState(() {});
      });
    }
    if (!_receiverInitialized) {
      _receiverInitialized = true;
      if (delivery.receiverName != null && delivery.receiverName!.isNotEmpty) {
        _receiverNameController.text = delivery.receiverName!;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _actualDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _actualDate = picked);
  }

  void _submit(BuildContext context) {
    final controller = _stockController;
    if (controller == null) return;

    context.read<DeliveryConfirmBloc>().add(
          DeliveryConfirmSubmitted(
            actualDeliveryDate: _actualDate,
            lineItems: controller.buildConfirmedLineItems(),
            notes: _notesController.text.trim(),
            receiverName: _receiverNameController.text.trim(),
          ),
        );
  }

  String _appBarSubtitle(Delivery delivery) {
    if (delivery.deliveryNumber.isNotEmpty) {
      return '${delivery.deliveryNumber} · ${delivery.customerName}';
    }
    return delivery.customerName;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryConfirmBloc, DeliveryConfirmState>(
      listener: (context, state) {
        if (state.status == DeliveryConfirmStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.deliveryConfirmed)),
          );
          context.pop(true);
        }
        if (state.status == DeliveryConfirmStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == DeliveryConfirmStatus.loading ||
            state.status == DeliveryConfirmStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.confirmDelivery,
                subtitle: AppStrings.confirmDelivery,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = state.delivery;
        if (delivery == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.confirmDelivery,
                subtitle: AppStrings.confirmDelivery,
              ),
            ),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.deliveryNotFound),
            ),
          );
        }

        _initController(delivery);
        final isSaving = state.status == DeliveryConfirmStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.confirmDelivery,
              subtitle: _appBarSubtitle(delivery),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              JobWorkDetailSection(
                title: AppStrings.actualDeliveryDate,
                icon: Icons.event_outlined,
                child: AppFormSectionBody(
                  children: [
                    AppFormDateField(
                      label: AppStrings.actualDeliveryDate,
                      value: DateFormat.yMMMd().format(_actualDate),
                      onTap: isSaving ? null : _pickDate,
                    ),
                    AppFormFields.gap,
                    TextFormField(
                      controller: _receiverNameController,
                      enabled: !isSaving,
                      style: AppFormFields.valueStyle(context),
                      decoration: AppFormFields.decoration(
                        context,
                        label: AppStrings.receiverName,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.itemsToDeliver,
                icon: Icons.inventory_2_outlined,
                child: AppFormSectionBody(
                  children: [
                    DispatchStockRecordingPanel(
                      controller: _stockController!,
                      enabled: !isSaving,
                      mode: DispatchStockPanelMode.confirm,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.notes,
                icon: Icons.notes_outlined,
                child: AppFormSectionBody(
                  children: [
                    TextFormField(
                      controller: _notesController,
                      enabled: !isSaving,
                      style: AppFormFields.valueStyle(context),
                      decoration: AppFormFields.decoration(
                        context,
                        label: AppStrings.notes,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              AppFormSubmitBar(
                label: AppStrings.confirmDelivery,
                isLoading: isSaving,
                onPressed: isSaving ? null : () => _submit(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
