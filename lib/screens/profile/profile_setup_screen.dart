import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      } 

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.country}';
        _addressController.text = address;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final user = authProvider.user;
      if (user == null) return;

      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        cnic: _cnicController.text.trim(),
        address: _addressController.text.trim(),
      );

      final success = await authProvider.saveProfile(profile);

      if (success) {
        // Navigation will be handled by AuthWrapper or we can push directly if needed
        // But since auth state (hasProfile) changes, AuthWrapper might react.
        // However, Provider listeners usually trigger rebuilds.
        // Let's rely on AuthWrapper's reactive nature or manual push if wrapper isn't sufficient yet.
        // For now, let's assume AuthWrapper rebuilds. If not, we can force navigation.
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
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
               const Icon(
                  Icons.person_pin,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
              Text(
                'Personal Details',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
              ),
              const SizedBox(height: 32),
              
              // Email (Read Only)
              TextFormField(
                initialValue: user?.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // CNIC
              TextFormField(
                controller: _cnicController,
                decoration: InputDecoration(
                  labelText: 'CNIC *',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Address with Fetch Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address *',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _isGettingLocation ? null : _fetchLocation,
                      icon: _isGettingLocation 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Icons.my_location, color: Colors.blueAccent),
                      tooltip: 'Get Current Location',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
