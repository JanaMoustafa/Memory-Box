import 'package:flutter/material.dart';
import '../models/memory.dart';

class MemoryPin extends StatefulWidget {
  final Memory memory;
  final VoidCallback onTap;

  const MemoryPin({
    Key? key,
    required this.memory,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MemoryPin> createState() => _MemoryPinState();
}

class _MemoryPinState extends State<MemoryPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tooltip (appears on hover)
              AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.memory.title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
              // Pin marker
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3B82F6),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildPinContent(),
              ),
              // Pin pointer
              Container(
                width: 4,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinContent() {
    if (widget.memory.emoji != null && widget.memory.emoji!.isNotEmpty) {
      return Center(
        child: DefaultTextStyle(
          style: const TextStyle(), // Reset to default
          child: Text(
            widget.memory.emoji!,
            style: const TextStyle(
              fontSize: 36,
              height: 1.0,
              letterSpacing: 0,
              // No fontFamily specified = uses system default
              // On iOS, this automatically renders iOS-style emojis
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (widget.memory.photoUrl != null) {
      return ClipOval(
        child: Image.network(
          widget.memory.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.location_on,
              color: Color(0xFF3B82F6),
              size: 24,
            );
          },
        ),
      );
    } else {
      return const Icon(
        Icons.location_on,
        color: Color(0xFF3B82F6),
        size: 24,
      );
    }
  }
}
