import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';

class MemoryDetailScreen extends StatelessWidget {
  final Memory memory;
  final Function(String) onToggleStar;
  final Function(String) onDelete;

  const MemoryDetailScreen({
    Key? key,
    required this.memory,
    required this.onToggleStar,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, y').format(memory.timestamp);
    final formattedTime = DateFormat('h:mm a').format(memory.timestamp);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1F2937),
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Star Button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    memory.isStarred ? Icons.star : Icons.star_border,
                    color: memory.isStarred
                        ? const Color(0xFFEAB308)
                        : const Color(0xFF9CA3AF),
                    size: 24,
                  ),
                ),
                onPressed: () {
                  onToggleStar(memory.id);
                },
              ),
              // Delete Button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
                onPressed: () => _showDeleteConfirmationDialog(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: memory.photoUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          memory.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          },
                        ),
                        // Gradient overlay
                        Container(
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
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF9333EA),
                          ],
                        ),
                      ),
                      child: Center(
                        child: memory.emoji != null && memory.emoji!.isNotEmpty
                            ? Text(
                                memory.emoji!,
                                style: const TextStyle(fontSize: 80),
                              )
                            : const Icon(
                                Icons.location_on,
                                size: 80,
                                color: Colors.white,
                              ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji (if not in photo)
                      if ((memory.photoUrl == null) &&
                          memory.emoji != null &&
                          memory.emoji!.isNotEmpty)
                        Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
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
                              memory.emoji!,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date and Time
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: formattedDate,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: formattedTime,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'Coordinates',
                    value:
                        '${memory.coordinates.lat}, ${memory.coordinates.lng}',
                  ),
                  const SizedBox(height: 32),

                  // Note Section
                  if (memory.note != null && memory.note!.isNotEmpty) ...[
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        memory.note!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4B5563),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Memory?'),
          content: Text(
            'Are you sure you want to delete "${memory.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close detail screen
                onDelete(memory.id);
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
