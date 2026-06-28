import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../constants.dart';

/// Interactive map component for selecting hospital location
/// Features: Tap to place marker, drag to move, displays coordinates
class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const LocationPickerMap({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? 
      LatLng(7.4479, 125.8078); // Default to Tagum City, Davao del Norte
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    widget.onLocationSelected(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Coordinates Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.place, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLocation == null
                      ? 'Tap on map to select location'
                      : 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Map
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? LatLng(7.4479, 125.8078),
                  initialZoom: 12.0,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                  onTap: _onMapTap,
                ),
                children: [
                  // Tile Layer (Satellite)
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.lifepulse.admin',
                    maxZoom: 19,
                  ),
                  
                  // Selected Location Marker
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 50,
                          height: 50,
                          point: _selectedLocation!,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              // Allow dragging marker
                              final currentZoom = _mapController.camera.zoom;
                              final bounds = _mapController.camera.visibleBounds;
                              final mapWidth = bounds.east - bounds.west;
                              final mapHeight = bounds.north - bounds.south;
                              
                              // Calculate new position based on drag
                              final newLat = _selectedLocation!.latitude - 
                                (details.delta.dy / MediaQuery.of(context).size.height) * mapHeight;
                              final newLng = _selectedLocation!.longitude + 
                                (details.delta.dx / MediaQuery.of(context).size.width) * mapWidth;
                              
                              setState(() {
                                _selectedLocation = LatLng(newLat, newLng);
                              });
                              widget.onLocationSelected(_selectedLocation!);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.local_hospital,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Instruction Overlay
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap to place marker • Drag marker to adjust',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Zoom Controls
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    // Zoom In
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom + 1).clamp(4.0, 18.0),
                        );
                      },
                      backgroundColor: Colors.white,
                      child: Icon(Icons.add, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    // Zoom Out
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom - 1).clamp(4.0, 18.0),
                        );
                      },
                      backgroundColor: Colors.white,
                      child: Icon(Icons.remove, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
