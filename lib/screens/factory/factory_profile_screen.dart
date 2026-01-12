import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/factory_service.dart';
import '../../models/factory_model.dart';
import '../../widgets/custom_dropdown.dart';

class FactoryProfileScreen extends StatefulWidget {
  const FactoryProfileScreen({super.key});

  @override
  State<FactoryProfileScreen> createState() => _FactoryProfileScreenState();
}

class _FactoryProfileScreenState extends State<FactoryProfileScreen> {
  final FactoryService _factoryService = FactoryService();
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _emergencyContactController;

  // Dropdown states need to be managed locally during edit
  String? _selectedFactoryType;
  String? _selectedStatus;
  String? _selectedBusinessType;
  String? _selectedWorkingDays;
  String? _selectedWorkingHours;
  String? _selectedShiftSystem;
  String? _selectedDefaultShift;
  String? _selectedCurrency;
  String? _selectedSalaryType;
  String? _selectedPaymentCycle;
  String? _selectedProductionUnit;
  String? _selectedQualityLevel;
  
  // Lists (Duplicated from CreateFactoryScreen - ideally a shared constant file)
  final List<String> _factoryTypes = ['Marble', 'Textile', 'Steel', 'Food Processing', 'Other'];
  final List<String> _statuses = ['Active', 'Suspended', 'Closed'];
  final List<String> _businessTypes = ['Sole Proprietor', 'Partnership', 'Private Ltd'];
  final List<String> _workingDaysList = ['Mon-Sat', 'Mon-Fri', 'Daily'];
  final List<String> _workingHoursList = ['8 Hours', '9 Hours', '10 Hours', '12 Hours', '24 Hours'];
  final List<String> _shiftSystems = ['Single Shift', 'Double Shift', 'Triple Shift'];
  final List<String> _defaultShifts = ['Morning', 'Evening', 'Night'];
  final List<String> _currencies = ['PKR', 'USD', 'EUR', 'GBP'];
  final List<String> _salaryTypes = ['Daily Wage', 'Monthly Salary'];
  final List<String> _paymentCycles = ['Weekly', 'Bi-weekly', 'Monthly'];
  final List<String> _qualityLevels = ['A', 'B', 'C'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _provinceController = TextEditingController();
    _countryController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _emergencyContactController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  // Helper to sync local state with stream data when NOT editing
  void _syncData(FactoryModel factory) {
    if (!_isEditing) {
      _nameController.text = factory.name;
      _streetController.text = factory.street;
      _cityController.text = factory.city;
      _provinceController.text = factory.province;
      _countryController.text = factory.country;
      _phoneController.text = factory.contactPhone;
      _emailController.text = factory.email;
      _emergencyContactController.text = factory.emergencyContact;

      _selectedFactoryType = factory.type;
      _selectedStatus = factory.status;
      _selectedBusinessType = factory.businessType;
      _selectedWorkingDays = factory.workingDays;
      _selectedWorkingHours = factory.workingHours;
      _selectedShiftSystem = factory.shiftSystem;
      _selectedDefaultShift = factory.defaultShift;
      _selectedCurrency = factory.currency;
      _selectedSalaryType = factory.salaryType;
      _selectedPaymentCycle = factory.paymentCycle;
      _selectedProductionUnit = factory.productionUnit;
      _selectedQualityLevel = factory.qualityLevel;
    }
  }

  Future<void> _updateFactory(FactoryModel current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedFactory = FactoryModel(
        id: current.id,
        ownerId: current.ownerId,
        logoUrl: current.logoUrl, // Not editing logo here for simplicity
        name: _nameController.text.trim(),
        type: _selectedFactoryType!,
        factoryCode: current.factoryCode, // Read only
        status: _selectedStatus!,
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        country: _countryController.text.trim(),
        gpsCoordinates: current.gpsCoordinates,
        contactPhone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        businessType: _selectedBusinessType!,
        workingDays: _selectedWorkingDays!,
        workingHours: _selectedWorkingHours!,
        shiftSystem: _selectedShiftSystem!,
        defaultShift: _selectedDefaultShift!,
        currency: _selectedCurrency!,
        salaryType: _selectedSalaryType!,
        paymentCycle: _selectedPaymentCycle!,
        productionUnit: _selectedProductionUnit!,
        qualityLevel: _selectedQualityLevel!,
        createdAt: current.createdAt,
      );

      await _factoryService.updateFactory(updatedFactory);
      
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factory updated!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Profile'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          )
        ],
      ),
      body: StreamBuilder<FactoryModel?>(
        stream: _factoryService.getFactoryStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final factory = snapshot.data;
          if (factory == null) return const Center(child: Text('No factory found'));

          _syncData(factory);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   if (factory.logoUrl != null)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(factory.logoUrl!),
                    )
                   else
                     const CircleAvatar(radius: 40, child: Icon(Icons.factory)),
                   const SizedBox(height: 24),

                   _buildSectionTitle('Basic Information'),
                   TextFormField(
                     controller: _nameController,
                     enabled: _isEditing,
                     decoration: const InputDecoration(labelText: 'Factory Name', border: OutlineInputBorder()),
                     validator: (v) => v!.isEmpty ? 'Required' : null,
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     initialValue: factory.factoryCode,
                     enabled: false,
                     decoration: const InputDecoration(labelText: 'Factory Code (Read-Only)', border: OutlineInputBorder(), filled: true),
                   ),
                   const SizedBox(height: 16),
                   
