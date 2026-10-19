import 'dart:io';
import 'package:camera/camera.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_memory_viewmodel.dart';
import '../screens/camera_screen.dart';
import 'web_camera_widget.dart';

/// AddPinSheet - View layer in MVVM
/// This widget consumes AddMemoryViewModel for form state management
class AddPinSheet extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function() onAddMemory;

  const AddPinSheet({
    Key? key,
    required this.onClose,
    required this.onAddMemory,
  }) : super(key: key);

  @override
  State<AddPinSheet> createState() => _AddPinSheetState();
}

class _AddPinSheetState extends State<AddPinSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _emojiController = TextEditingController();
  bool _showEmojiPicker = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Sync controllers with ViewModel
    final viewModel = Provider.of<AddMemoryViewModel>(context, listen: false);
    _titleController.text = viewModel.title;
    _noteController.text = viewModel.note;
    _emojiController.text = viewModel.emoji;

    // Listen to controller changes and update ViewModel
    _titleController.addListener(() {
      viewModel.setTitle(_titleController.text);
    });
    _noteController.addListener(() {
      viewModel.setNote(_noteController.text);
    });
    _emojiController.addListener(() {
      viewModel.setEmoji(_emojiController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _handlePhotoCapture() async {
    final viewModel = Provider.of<AddMemoryViewModel>(context, listen: false);
    try {
      if (kIsWeb) {
        // On web, use the custom web camera widget that directly accesses the camera
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WebCameraWidget(
              onImageCaptured: (imagePath, file) {
                viewModel.setCapturedImage(imagePath, file);
              },
            ),
          ),
        );
      } else {
        // On mobile, try image_picker first, fall back to camera screen if needed
        final shouldOpenCameraScreen = await viewModel.handlePhotoCapture();

        if (shouldOpenCameraScreen && mounted) {
          // Open camera screen and wait for result
          final imagePath = await Navigator.of(context).push<String>(
            MaterialPageRoute(
              builder: (context) => CameraScreen(
                onImageCaptured: (path) {
                  Navigator.of(context).pop(path);
                },
              ),
            ),
          );

          if (imagePath != null && mounted) {
            final viewModel =
                Provider.of<AddMemoryViewModel>(context, listen: false);
            final file = XFile(imagePath);
            viewModel.setCapturedImage(imagePath, file);
          }
        }
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        String errorMessage = 'Failed to open camera';
        if (kIsWeb) {
          errorMessage = 'Failed to access camera. Please ensure your browser has permission to use the camera.';
        } else {
          errorMessage = 'Failed to open camera: ${e.toString().replaceFirst('Exception: ', '')}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handlePhotoFromGallery() {
    final viewModel = Provider.of<AddMemoryViewModel>(context, listen: false);
    viewModel.handlePhotoFromGallery();
  }

  void _handleSkipPhoto() {
    final viewModel = Provider.of<AddMemoryViewModel>(context, listen: false);
    viewModel.skipPhoto();
  }

  Future<void> _handleSave() async {
    if (_isSaving) {
      return; // Prevent multiple simultaneous saves
    }

    final viewModel = Provider.of<AddMemoryViewModel>(context, listen: false);

    // Validate title before proceeding
    if (viewModel.title.isEmpty || viewModel.title.trim().isEmpty) {
      // Show error if title is empty
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a title for your memory'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Set saving state
    setState(() {
      _isSaving = true;
    });

    // Trigger the callback - photoUrl is already set in viewmodel from image picker
    try {
      await widget.onAddMemory().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Save operation timed out. Please check your connection and try again.');
        },
      );
    } catch (e) {
      // Error is already handled in _onAddMemory, but we catch here to prevent unhandled exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving memory: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Always reset saving state, even if there's an error or timeout
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddMemoryViewModel>(
      builder: (context, viewModel, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          viewModel.step == 'choose'
                              ? 'Capture Your Memory'
                              : 'Add Details',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viewModel.step == 'choose'
                          ? 'Choose how you want to document this moment'
                          : 'Give your memory a title and description',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (viewModel.step == 'choose')
                        _buildChooseStep()
                      else
                        _buildDetailsStep(viewModel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChooseStep() {
    return Consumer<AddMemoryViewModel>(
      builder: (context, viewModel, _) {
        // Use actual GPS coordinates if available, otherwise calculate from map position
        double lat, lng;
        if (viewModel.actualLat != null && viewModel.actualLng != null) {
          lat = viewModel.actualLat!;
          lng = viewModel.actualLng!;
        } else {
          // Convert percentage position to lat/lng for display
          lng = ((viewModel.mapX / 100.0) * 360.0 - 180.0);
          lat = (90.0 - (viewModel.mapY / 100.0) * 180.0);
        }
        final latStr = lat.toStringAsFixed(6);
        final lngStr = lng.toStringAsFixed(6);

        return Column(
          children: [
            // Current Location Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$latStr, $lngStr',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera Button
            _buildChoiceButton(
              icon: Icons.camera_alt,
              title: 'Capture Photo',
              subtitle: 'Capture this moment now',
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: _handlePhotoCapture,
            ),
            const SizedBox(height: 16),

            // Gallery Button
            _buildChoiceButton(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select an existing photo',
              gradientColors: const [Color(0xFF9333EA), Color(0xFF7C3AED)],
              onTap: _handlePhotoFromGallery,
            ),
            const SizedBox(height: 16),

            // Skip Photo Button
            _buildChoiceButton(
              icon: Icons.edit_note,
              title: 'Add Note Only',
              subtitle: 'Skip photo for now',
              gradientColors: const [Color(0xFF6B7280), Color(0xFF4B5563)],
              onTap: _handleSkipPhoto,
              isOutlined: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChoiceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOutlined ? Colors.grey.shade300 : Colors.grey.shade200,
            width: isOutlined ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isOutlined
                    ? null
                    : LinearGradient(
                        colors: gradientColors,
                      ),
                color: isOutlined ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(12),
                border: isOutlined
                    ? Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isOutlined ? Colors.grey.shade600 : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep(AddMemoryViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Photo Preview
        if (viewModel.photoUrl.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Display image from file picker or network URL
                  kIsWeb || viewModel.pickedFile == null
                      ? Image.network(
                          viewModel.photoUrl,
                          width: double.infinity,
                          height: 192,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 192,
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(viewModel.photoUrl),
                          width: double.infinity,
                          height: 192,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 192,
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        ),
                  Container(
                    height: 192,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Title Field
        const Text(
          'Memory Title *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g., My Graduation Day',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),

        // Emoji Field
        Row(
          children: [
            const Text(
              'Emoji (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.emoji_emotions),
              onPressed: () {
                setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                });
              },
              tooltip: 'Add emoji',
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emojiController,
          readOnly: true,
          maxLength: 2,
          decoration: InputDecoration(
            hintText: 'Tap emoji icon to add',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
            helperText: 'Choose an emoji to represent this memory on the map',
            helperMaxLines: 2,
            suffixIcon: _emojiController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _emojiController.clear();
                      final viewModel = Provider.of<AddMemoryViewModel>(context,
                          listen: false);
                      viewModel.setEmoji('');
                    },
                  )
                : null,
          ),
        ),
        // Emoji Picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _emojiController.text = emoji.emoji;
                final viewModel =
                    Provider.of<AddMemoryViewModel>(context, listen: false);
                viewModel.setEmoji(emoji.emoji);
                setState(() {
                  _showEmojiPicker = false;
                });
              },
              config: const Config(
                height: 256,
                checkPlatformCompatibility: true,
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Note Field
        const Text(
          'Note (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write about this special moment...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  final viewModel =
                      Provider.of<AddMemoryViewModel>(context, listen: false);
                  viewModel.goBackToChoose();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _isSaving
                        ? LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Save Memory',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
