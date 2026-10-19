import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/memory.dart';
import '../widgets/memory_pin.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Memory> memories;
  final Function(Memory) onMemoryTap;
  final Function(double x, double y)? onMapPositionChanged;
  final Function(double lat, double lng)?
      onMapTap; // Callback for map tap with actual coordinates
  final Function(LatLng Function())?
      onGetMapCenter; // Callback to get current map center

  const MapScreen({
    Key? key,
    required this.memories,
    required this.onMemoryTap,
    this.onMapPositionChanged,
    this.onMapTap,
    this.onGetMapCenter,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  /// Get current map center coordinates
  LatLng getCurrentMapCenter() {
    return _mapController.camera.center;
  }

  @override
  void initState() {
    super.initState();
    // Track map position changes
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && widget.onMapPositionChanged != null) {
        _trackMapPosition();
      }
    });

    // Get user's current location and initialize map
    _getUserLocation();

    // Initial position setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMapPosition();
      _trackMapPosition();

      // Register the getMapCenter callback
      if (widget.onGetMapCenter != null) {
        widget.onGetMapCenter!(() => getCurrentMapCenter());
      }
    });
  }

  /// Get user's current GPS location
  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);

        // Update coordinates in AddMemoryViewModel with user's actual location
        if (widget.onMapTap != null) {
          widget.onMapTap!(position.latitude, position.longitude);
        }
      });

      // Center map on user location
      _mapController.move(_userLocation!, 12.0);
    } catch (e) {
      // Continue with default initialization if location fails
    }
  }

  void _initializeMapPosition() {
    // If user location is available, use it
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 12.0);
      return;
    }

    // If there are memories with valid coordinates, center on them
    final validMemories = widget.memories.where((memory) {
      final coords = _parseCoordinates(memory);
      return coords.latitude != 0.0 || coords.longitude != 0.0;
    }).toList();

    if (validMemories.isNotEmpty) {
      // Calculate center point of all memories
      double totalLat = 0;
      double totalLng = 0;
      int count = 0;

      for (var memory in validMemories) {
        final coords = _parseCoordinates(memory);
        if (coords.latitude != 0.0 || coords.longitude != 0.0) {
          totalLat += coords.latitude;
          totalLng += coords.longitude;
          count++;
        }
      }

      if (count > 0) {
        final centerLat = totalLat / count;
        final centerLng = totalLng / count;
        _mapController.move(LatLng(centerLat, centerLng), 3.0);
      }
    }
  }

  void _trackMapPosition() {
    if (widget.onMapPositionChanged != null) {
      final center = _mapController.camera.center;
      final lng = center.longitude;
      final lat = center.latitude;

      // Convert to percentage (0-100)
      final xPercent = ((lng + 180) / 360 * 100).clamp(0.0, 100.0);
      final yPercent = ((90 - lat) / 180 * 100).clamp(0.0, 100.0);

      widget.onMapPositionChanged!(xPercent, yPercent);
    }
  }

  LatLng _parseCoordinates(Memory memory) {
    final lat = double.tryParse(memory.coordinates.lat) ?? 0.0;
    final lng = double.tryParse(memory.coordinates.lng) ?? 0.0;
    return LatLng(lat, lng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          memories: widget.memories,
          onMemoryTap: widget.onMemoryTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Flutter Map with Mapbox tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ??
                  const LatLng(20, 0), // Use user location or default
              initialZoom: _userLocation != null
                  ? 12.0
                  : 2.0, // Zoom in if user location available
              minZoom: 1.0,
              maxZoom: 19.0,
              onTap: (tapPosition, point) {
                // Handle map tap - get actual GPS coordinates
                if (widget.onMapTap != null) {
                  widget.onMapTap!(point.latitude, point.longitude);
                }
              },
            ),
            children: [
              // OpenStreetMap TileLayer - Free and realistic map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 19,
                tileSize: 256,
                userAgentPackageName: 'com.memorybox.app',
                // Alternative realistic map styles (uncomment to use):
                // For a more colorful style:
                // urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                // For a dark theme:
                // urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              ),

              // Markers Layer
              MarkerLayer(
                markers: widget.memories.map((memory) {
                  final coordinates = _parseCoordinates(memory);
                  if (coordinates.latitude == 0.0 &&
                      coordinates.longitude == 0.0) {
                    return Marker(
                      point: coordinates,
                      width: 0,
                      height: 0,
                      child: const SizedBox.shrink(),
                    );
                  }

                  return Marker(
                    point: coordinates,
                    width: 56,
                    height: 66,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => widget.onMemoryTap(memory),
                      child: MemoryPin(
                        memory: memory,
                        onTap: () => widget.onMemoryTap(memory),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Memory Box',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _openSearch,
                            color: const Color(0xFF6B7280),
                          ),
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () =>
                                  Scaffold.of(context).openEndDrawer(),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF3B82F6),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Memory Box',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.description_outlined,
                      title: 'Terms and Conditions',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TermsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.security_outlined,
                      title: 'Privacy and Security',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showLogoutDialog(context, authViewModel);
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF6B7280),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : const Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authViewModel.logout();
                // Navigation will be handled by AppNavigator listening to auth state
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
