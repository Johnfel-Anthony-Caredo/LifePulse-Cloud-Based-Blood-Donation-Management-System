import 'package:admin_new/responsive.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/hospital.dart';
import '../../services/hospital_service.dart';
import '../shared/admin_page.dart';
import 'hospital_form_dialog.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({Key? key}) : super(key: key);

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  String _searchQuery = '';
  HospitalUrgency? _selectedFilter;
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hospitals = await HospitalService.listHospitals();
      if (!mounted) return;
      
      setState(() {
        _hospitals = hospitals;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Hospital> get _filteredHospitals {
    return _hospitals.where((hospital) {
      final matchesSearch = hospital.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          hospital.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == null || hospital.urgency == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _showAddEditDialog({Hospital? hospital}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => HospitalFormDialog(hospital: hospital),
    );

    if (result == true) {
      _loadHospitals(); // Reload data after successful create/edit
    }
  }

  Future<void> _deleteHospital(Hospital hospital) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: primaryColor),
            const SizedBox(width: 10),
            const Text('Delete Hospital'),
          ],
        ),
        content: Text('Are you sure you want to delete "${hospital.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: grayColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HospitalService.deleteHospital(hospital.id);
        _loadHospitals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hospital deleted successfully'),
              backgroundColor: tealAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting hospital: ${e.toString()}'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHospitals = _filteredHospitals;

    return AdminPage(
      title: 'Hospital Management',
      subtitle: 'Manage all ${_hospitals.length} hospitals across Mindanao.',
      action: ElevatedButton.icon(
        onPressed: () => _showAddEditDialog(),
        icon: Icon(Icons.add, size: 18),
        label: Text('Add Hospital'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      children: [
            // Search and Filter Bar
            AdminSectionCard(
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search hospitals...',
                        prefixIcon: Icon(Icons.search, color: grayColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Filter dropdown
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: lightGrayColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<HospitalUrgency?>(
                      value: _selectedFilter,
                      hint: Text('Filter by Status'),
                      underline: SizedBox(),
                      icon: Icon(Icons.filter_list, size: 20),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All Hospitals'),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.critical,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(0xFFDC143C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Critical'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.low,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Low Stock'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.medium,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFCD34D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.good,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: tealAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Well Stocked'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: defaultPadding),
            
            // Loading, Error, or Hospital Grid
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: primaryColor),
                      SizedBox(height: 16),
                      Text(
                        'Error loading hospitals',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadHospitals,
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Showing ${filteredHospitals.length} of ${_hospitals.length} hospitals',
                style: TextStyle(
                  fontSize: 14,
                  color: grayColor,
                ),
              ),
              SizedBox(height: defaultPadding),
              
              Responsive(
                mobile: HospitalGrid(
                  hospitals: filteredHospitals,
                  crossAxisCount: 1,
                  childAspectRatio: 0.85,
                  onEdit: _showAddEditDialog,
                  onDelete: _deleteHospital,
                ),
                tablet: HospitalGrid(
                  hospitals: filteredHospitals,
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  onEdit: _showAddEditDialog,
                  onDelete: _deleteHospital,
                ),
                desktop: HospitalGrid(
                  hospitals: filteredHospitals,
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  onEdit: _showAddEditDialog,
                  onDelete: _deleteHospital,
                ),
              ),
            ],
      ],
    );
  }
}

class HospitalGrid extends StatelessWidget {
  const HospitalGrid({
    Key? key,
    required this.hospitals,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.3,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final List<Hospital> hospitals;
  final int crossAxisCount;
  final double childAspectRatio;
  final Function({Hospital? hospital}) onEdit;
  final Function(Hospital hospital) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: hospitals.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => HospitalCard(
        hospital: hospitals[index],
        onEdit: () => onEdit(hospital: hospitals[index]),
        onDelete: () => onDelete(hospitals[index]),
      ),
    );
  }
}

class HospitalCard extends StatelessWidget {
  const HospitalCard({
    Key? key,
    required this.hospital,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final Hospital hospital;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _getUrgencyColor() {
    switch (hospital.urgency) {
      case HospitalUrgency.critical:
        return Color(0xFFDC143C);
      case HospitalUrgency.low:
        return orangeAccent;
      case HospitalUrgency.medium:
        return Color(0xFFFCD34D);
      case HospitalUrgency.good:
        return tealAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgencyColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hospital Image Header
          if (hospital.imageUrl != null && hospital.imageUrl!.isNotEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.network(
                    hospital.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.local_hospital, size: 48, color: Colors.grey.shade400),
                      );
                    },
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status badge on image
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            hospital.urgencyLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Icon(Icons.local_hospital, size: 48, color: primaryColor.withOpacity(0.3)),
              ),
            ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hospital name
                  Text(
                    hospital.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: grayColor),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.address.split(',').first,
                          style: TextStyle(
                            fontSize: 14,
                            color: grayColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  
                  // Phone
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: grayColor),
                      SizedBox(width: 4),
                      Text(
                        hospital.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: grayColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  
                  // Blood inventory summary
                  Text(
                    'Blood Inventory:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInventoryItem('Total', '${hospital.totalUnits}'),
                      _buildInventoryItem('Critical', '${hospital.criticalBloodTypes.length}'),
                      _buildInventoryItem('Low', '${hospital.lowBloodTypes.length}'),
                    ],
                  ),
                  
                  Spacer(flex: 1),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: Icon(Icons.edit, size: 16),
                          label: Text('Edit', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDelete,
                          icon: Icon(Icons.delete_outline, size: 16),
                          label: Text('Delete', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: grayColor,
          ),
        ),
      ],
    );
  }
}
