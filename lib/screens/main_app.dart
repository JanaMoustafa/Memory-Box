import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/memory.dart';
import '../viewmodels/memory_viewmodel.dart';
import '../viewmodels/add_memory_viewmodel.dart';
import 'map_screen.dart';
import 'journal_feed.dart';
import 'starred_feed.dart';
import '../widgets/add_pin_sheet.dart';
import '../widgets/memory_viewer.dart';

/// MainApp - View layer in MVVM
/// This screen consumes MemoryViewModel and AddMemoryViewModel for business logic
class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  bool _showAddPinSheet = false;
  double _currentMapX = 50.0; // Current map center position (percentage)
  double _currentMapY = 50.0; // Current map center position (percentage)
  LatLng Function()?
      _getMapCenter; // Function to get current map center coordinates

  void _onMemoryTap(Memory memory) {
    final memoryViewModel =
        Provider.of<MemoryViewModel>(context, listen: false);
    memoryViewModel.selectMemory(memory);
  }

  void _onCloseMemoryViewer() {
    final memoryViewModel =
        Provider.of<MemoryViewModel>(context, listen: false);
    memoryViewModel.clearSelectedMemory();
  }

  void _onDeleteMemory(String memoryId) {
    final memoryViewModel =
        Provider.of<MemoryViewModel>(context, listen: false);
    memoryViewModel.deleteMemory(memoryId);
  }

  void _onToggleStar(String memoryId) {
    final memoryViewModel =
        Provider.of<MemoryViewModel>(context, listen: false);
    memoryViewModel.toggleStar(memoryId);
  }

  Future<void> _onAddMemory() async {
    final addMemoryViewModel =
        Provider.of<AddMemoryViewModel>(context, listen: false);

    // Create memory - photoUrl is already set in the viewmodel from image picker
    final memory = addMemoryViewModel.createMemory();

    if (memory != null) {
      final memoryViewModel =
          Provider.of<MemoryViewModel>(context, listen: false);
      try {
        await memoryViewModel.addMemory(memory);

        addMemoryViewModel.reset();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Memory saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Close the sheet after successful save
        if (mounted) {
          setState(() {
            _showAddPinSheet = false;
          });
        }
      } catch (e, stackTrace) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save memory: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        // Don't close the sheet if there's an error - rethrow to let caller know
        rethrow;
      }
    } else {
      // If memory creation failed (e.g., title empty), don't close sheet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a title for your memory'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryViewModel>(
      builder: (context, memoryViewModel, _) {
        return Scaffold(
          body: Stack(
            children: [
              // Main Content
              IndexedStack(
                index: _currentIndex,
                children: [
                  MapScreen(
                    memories: memoryViewModel.memories,
                    onMemoryTap: _onMemoryTap,
                    onMapPositionChanged: (x, y) {
                      _currentMapX = x;
                      _currentMapY = y;
                    },
                    onMapTap: (lat, lng) {
                      // When user taps on map, set actual GPS coordinates
                      final addMemoryViewModel =
                          Provider.of<AddMemoryViewModel>(context,
                              listen: false);
                      addMemoryViewModel.setActualCoordinates(lat, lng);
                    },
                    onGetMapCenter: (getCenter) {
                      // Store the function to get map center
                      _getMapCenter = getCenter;
                    },
                  ),
                  JournalFeed(
                    memories: memoryViewModel.memories,
                    onMemoryTap: _onMemoryTap,
                    onToggleStar: _onToggleStar,
                    onDelete: _onDeleteMemory,
                  ),
                  StarredFeed(
                    memories: memoryViewModel.memories,
                    onMemoryTap: _onMemoryTap,
                    onToggleStar: _onToggleStar,
                    onDelete: _onDeleteMemory,
                  ),
                ],
              ),

              // Bottom Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Add Pin Button (centered at top, elevated)
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -24),
                              child: GestureDetector(
                                onTap: () {
                                  // Set map position in AddMemoryViewModel when opening sheet
                                  final addMemoryViewModel =
                                      Provider.of<AddMemoryViewModel>(context,
                                          listen: false);

                                  // Get actual map center coordinates from MapController
                                  double lat, lng;
                                  if (_getMapCenter != null) {
                                    final center = _getMapCenter!();
                                    lat = center.latitude;
                                    lng = center.longitude;
                                  } else {
                                    // Fallback: Convert percentage position to coordinates
                                    lng = ((_currentMapX / 100.0) * 360.0 -
                                        180.0);
                                    lat =
                                        (90.0 - (_currentMapY / 100.0) * 180.0);
                                  }

                                  // Set both percentage position and actual coordinates
                                  addMemoryViewModel.setMapPosition(
                                      _currentMapX, _currentMapY);
                                  addMemoryViewModel.setActualCoordinates(
                                      lat, lng);

                                  setState(() {
                                    _showAddPinSheet = true;
                                  });
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF9333EA)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Navigation Items Row (Map, Journal, Starred)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _buildNavItem(
                                    icon: Icons.map,
                                    label: 'Map',
                                    index: 0,
                                  ),
                                ),
                                Expanded(
                                  child: _buildNavItem(
                                    icon: Icons.list,
                                    label: 'Journal',
                                    index: 1,
                                  ),
                                ),
                                Expanded(
                                  child: _buildNavItem(
                                    icon: Icons.star,
                                    label: 'Starred',
                                    index: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Memory Viewer Modal or Add Pin Sheet Modal
          bottomSheet: memoryViewModel.selectedMemory != null
              ? MemoryViewer(
                  memory: memoryViewModel.selectedMemory!,
                  onClose: _onCloseMemoryViewer,
                  onDelete: _onDeleteMemory,
                  onToggleStar: _onToggleStar,
                )
              : _showAddPinSheet
                  ? AddPinSheet(
                      onClose: () {
                        setState(() {
                          _showAddPinSheet = false;
                        });
                      },
                      onAddMemory: _onAddMemory,
                    )
                  : null,
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF9CA3AF),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
