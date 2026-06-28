
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/hospital.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/hospital_service.dart';
import '../auth/login_screen.dart';
import 'components/filter_fab.dart';
import 'components/menu_fab.dart';
import 'components/zoom_controls.dart';
import 'components/legend_card.dart';
import 'components/hospital_bottom_sheet.dart';

/// Map style options for tile layers
/// Includes satellite imagery, 3D buildings, terrain, and various artistic styles
enum MapStyle {
  satellite,      // Esri Satellite imagery (DEFAULT)
  mapbox3D,       // Mapbox Streets with 3D buildings
  mapboxOutdoors, // Mapbox Outdoors with 3D terrain
  mapboxSatellite,// Mapbox Satellite with labels
  light,          // CartoDB Positron (clean medical look)
  dark,           // CartoDB Dark Voyager (dark mode)
  standard,       // OpenStreetMap
  terrain,        // Stamen Terrain (topographic)
}

class DonorMapScreenWeb extends StatefulWidget {
  const DonorMapScreenWeb({Key? key}) : super(key: key);

  @override
  State<DonorMapScreenWeb> createState() => _DonorMapScreenWebState();
}

class _DonorMapScreenWebState extends State<DonorMapScreenWeb> {
  final MapController _mapController = MapController();
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  HospitalUrgency? _selectedUrgency;
  String? _selectedBloodType;
  MapStyle _selectedMapStyle = MapStyle.satellite; // Default to satellite view
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final hospitals = await HospitalService.listHospitals();
      setState(() {
        _hospitals = hospitals;
        _isLoading = false;
      });
    } catch (e) {
      safePrint('Error loading hospitals: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load hospitals: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: primaryColor),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          // Still navigate to login screen even if sign out fails
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  // Helper to convert hex color to Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Get tile layer URL based on selected style
  String _getTileUrl() {
    switch (_selectedMapStyle) {
      case MapStyle.satellite:
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case MapStyle.mapbox3D:
        return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
      case MapStyle.mapboxOutdoors:
        return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
      case MapStyle.mapboxSatellite:
        return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
      case MapStyle.light:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'; // CARTO Light
      case MapStyle.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'; // CARTO Dark
      case MapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'; // OpenStreetMap
      case MapStyle.terrain:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png'; // OpenTopoMap
    }
  }

  // Get subdomains for tile providers that use them
  List<String> _getTileSubdomains() {
    switch (_selectedMapStyle) {
      case MapStyle.light:
      case MapStyle.dark:
        return ['a', 'b', 'c']; // CARTO uses subdomains
      case MapStyle.terrain:
        return ['a', 'b', 'c']; // OpenTopoMap uses subdomains
      case MapStyle.satellite:
      case MapStyle.mapbox3D:
      case MapStyle.mapboxOutdoors:
      case MapStyle.mapboxSatellite:
      case MapStyle.standard:
        return [];
    }
  }

  // Get map style display name
  String _getMapStyleName(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return 'Satellite';
      case MapStyle.mapbox3D:
        return '3D Streets';
      case MapStyle.mapboxOutdoors:
        return '3D Outdoors';
      case MapStyle.mapboxSatellite:
        return 'Satellite+';
      case MapStyle.light:
        return 'Light';
      case MapStyle.dark:
        return 'Dark';
      case MapStyle.standard:
        return 'Standard';
      case MapStyle.terrain:
        return 'Terrain';
    }
  }

  // Get map style icon
  IconData _getMapStyleIcon(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return Icons.satellite_alt;
      case MapStyle.mapbox3D:
        return Icons.apartment; // 3D building icon
      case MapStyle.mapboxOutdoors:
        return Icons.landscape; // Mountain/outdoor icon
      case MapStyle.mapboxSatellite:
        return Icons.public; // Globe icon
      case MapStyle.light:
        return Icons.light_mode;
      case MapStyle.dark:
        return Icons.dark_mode;
      case MapStyle.standard:
        return Icons.map;
      case MapStyle.terrain:
        return Icons.terrain;
    }
  }

  List<Hospital> get _filteredHospitals {
    return _hospitals.where((hospital) {
      // Filter by urgency
      if (_selectedUrgency != null && hospital.urgency != _selectedUrgency) {
        return false;
      }

      // Filter by blood type (show hospitals with low stock of selected type)
      if (_selectedBloodType != null) {
        final stock = hospital.bloodInventory[_selectedBloodType!] ?? 0;
        if (stock >= 20) return false; // Only show if stock is low
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading hospitals...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: grayColor,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
        children: [
          // Flutter Map (Web)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(7.4479, 125.8078), // Tagum City, Davao del Norte
              initialZoom: 9.5, // Focused on Davao del Norte (zoomed out a bit)
              minZoom: 4.0,
              maxZoom: 18.0,
              onTap: (_, __) {
                // Deselect hospital when tapping on map
                setState(() => _selectedHospital = null);
              },
            ),
            children: [
              // Dynamic tile layer based on selected style
              TileLayer(
                urlTemplate: _getTileUrl(),
                subdomains: _getTileSubdomains(),
                userAgentPackageName: 'com.lifepulse.admin',
                maxZoom: 19,
              ),
              
              // Hospital markers
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Overlay UI Elements
          _buildOverlayUI(isMobile),

          // Hospital Details Bottom Sheet (Mobile)
          if (isMobile && _selectedHospital != null)
            HospitalBottomSheet(
              hospital: _selectedHospital!,
              onClose: () => setState(() => _selectedHospital = null),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final hospitals = _filteredHospitals;
    
    return hospitals.map((hospital) {
      final isSelected = _selectedHospital?.id == hospital.id;
      final markerColor = _hexToColor(hospital.urgencyColor);
      
      return Marker(
        width: isSelected ? 60 : 50,
        height: isSelected ? 60 : 50,
        point: LatLng(hospital.latitude, hospital.longitude),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedHospital = hospital;
            });
            
            // Animate to hospital location
            _mapController.move(
              LatLng(hospital.latitude, hospital.longitude),
              _mapController.camera.zoom > 13 ? _mapController.camera.zoom : 13.0,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                // Pulsing effect for critical hospitals
                if (hospital.urgency == HospitalUrgency.critical)
                  _PulsingCircle(color: markerColor),
                
                // Main marker
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerColor,
                      width: isSelected ? 4 : 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withOpacity(0.4),
                        blurRadius: isSelected ? 12 : 8,
                        spreadRadius: isSelected ? 3 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_hospital,
                      color: markerColor,
                      size: isSelected ? 28 : 24,
                    ),
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: tealAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildOverlayUI(bool isMobile) {
    return Stack(
      children: [
        // Legend Card (Top-Left - No spacing)
        Positioned(
          top: 16,
          left: 16,
          child: LegendCard(isWebVersion: !isMobile), // Pass false for mobile
        ),

        // Filter FAB (Top-Right - No spacing)
        Positioned(
          top: 16,
          right: 16,
          child: FilterFAB(
            selectedUrgency: _selectedUrgency,
            selectedBloodType: _selectedBloodType,
            onUrgencyChanged: (urgency) {
              setState(() {
                _selectedUrgency = urgency;
                _selectedHospital = null; // Clear selection on filter change
              });
            },
            onBloodTypeChanged: (bloodType) {
              setState(() {
                _selectedBloodType = bloodType;
                _selectedHospital = null; // Clear selection on filter change
              });
            },
          ),
        ),

        // Menu FAB (Bottom-Left - Closer to bottom)
        Positioned(
          bottom: 16,
          left: 16,
          child: MenuFAB(onLogout: _handleSignOut),
        ),

        // Map Style FAB (Above Zoom Controls)
        Positioned(
          bottom: 136,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'map_style_fab',
            onPressed: _showMapStylePicker,
            backgroundColor: Colors.white,
            child: Icon(
              _getMapStyleIcon(_selectedMapStyle),
              color: primaryColor,
            ),
          ),
        ),

        // Zoom Controls (Bottom-Right - Closer to bottom)
        Positioned(
          bottom: 16,
          right: 16,
          child: ZoomControls(
            onZoomIn: () => _zoomMap(1),
            onZoomOut: () => _zoomMap(-1),
          ),
        ),

        // Desktop info card (when hospital selected)
        if (!isMobile && _selectedHospital != null)
          Positioned(
            top: 16,
            right: 80,
            child: _buildDesktopInfoCard(),
          ),
      ],
    );
  }

  Widget _buildDesktopInfoCard() {
    final hospital = _selectedHospital!;
    final cardColor = _hexToColor(hospital.urgencyColor);
    
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedHospital = null),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Hospital image
            if (hospital.imageUrl != null && hospital.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  hospital.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: lightGrayColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_hospital,
                          size: 48,
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: lightGrayColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: primaryColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            
            // Urgency badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardColor, width: 1.5),
              ),
              child: Text(
                hospital.urgencyLabel,
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Info rows
            _buildInfoRow(Icons.location_on, hospital.address),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, hospital.phone),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Contact for Hours',
            ),
            const SizedBox(height: 16),
            
            // Total units
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Blood Units',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hospital.totalUnits}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Critical warning if needed
            if (hospital.criticalBloodTypes.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Critical: ${hospital.criticalBloodTypes.join(", ")}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: grayColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _zoomMap(int direction) {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom + direction).clamp(4.0, 18.0);
    
    _mapController.move(
      _mapController.camera.center,
      newZoom,
    );
  }

  void _showMapStylePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Style',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Map style options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: MapStyle.values.map((style) {
                final isSelected = _selectedMapStyle == style;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMapStyleIcon(style),
                        size: 18,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(_getMapStyleName(style)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedMapStyle = style);
                    Navigator.pop(context);
                  },
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey[100],
                  elevation: isSelected ? 4 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Pulsing animation widget for critical hospitals
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
