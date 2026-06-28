import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants.dart';
import '../../models/hospital.dart';
import '../../services/hospital_service.dart';
import '../shared/admin_page.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({Key? key}) : super(key: key);

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();
  HospitalUrgency? _selectedUrgencyFilter;
  Hospital? _selectedHospital;
  
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final hospitals = await HospitalService.listHospitals();
      
      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;
    final mapHeightRaw = size.height - (isMobile ? 170 : 190);
    final mapHeight = mapHeightRaw < 520 ? 520.0 : mapHeightRaw;
    
    // Apply urgency filter
    final filteredHospitals = _selectedUrgencyFilter == null
        ? _hospitals
        : _hospitals.where((h) => h.urgency == _selectedUrgencyFilter).toList();
    
    // Count hospitals by urgency
    final criticalCount = _hospitals.where((h) => h.urgency == HospitalUrgency.critical).length;
    final lowCount = _hospitals.where((h) => h.urgency == HospitalUrgency.low).length;
    final mediumCount = _hospitals.where((h) => h.urgency == HospitalUrgency.medium).length;
    final goodCount = _hospitals.where((h) => h.urgency == HospitalUrgency.good).length;

    return AdminPage(
      title: 'Hospital Map',
      subtitle: 'View hospital locations, stock urgency, and geographic coverage.',
      children: [
        SizedBox(
          height: mapHeight,
          child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading hospitals...', style: TextStyle(color: grayColor)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: primaryColor),
                      SizedBox(height: 16),
                      Text(
                        'Error loading hospitals',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(_errorMessage!, style: TextStyle(color: grayColor)),
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
                )
              : Padding(
        padding: EdgeInsets.all(isMobile ? 0.0 : 16.0),
        child: Stack(
          children: [
            // Map with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(7.8, 125.0), // Center of Mindanao
                  initialZoom: 7.5,
                  minZoom: 6.0,
                  maxZoom: 18.0,
                ),
                children: [
              // Satellite tile layer (default)
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.lifepulse.admin',
              ),
              // Hospital markers
              MarkerLayer(
                markers: filteredHospitals.map((hospital) {
                  return Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(hospital.latitude, hospital.longitude),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHospital = hospital;
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing/glowing effect for all hospitals (color-coded by urgency)
                          Center(
                            child: _PulsingCircle(color: _getUrgencyColor(hospital.urgency)),
                          ),
                          
                          // Main marker
                          Container(
                            decoration: BoxDecoration(
                              color: _getUrgencyColor(hospital.urgency),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
              ),
            ),
          
            // Filter Button (Top-Right)
            Positioned(
              top: isMobile ? 16 : 32,
              right: isMobile ? 16 : 32,
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showFilterDialog(),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          _selectedUrgencyFilter == null 
                              ? 'Filter' 
                              : _getUrgencyLabel(_selectedUrgencyFilter!),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
            // Statistics Panel (Hospital Overview) - Bottom-Right (Hidden on mobile)
            if (!isMobile)
              Positioned(
                bottom: 32,
                right: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Zoom Controls
                    _buildZoomButton(
                      icon: Icons.add,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom + 1,
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    _buildZoomButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom - 1,
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // Hospital Overview Panel
                    Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hospital Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildStatItem(Icons.business, 'Total Hospitals', _hospitals.length.toString(), Colors.blue),
                      SizedBox(height: 8),
                      _buildStatItem(Icons.warning, 'Critical', criticalCount.toString(), Color(0xFFDC143C)),
                      SizedBox(height: 8),
                      _buildStatItem(Icons.info, 'Low Stock', lowCount.toString(), orangeAccent),
                      SizedBox(height: 8),
                      _buildStatItem(Icons.check_circle, 'Medium', mediumCount.toString(), Color(0xFFFCD34D)),
                      SizedBox(height: 8),
                      _buildStatItem(Icons.verified, 'Well Stocked', goodCount.toString(), tealAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
            // Hospital Details (Bottom-Left Box) - Desktop only
            if (!isMobile && _selectedHospital != null)
              Positioned(
                bottom: 32,
                left: 32,
                child: Container(
                  width: 350,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedHospital!.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedHospital = null;
                            });
                          },
                          icon: Icon(Icons.close),
                          color: grayColor,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Urgency badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(_selectedHospital!.urgency).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getUrgencyColor(_selectedHospital!.urgency),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _selectedHospital!.urgencyLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getUrgencyColor(_selectedHospital!.urgency),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: grayColor),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedHospital!.address.split(',').first,
                            style: TextStyle(fontSize: 12, color: grayColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Phone
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: grayColor),
                        SizedBox(width: 4),
                        Text(
                          _selectedHospital!.phone,
                          style: TextStyle(fontSize: 12, color: grayColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Blood Inventory (${_selectedHospital!.totalUnits} units)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedHospital!.bloodInventory.entries.map((entry) {
                        final isCritical = _selectedHospital!.criticalBloodTypes.contains(entry.key);
                        final isLow = _selectedHospital!.lowBloodTypes.contains(entry.key);
                        Color color = isCritical 
                            ? Color(0xFFDC143C) 
                            : isLow 
                                ? orangeAccent 
                                : tealAccent;
                        
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${entry.value} units',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              ),
          
          // Mobile-only controls
          if (isMobile) ...[
            // Hamburger Menu (Top-Left)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.menu, color: primaryColor),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
            
            // Zoom Controls (Bottom-Right)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  _buildZoomButton(
                    icon: Icons.add,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        currentZoom + 1,
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildZoomButton(
                    icon: Icons.remove,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        currentZoom - 1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Mobile Hospital Details - Centered Dialog
          if (isMobile && _selectedHospital != null)
            _buildMobileHospitalDialog(_hospitals, criticalCount, lowCount, mediumCount, goodCount),
          ],
        ),
      ),
        ),
      ],
    );
  }
  
  Widget _buildMobileHospitalDialog(List<Hospital> hospitals, int criticalCount, int lowCount, int mediumCount, int goodCount) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedHospital!.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded),
                        color: Colors.grey[600],
                        onPressed: () {
                          setState(() => _selectedHospital = null);
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Urgency badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(_selectedHospital!.urgency).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getUrgencyColor(_selectedHospital!.urgency).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getUrgencyLabel(_selectedHospital!.urgency),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _getUrgencyColor(_selectedHospital!.urgency),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Hospital info
                  _buildMobileInfoRow(Icons.location_on_outlined, _selectedHospital!.address),
                  SizedBox(height: 8),
                  _buildMobileInfoRow(Icons.phone_outlined, _selectedHospital!.phone),
                  SizedBox(height: 8),
                  _buildMobileInfoRow(Icons.access_time_outlined, 'Operating Hours: Contact Hospital'),
                  SizedBox(height: 20),
                  
                  // Blood inventory
                  Text(
                    'Blood Inventory',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedHospital!.bloodInventory.entries.map((entry) {
                      final color = _getBloodTypeColor(entry.value);
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${entry.value}',
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMobileInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: grayColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            child: Icon(icon, color: primaryColor, size: 24),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(null, 'All Hospitals', Icons.business, Colors.blue),
              _buildFilterOption(HospitalUrgency.critical, 'Critical', Icons.warning, Color(0xFFDC143C)),
              _buildFilterOption(HospitalUrgency.low, 'Low Stock', Icons.info, orangeAccent),
              _buildFilterOption(HospitalUrgency.medium, 'Medium', Icons.check_circle, Color(0xFFFCD34D)),
              _buildFilterOption(HospitalUrgency.good, 'Well Stocked', Icons.verified, tealAccent),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(HospitalUrgency? urgency, String label, IconData icon, Color color) {
    final isSelected = _selectedUrgencyFilter == urgency;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUrgencyFilter = urgency;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            if (isSelected)
              Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(HospitalUrgency urgency) {
    switch (urgency) {
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

  String _getUrgencyLabel(HospitalUrgency urgency) {
    switch (urgency) {
      case HospitalUrgency.critical:
        return 'Critical';
      case HospitalUrgency.low:
        return 'Low Stock';
      case HospitalUrgency.medium:
        return 'Medium';
      case HospitalUrgency.good:
        return 'Well Stocked';
    }
  }
  
  Color _getBloodTypeColor(int units) {
    if (units < 10) {
      return Color(0xFFDC143C); // Critical - Red
    } else if (units < 20) {
      return orangeAccent; // Low - Orange
    } else {
      return tealAccent; // Good - Teal
    }
  }
}

// Pulsing animation widget for hospital markers
class _PulsingCircle extends StatefulWidget {
  final Color color;
  
  const _PulsingCircle({required this.color});
  
  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(1.0 - _animation.value),
              width: 2,
            ),
          ),
          transform: Matrix4.identity()..scale(1.0 + (_animation.value * 0.5)),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
