import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_collection_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/collect_material_form_controller.dart';
import '../../widgets/job_work/collect_material_recording_panel.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class CollectMaterialScreen extends StatefulWidget {
  const CollectMaterialScreen({
    required this.jobWorkId,
    this.loadId,
    super.key,
  });

  final String jobWorkId;
  final String? loadId;

  @override
  State<CollectMaterialScreen> createState() => _CollectMaterialScreenState();
}

class _CollectMaterialScreenState extends State<CollectMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverAddressController = TextEditingController();
  final _receiverEmailController = TextEditingController();

  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverCnicController = TextEditingController();

  String? _vehicleType;
  CollectMaterialFormController? _stockController;
  DateTime _collectedAt = DateTime.now();
  bool _populatedReceiver = false;

  static const List<String> _vehicleTypes = [
    'Flatbed Truck',
    'Trailer',
    'Dumper',
    'Pickup',
    'Container Truck',
    'Tractor Trolley',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverEmailController.dispose();

    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverCnicController.dispose();

    _stockController?.dispose();
    super.dispose();
  }

  void _populateReceiverDetails(JobWorkCollectionFormState state) {
    if (_populatedReceiver) return;

    final customer = state.customer;
    if (customer != null) {
      _receiverNameController.text =
          customer.contactPersonName?.isNotEmpty == true
              ? customer.contactPersonName!
              : customer.name;
      _receiverPhoneController.text = customer.phone;
      _receiverEmailController.text = customer.email ?? '';

      final street = customer.shippingStreet ?? customer.billingStreet;
      final city = customer.shippingCity ?? customer.billingCity;
      final province = customer.shippingProvince ?? customer.billingProvince;
      final addressParts = [street, city, province]
          .where((p) => p != null && p.trim().isNotEmpty)
          .map((p) => p!.trim())
          .toList();
      _receiverAddressController.text = addressParts.join(', ');
    } else if (state.order != null) {
      _receiverNameController.text = state.order!.customerName;
    }
    _populatedReceiver = true;
  }

  void _ensureController(JobWorkCollectionFormState state) {
    if (_stockController != null || state.load == null) return;
    final remaining = JobWorkCollectionQuantityHelper.remainingLinesForLoad(
      state.load!,
      state.collections,
    );
    final totals = JobWorkCollectionQuantityHelper.loadTotals(
      state.load!,
      state.collections,
    );
    _stockController = CollectMaterialFormController.fromRemainingLines(
      remainingLines: remaining,
      orderTotals: totals,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _collectedAt = picked);
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = _stockController;
    if (controller == null || !controller.hasCollectQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.enterCollectPieces)),
      );
      return;
    }
    if (controller.hasExcessCollect) {
      return;
    }

    context.read<JobWorkCollectionFormBloc>().add(
          JobWorkCollectionFormSubmitted(
            collectedAt: _collectedAt,
            lineItems: controller.buildLineItems(),
            receiverName: _receiverNameController.text.trim(),
            receiverPhone: _receiverPhoneController.text.trim(),
            receiverAddress: _receiverAddressController.text.trim(),
            receiverEmail: _receiverEmailController.text.trim(),
            vehicleNumber: _vehicleNumberController.text.trim(),
            driverName: _driverNameController.text.trim(),
            driverPhone: _driverPhoneController.text.trim(),
            driverCnic: _driverCnicController.text.trim(),
            vehicleType: _vehicleType,
            notes: _notesController.text.trim(),
          ),
        );
  }

  List<JobWorkCollection> _extractRecentTransports(
      List<JobWorkCollection> collections) {
    final recent = <JobWorkCollection>[];
    final seen = <String>{};
    for (final col in collections) {
      final vNo = col.vehicleNumber?.trim() ?? '';
      final dName = col.driverName?.trim() ?? '';
      if (vNo.isNotEmpty || dName.isNotEmpty) {
        final key = '$vNo|$dName';
        if (!seen.contains(key)) {
          seen.add(key);
          recent.add(col);
        }
      }
    }
    return recent;
  }

  void _applyRecentTransport(JobWorkCollection col) {
    setState(() {
      if (col.vehicleNumber != null) {
        _vehicleNumberController.text = col.vehicleNumber!;
      }
      if (col.driverName != null) {
        _driverNameController.text = col.driverName!;
      }
      if (col.driverPhone != null) {
        _driverPhoneController.text = col.driverPhone!;
      }
      if (col.driverCnic != null) {
        _driverCnicController.text = col.driverCnic!;
      }
      if (col.vehicleType != null && _vehicleTypes.contains(col.vehicleType)) {
        _vehicleType = col.vehicleType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkCollectionFormBloc, JobWorkCollectionFormState>(
      listener: (context, state) {
        if (state.status == JobWorkCollectionFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.materialCollected)),
          );
          context.pop(true);
        }
        if (state.errorMessage != null &&
            state.status == JobWorkCollectionFormStatus.ready &&
            _stockController != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkCollectionFormStatus.loading ||
            state.status == JobWorkCollectionFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: const AppFormAppBarTitle(
                title: AppStrings.collectMaterial,
                subtitle: AppStrings.collectMaterial,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              title: const AppFormAppBarTitle(
                title: AppStrings.collectMaterial,
                subtitle: AppStrings.collectMaterial,
              ),
            ),
            body: Center(
              child: Text(
                state.errorMessage ?? AppStrings.jobWorkOrderNotFound,
              ),
            ),
          );
        }

        if (state.status == JobWorkCollectionFormStatus.failure &&
            _stockController == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.collectMaterial,
                subtitle: order.jobWorkNumber,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage ?? AppStrings.noRemainingStockToCollect,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        _ensureController(state);
        _populateReceiverDetails(state);
        final isSaving = state.status == JobWorkCollectionFormStatus.saving;
        final hasExcessCollect = _stockController?.hasExcessCollect == true;
        final load = state.load;
        final loadLabel = load == null
            ? null
            : (load.loadNumber.isEmpty
                ? '${AppStrings.load} #${load.loadSequence}'
                : load.loadNumber);
        final subtitle = loadLabel == null
            ? '${order.jobWorkNumber} · ${order.customerName}'
            : '${order.jobWorkNumber} · $loadLabel · ${order.customerName}';

        final recentTransports = _extractRecentTransports(state.collections);

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.collectMaterial,
              subtitle: subtitle,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.collectionDetails,
                  icon: Icons.event_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.collectionDate,
                        value: DateFormat.yMMMd().format(_collectedAt),
                        onTap: isSaving ? null : _pickDate,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.receiverDetails,
                  icon: Icons.person_outlined,
                  child: AppFormSectionBody(
                    children: [
                      TextFormField(
                        controller: _receiverNameController,
                        enabled: !isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: '${AppStrings.receiverName} *',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.enterReceiverName
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _receiverPhoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: '${AppStrings.receiverPhone} *',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.enterReceiverPhone
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _receiverAddressController,
                        enabled: !isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: '${AppStrings.deliveryAddress} *',
                        ),
                        maxLines: 2,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.enterDeliveryAddress
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _receiverEmailController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.emailAddress,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.receiverEmail,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          return emailRegex.hasMatch(value.trim())
                              ? null
                              : AppStrings.invalidEmail;
                        },
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.transportAndVehicleInfo,
                  icon: Icons.local_shipping_outlined,
                  child: AppFormSectionBody(
                    children: [
                      if (recentTransports.isNotEmpty) ...[
                        Text(
                          AppStrings.recentTransport,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: recentTransports.map((col) {
                            final label = [col.vehicleNumber, col.driverName]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(' - ');
                            return ActionChip(
                              avatar: const Icon(Icons.directions_bus, size: 16),
                              label: Text(label),
                              onPressed: isSaving
                                  ? null
                                  : () => _applyRecentTransport(col),
                            );
                          }).toList(),
                        ),
                        AppFormFields.gap,
                      ],
                      TextFormField(
                        controller: _vehicleNumberController,
                        enabled: !isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: '${AppStrings.vehicleNumber} *',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.enterVehicleNumber
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _driverNameController,
                        enabled: !isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: '${AppStrings.driverName} *',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.enterDriverName
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _driverPhoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: '${AppStrings.driverPhone} *',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.enterDriverPhone
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _driverCnicController,
                        enabled: !isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.driverCnic,
                        ),
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.vehicleType,
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (val) => setState(() => _vehicleType = val),
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.itemsToCollect,
                  icon: Icons.inventory_2_outlined,
                  child: AppFormSectionBody(
                    children: [
                      CollectMaterialRecordingPanel(
                        controller: _stockController!,
                        enabled: !isSaving,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: FilledButton(
                    onPressed: isSaving || hasExcessCollect
                        ? null
                        : () => _submit(context),
                    child: Text(
                      isSaving ? 'Saving…' : AppStrings.confirmCollectMaterial,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
