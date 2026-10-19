import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';

class MemoryViewer extends StatefulWidget {
  final Memory memory;
  final VoidCallback onClose;
  final Function(String) onDelete;
  final Function(String) onToggleStar;

  const MemoryViewer({
    Key? key,
    required this.memory,
    required this.onClose,
    required this.onDelete,
    required this.onToggleStar,
  }) : super(key: key);

  @override
  State<MemoryViewer> createState() => _MemoryViewerState();
}

class _MemoryViewerState extends State<MemoryViewer>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 1),
        end: _isExpanded ? Offset.zero : const Offset(0, 0.5),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMMM d, y').format(widget.memory.timestamp);

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping the sheet
          child: SlideTransition(
            position: _slideAnimation,
            child: DraggableScrollableSheet(
              initialChildSize: _isExpanded ? 1.0 : 0.5,
              minChildSize: 0.5,
              maxChildSize: 1.0,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      GestureDetector(
                        onTap: _toggleExpanded,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji Display
                            if (widget.memory.emoji != null &&
                                widget.memory.emoji!.isNotEmpty)
                              Container(
                                width: 56,
                                height: 56,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF9333EA)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.memory.emoji!,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.memory.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${widget.memory.coordinates.lat}, ${widget.memory.coordinates.lng}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Star Button
                                IconButton(
                                  icon: Icon(
                                    widget.memory.isStarred
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: widget.memory.isStarred
                                        ? const Color(0xFFEAB308)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                  onPressed: () {
                                    widget.onToggleStar(widget.memory.id);
                                  },
                                ),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(context);
                                  },
                                ),
                                // Close Button
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: widget.onClose,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Emoji Display (if not shown in header and no photo)
                              if ((widget.memory.emoji == null ||
                                      widget.memory.emoji!.isEmpty) &&
                                  widget.memory.photoUrl == null)
                                Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF9333EA)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                              // Photo
                              if (widget.memory.photoUrl != null) ...[
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
                                    child: Image.network(
                                      widget.memory.photoUrl!,
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          height: 300,
                                          color: const Color(0xFFF3F4F6),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],

                              // Note Section
                              if (widget.memory.note != null &&
                                  widget.memory.note!.isNotEmpty) ...[
                                const Text(
                                  'Note',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.memory.note!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF4B5563),
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Empty state
                              if (widget.memory.note == null &&
                                  widget.memory.photoUrl == null &&
                                  (widget.memory.emoji == null ||
                                      widget.memory.emoji!.isEmpty))
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Text(
                                      'No additional details for this memory',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Expand Indicator
                      if (!_isExpanded)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: TextButton(
                            onPressed: _toggleExpanded,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Full Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Memory?'),
          content: Text(
            'Are you sure you want to delete "${widget.memory.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete(widget.memory.id);
                widget.onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
