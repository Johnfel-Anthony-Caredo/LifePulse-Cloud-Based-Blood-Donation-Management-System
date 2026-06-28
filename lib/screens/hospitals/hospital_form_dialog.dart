import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../constants.dart';
import '../../models/hospital.dart';
import '../../services/hospital_service.dart';
import 'components/location_picker_map.dart';

/// Material 3 Dialog for creating or editing a hospital
class HospitalFormDialog extends StatefulWidget {
  final Hospital? hospital; // null for create, non-null for edit

  const HospitalFormDialog({Key? key, this.hospital}) : super(key: key);

  @override
  State<HospitalFormDialog> createState() => _HospitalFormDialogState();
}

class _HospitalFormDialogState extends State<HospitalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _operatingHoursController = TextEditingController();

  LatLng? _selectedLocation;
  HospitalUrgency _selectedUrgency = HospitalUrgency.medium;
  bool _is24Hours = false;
  bool _isLoading = false;

  // Blood inventory controllers
  final Map<String, TextEditingController> _bloodInventoryControllers = {
    'A+': TextEditingController(text: '0'),
    'A-': TextEditingController(text: '0'),
    'B+': TextEditingController(text: '0'),
    'B-': TextEditingController(text: '0'),
    'O+': TextEditingController(text: '0'),
    'O-': TextEditingController(text: '0'),
    'AB+': TextEditingController(text: '0'),
    'AB-': TextEditingController(text: '0'),
  };

  @override
  void initState() {
    super.initState();
    
    // Listen to image URL changes to show preview
    _imageUrlController.addListener(() {
      setState(() {});
    });
    
    if (widget.hospital != null) {
      // Edit mode - populate fields
      _nameController.text = widget.hospital!.name;
      _addressController.text = widget.hospital!.address;
      _phoneController.text = widget.hospital!.phone;
      _emailController.text = widget.hospital!.email ?? '';
      _imageUrlController.text = widget.hospital!.imageUrl ?? '';
      _is24Hours = widget.hospital!.is24Hours;
      _operatingHoursController.text = widget.hospital!.operatingHours ?? '';
      _selectedLocation = LatLng(widget.hospital!.latitude, widget.hospital!.longitude);
      _selectedUrgency = widget.hospital!.urgency;

      // Populate blood inventory
      widget.hospital!.bloodInventory.forEach((bloodType, units) {
        _bloodInventoryControllers[bloodType]?.text = units.toString();
      });
    } else {
      // Create mode - default location to Tagum City
      _selectedLocation = LatLng(7.4479, 125.8078);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _imageUrlController.dispose();
    _operatingHoursController.dispose();
    _bloodInventoryControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveHospital() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build blood inventory map
      final bloodInventory = <String, int>{};
      _bloodInventoryControllers.forEach((bloodType, controller) {
        bloodInventory[bloodType] = int.tryParse(controller.text) ?? 0;
      });

      // Calculate urgency based on inventory
      final urgency = _calculateUrgency(bloodInventory);

      final hospital = Hospital(
        id: widget.hospital?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        is24Hours: _is24Hours,
        operatingHours: _operatingHoursController.text.trim().isEmpty ? null : _operatingHoursController.text.trim(),
        bloodInventory: bloodInventory,
        urgency: urgency,
      );

      if (widget.hospital == null) {
        // Create new hospital
        await HospitalService.createHospital(hospital);
      } else {
        // Update existing hospital
        await HospitalService.updateHospital(hospital);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        _showSuccessSnackBar(
          widget.hospital == null
              ? 'Hospital created successfully!'
              : 'Hospital updated successfully!'
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error saving hospital: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: tealAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Calculate hospital urgency based on blood inventory
  /// CRITICAL: total <= 50 OR any blood type <= 5
  /// LOW: total <= 150 OR any blood type <= 15
  /// MEDIUM: total <= 300
  /// WELL_STOCKED: total > 300
  HospitalUrgency _calculateUrgency(Map<String, int> inventory) {
    final total = inventory.values.fold(0, (sum, units) => sum + units);
    final hasCriticalBloodType = inventory.values.any((units) => units <= 5);
    final hasLowBloodType = inventory.values.any((units) => units > 5 && units <= 15);
    
    // Critical if total <= 50 OR any blood type <= 5
    if (total <= 50 || hasCriticalBloodType) {
      return HospitalUrgency.critical;
    }
    
    // Low if total <= 150 OR any blood type is low (6-15)
    if (total <= 150 || hasLowBloodType) {
      return HospitalUrgency.low;
    }
    
    // Medium if total <= 300
    if (total <= 300) {
      return HospitalUrgency.medium;
    }
    
    // Well stocked
    return HospitalUrgency.good;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.hospital != null;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 80,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 900, maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Material 3 Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_outlined : Icons.add_business_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Hospital' : 'Add New Hospital',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit ? 'Update hospital information' : 'Fill in the details below',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _nameController,
                        label: 'Hospital Name *',
                        hint: 'e.g., Davao del Norte Provincial Hospital',
                        icon: Icons.local_hospital,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address *',
                        hint: 'Full address with city and province',
                        icon: Icons.location_on,
                        maxLines: 2,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number *',
                              hint: '+63 XX XXX XXXX',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Phone is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'hospital@example.com',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Image URL with Preview
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'Hospital Image URL',
                        hint: 'https://example.com/hospital-image.jpg',
                        icon: Icons.image,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      
                      // Image Preview
                      if (_imageUrlController.text.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            _imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Invalid image URL',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      
                      // Operating Hours - Material 3 Style
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tealAccent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tealAccent.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              title: Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 18, color: tealAccent),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Open 24 Hours',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              value: _is24Hours,
                              onChanged: (value) {
                                setState(() => _is24Hours = value ?? false);
                              },
                              activeColor: tealAccent,
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            if (!_is24Hours) ...[
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _operatingHoursController,
                                label: 'Operating Hours',
                                hint: 'e.g., 8:00 AM - 5:00 PM',
                                icon: Icons.schedule_rounded,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Location Section
                      _buildSectionTitle('Location'),
                      const SizedBox(height: 12),
                      
                      LocationPickerMap(
                        initialLocation: _selectedLocation,
                        onLocationSelected: (location) {
                          setState(() => _selectedLocation = location);
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Blood Inventory Section (Urgency is auto-calculated)
                      _buildSectionTitle('Blood Inventory (Units)'),
                      const SizedBox(height: 12),
                      
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: isMobile ? 1.8 : 2.5,
                        children: _bloodInventoryControllers.entries.map((entry) {
                          return _buildBloodTypeField(entry.key, entry.value);
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Material 3 Footer Actions
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _saveHospital,
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEdit ? 'Save' : 'Create',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: grayColor,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: grayColor,
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.close_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isLoading ? null : _saveHospital,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEdit ? 'Save Changes' : 'Create Hospital',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildUrgencyChip(HospitalUrgency urgency, String label) {
    final isSelected = _selectedUrgency == urgency;
    Color chipColor;
    IconData chipIcon;
    
    switch (urgency) {
      case HospitalUrgency.critical:
        chipColor = primaryColor;
        chipIcon = Icons.warning_rounded;
        break;
      case HospitalUrgency.low:
        chipColor = orangeAccent;
        chipIcon = Icons.trending_down_rounded;
        break;
      case HospitalUrgency.medium:
        chipColor = const Color(0xFFFCD34D);
        chipIcon = Icons.trending_flat_rounded;
        break;
      case HospitalUrgency.good:
        chipColor = tealAccent;
        chipIcon = Icons.trending_up_rounded;
        break;
    }

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 18,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedUrgency = urgency);
      },
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withOpacity(0.3),
          width: isSelected ? 0 : 1.5,
        ),
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 1,
    );
  }

  Widget _buildBloodTypeField(String bloodType, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        color: primaryColor.withOpacity(0.03),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bloodType,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 32,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey.shade300),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Text(
            'units',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
