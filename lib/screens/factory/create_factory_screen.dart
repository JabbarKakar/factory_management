import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../services/factory_service.dart';
import '../../models/factory_model.dart';
import '../../widgets/custom_dropdown.dart';

class CreateFactoryScreen extends StatefulWidget {
  const CreateFactoryScreen({super.key});

  @override
  State<CreateFactoryScreen> createState() => _CreateFactoryScreenState();
}

class _CreateFactoryScreenState extends State<CreateFactoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final FactoryService _factoryService = FactoryService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _countryController = TextEditingController();
  final _gpsController = TextEditingController(); // Optional
  final _contactPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // Dropdown Values
  String? _selectedFactoryType;
  String? _selectedStatus = 'Active';
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

  File? _logoFile;
  String _generatedFactoryCode = '';
  bool _isLoading = false;

  // Dropdown Options
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

  // Dynamic Options
  List<String> get _productionUnits {
    if (_selectedFactoryType == 'Marble') {
      return ['Sq ft', 'Tons'];
    } else if (_selectedFactoryType == 'Textile') {
      return ['Meters', 'Yards', 'Pieces'];
    } else if (_selectedFactoryType == 'Steel') {
      return ['Tons', 'Kg'];
    } else if (_selectedFactoryType == 'Food Processing') {
      return ['Kg', 'Liters', 'Units'];
    } else {
      return ['Units', 'Kg', 'Tons'];
    }
  }

  @override
  void initState() {
    super.initState();
    _generatedFactoryCode = _factoryService.generateFactoryCode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    if (userProfile != null) {
      setState(() {
        _contactPhoneController.text = userProfile.phoneNumber;
        _emailController.text = userProfile.email;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    _gpsController.dispose();
    _contactPhoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _logoFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking logo: $e');
    }
  }

  Future<void> _submitFactory() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;

        if (user == null) throw Exception('User not logged in');

        final factoryModel = FactoryModel(
          id: const Uuid().v4(),
          ownerId: user.uid,
          name: _nameController.text.trim(),
          type: _selectedFactoryType!,
          factoryCode: _generatedFactoryCode,
          status: _selectedStatus!,
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim(),
          country: _countryController.text.trim(),
          // gpsCoordinates: ... (Parse logic if needed, keeping simple for now)
          contactPhone: _contactPhoneController.text.trim(),
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
          createdAt: DateTime.now(),
        );

        await _factoryService.createFactory(factoryModel, _logoFile);
        
        await authProvider.refreshFactoryStatus(); // Need to implement this in AuthProvider

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Factory Created Successfully!'), backgroundColor: Colors.green),
          );
          // Navigation handled by AuthWrapper via Provider changes
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Factory'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _logoFile != null ? FileImage(_logoFile!) : null,
                    child: _logoFile == null
                        ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Add Factory Logo (Optional)', style: TextStyle(color: Colors.grey))),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Basic Information'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Factory Name', Icons.factory),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'Factory Type',
                value: _selectedFactoryType,
                items: _factoryTypes,
                prefixIcon: Icons.category,
                onChanged: (val) {
                  setState(() {
                    _selectedFactoryType = val;
                    _selectedProductionUnit = null; // Reset dependent dropdown
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // Factory Code (Read Only)
              TextFormField(
                initialValue: _generatedFactoryCode,
                readOnly: true,
                decoration: _inputDecoration('Factory Code', Icons.qr_code).copyWith(
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
               CustomDropdown(
                label: 'Status',
                value: _selectedStatus,
                items: _statuses,
                prefixIcon: Icons.info,
                onChanged: (val) => setState(() => _selectedStatus = val),
                 validator: (v) => v == null ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Location'),
              TextFormField(
                controller: _streetController,
                decoration: _inputDecoration('Street / Area', Icons.location_on),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration('City', Icons.location_city),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                        controller: _provinceController,
                        decoration: _inputDecoration('Province', Icons.map),
                         validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _countryController,
                  decoration: _inputDecoration('Country', Icons.flag),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                  controller: _gpsController,
                  decoration: _inputDecoration('GPS Coordinates (Optional)', Icons.gps_fixed),
              ),

              const SizedBox(height: 24),
               _buildSectionTitle('Contact Details'),
               TextFormField(
                  controller: _contactPhoneController,
                  decoration: _inputDecoration('Contact Phone', Icons.phone),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email Address', Icons.email),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                  controller: _emergencyContactController,
                  decoration: _inputDecoration('Emergency Contact', Icons.contact_emergency),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Business & Operations'),
               CustomDropdown(
                label: 'Business Type',
                value: _selectedBusinessType,
                items: _businessTypes,
                prefixIcon: Icons.business,
                onChanged: (val) => setState(() => _selectedBusinessType = val),
                 validator: (v) => v == null ? 'Required' : null,
              ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(
                     child: CustomDropdown(
                      label: 'Working Days',
                      value: _selectedWorkingDays,
                      items: _workingDaysList,
                      prefixIcon: Icons.calendar_today,
                      onChanged: (val) => setState(() => _selectedWorkingDays = val),
                       validator: (v) => v == null ? 'Required' : null,
                                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: CustomDropdown(
                      label: 'Working Hours',
                      value: _selectedWorkingHours,
                      items: _workingHoursList,
                      prefixIcon: Icons.access_time,
                      onChanged: (val) => setState(() => _selectedWorkingHours = val),
                       validator: (v) => v == null ? 'Required' : null,
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
                      prefixIcon: Icons.schedule,
                      onChanged: (val) => setState(() => _selectedShiftSystem = val),
                       validator: (v) => v == null ? 'Required' : null,
                                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: CustomDropdown(
                      label: 'Default Shift',
                      value: _selectedDefaultShift,
                      items: _defaultShifts,
                      prefixIcon: Icons.light_mode,
                      onChanged: (val) => setState(() => _selectedDefaultShift = val),
                       validator: (v) => v == null ? 'Required' : null,
                                     ),
                   ),
                 ],
               ),

              const SizedBox(height: 24),
               _buildSectionTitle('Finance & Production'),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown(
                        label: 'Currency',
                        value: _selectedCurrency,
                        items: _currencies,
                        prefixIcon: Icons.attach_money,
                        onChanged: (val) => setState(() => _selectedCurrency = val),
                        validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                   const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown(
                        label: 'Salary Type',
                        value: _selectedSalaryType,
                        items: _salaryTypes,
                        prefixIcon: Icons.payments,
                        onChanged: (val) => setState(() => _selectedSalaryType = val),
                        validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                  label: 'Payment Cycle',
                  value: _selectedPaymentCycle,
                  items: _paymentCycles,
                  prefixIcon: Icons.update,
                  onChanged: (val) => setState(() => _selectedPaymentCycle = val),
                  validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
               CustomDropdown(
                  label: 'Production Unit',
                  value: _selectedProductionUnit,
                  items: _productionUnits, // Dynamic based on Factory Type
                  prefixIcon: Icons.scale,
                  onChanged: (val) => setState(() => _selectedProductionUnit = val),
                  validator: (v) => v == null ? 'Required' : null,
              ),
               const SizedBox(height: 16),
               CustomDropdown(
                  label: 'Quality Level',
                  value: _selectedQualityLevel,
                  items: _qualityLevels,
                  prefixIcon: Icons.grade,
                  onChanged: (val) => setState(() => _selectedQualityLevel = val),
                  validator: (v) => v == null ? 'Required' : null,
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFactory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Factory',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