                   IgnorePointer(
                     ignoring: !_isEditing,
                     child: Opacity(
                       opacity: _isEditing ? 1.0 : 0.7,
                       child: Column(
                         children: [
                            CustomDropdown(
                              label: 'Factory Type',
                              value: _selectedFactoryType,
                              items: _factoryTypes,
                              onChanged: (v) => setState(() => _selectedFactoryType = v),
                            ),
                            const SizedBox(height: 16),
                            CustomDropdown(
                              label: 'Status',
                              value: _selectedStatus,
                              items: _statuses,
                              onChanged: (v) => setState(() => _selectedStatus = v),
                            ),
                         ],
                       ),
                     ),
                   ),

                   const SizedBox(height: 24),
                   _buildSectionTitle('Location'),
                   TextFormField(
                     controller: _streetController,
                     enabled: _isEditing,
                     decoration: const InputDecoration(labelText: 'Street', border: OutlineInputBorder()),
                   ),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(
                         child: TextFormField(
                           controller: _cityController,
                           enabled: _isEditing,
                           decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: TextFormField(
                           controller: _provinceController,
                           enabled: _isEditing,
                           decoration: const InputDecoration(labelText: 'Province', border: OutlineInputBorder()),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _countryController,
                     enabled: _isEditing,
                     decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                   ),

                   const SizedBox(height: 24),
                   _buildSectionTitle('Contact Details'),
                   TextFormField(
                     controller: _phoneController,
                     enabled: _isEditing,
                     decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _emailController,
                     enabled: _isEditing,
                     decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _emergencyContactController,
                     enabled: _isEditing,
                     decoration: const InputDecoration(labelText: 'Emergency Contact', border: OutlineInputBorder()),
                   ),

                   const SizedBox(height: 24),
                   _buildSectionTitle('Business & Operations'),
                   IgnorePointer(
                     ignoring: !_isEditing,
                     child: Opacity(
                       opacity: _isEditing ? 1.0 : 0.7,
                       child: Column(
                         children: [
                           CustomDropdown(
                             label: 'Business Type',
                             value: _selectedBusinessType,
                             items: _businessTypes,
                             onChanged: (v) => setState(() => _selectedBusinessType = v),
                           ),
                           const SizedBox(height: 16),
                           Row(
                             children: [
                               Expanded(
                                 child: CustomDropdown(
                                   label: 'Working Days',
                                   value: _selectedWorkingDays,
                                   items: _workingDaysList,
                                   onChanged: (v) => setState(() => _selectedWorkingDays = v),
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: CustomDropdown(
                                   label: 'Working Hours',
                                   value: _selectedWorkingHours,
                                   items: _workingHoursList,
                                   onChanged: (v) => setState(() => _selectedWorkingHours = v),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 16),
                           Row(
                             children: [
                               Expanded(
                                 child: CustomDropdown(
                                   label: 'Shift System',
                                   value: _selectedShiftSystem,
                                   items: _shiftSystems,
                                   onChanged: (v) => setState(() => _selectedShiftSystem = v),
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: CustomDropdown(
                                   label: 'Default Shift',
                                   value: _selectedDefaultShift,
                                   items: _defaultShifts,
                                   onChanged: (v) => setState(() => _selectedDefaultShift = v),
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),

                   const SizedBox(height: 24),
                   _buildSectionTitle('Finance & Production'),
                   IgnorePointer(
                     ignoring: !_isEditing,
                     child: Opacity(
                       opacity: _isEditing ? 1.0 : 0.7,
                       child: Column(
                         children: [
                           Row(
                             children: [
                               Expanded(
                                 child: CustomDropdown(
                                   label: 'Currency',
                                   value: _selectedCurrency,
                                   items: _currencies,
                                   onChanged: (v) => setState(() => _selectedCurrency = v),
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: CustomDropdown(
                                   label: 'Salary Type',
                                   value: _selectedSalaryType,
                                   items: _salaryTypes,
                                   onChanged: (v) => setState(() => _selectedSalaryType = v),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 16),
                           CustomDropdown(
                             label: 'Payment Cycle',
                             value: _selectedPaymentCycle,
                             items: _paymentCycles,
                             onChanged: (v) => setState(() => _selectedPaymentCycle = v),
                           ),
                           const SizedBox(height: 16),
                           CustomDropdown(
                              label: 'Production Unit',
                              value: _selectedProductionUnit, // Simplified logic
                              items: ['Sq ft', 'Tons', 'Meters', 'Yards', 'Pieces', 'Kg', 'Liters', 'Units'],
                              onChanged: (v) => setState(() => _selectedProductionUnit = v),
                            ),
                           const SizedBox(height: 16),
                           CustomDropdown(
                              label: 'Quality Level',
                              value: _selectedQualityLevel,
                              items: _qualityLevels,
                              onChanged: (v) => setState(() => _selectedQualityLevel = v),
                            ),
                         ],
                       ),
                     ),
                   ),
                    
                   if (_isEditing) ...[
                     const SizedBox(height: 32),
                     SizedBox(
                       width: double.infinity,
                       height: 50,
                       child: ElevatedButton(
                         onPressed: _isLoading ? null : () => _updateFactory(factory),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                         child: _isLoading ? const CircularProgressIndicator() : const Text('Update Factory', style: TextStyle(color: Colors.white)),
                       ),
                     )
                   ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        const Divider(thickness: 1, color: Colors.blueAccent),
        const SizedBox(height: 16),
      ],
    );
  }
}
