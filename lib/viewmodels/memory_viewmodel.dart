import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/memory.dart';
import '../repositories/memory_repository.dart';

/// ViewModel for managing memory-related business logic and state
/// Follows MVVM pattern - handles all business logic and notifies views of changes
class MemoryViewModel extends ChangeNotifier {
  final MemoryRepository _repository;
  StreamSubscription<List<Memory>>? _memoriesSubscription;

  MemoryViewModel(this._repository) {
    _initialize();
  }

  List<Memory> _memories = [];
  Memory? _selectedMemory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Memory> get memories => List.unmodifiable(_memories);
  Memory? get selectedMemory => _selectedMemory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize and listen to memory stream
  void _initialize() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Listen to memory stream for real-time updates
    _memoriesSubscription?.cancel();
    _memoriesSubscription = _repository.getAllMemoriesStream().listen(
      (memories) {
        _memories = memories;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load memories: ${error.toString()}';
        notifyListeners();
      },
    );
  }

  /// Reinitialize when user logs in/out
  void reinitialize() {
    _initialize();
  }

  /// Add a new memory
  /// The photoUrl should already be set in the memory object
  Future<void> addMemory(Memory memory) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.addMemory(memory);
      // The stream will automatically update, no need to reload
      _isLoading = false;
      _error = null;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to add memory: ${e.toString()}';
      // Show error to user
      rethrow;
    }
    notifyListeners();
  }

  /// Delete a memory
  Future<void> deleteMemory(String memoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteMemory(memoryId);
      if (success) {
        if (_selectedMemory?.id == memoryId) {
          _selectedMemory = null;
        }
        // The stream will automatically update
        _isLoading = false;
      } else {
        _isLoading = false;
        _error = 'Failed to delete memory';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete memory: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Toggle star status of a memory
  Future<void> toggleStar(String memoryId) async {
    try {
      final memory = await _repository.getMemoryById(memoryId);
      if (memory != null) {
        final updatedMemory = memory.copyWith(
          isStarred: !memory.isStarred,
        );
        final success = await _repository.updateMemory(updatedMemory);
        if (success) {
          // The stream will automatically update
          // Update selected memory if it's the one being modified
          if (_selectedMemory?.id == memoryId) {
            _selectedMemory = updatedMemory;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to toggle star: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Select a memory (for viewing details)
  void selectMemory(Memory memory) {
    _selectedMemory = memory;
    notifyListeners();
  }

  /// Clear selected memory
  void clearSelectedMemory() {
    _selectedMemory = null;
    notifyListeners();
  }

  /// Get starred memories stream
  Stream<List<Memory>> getStarredMemoriesStream() {
    return _repository.getStarredMemoriesStream();
  }

  @override
  void dispose() {
    _memoriesSubscription?.cancel();
    super.dispose();
  }
}
