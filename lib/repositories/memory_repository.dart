import 'dart:async';
import '../models/memory.dart';
import '../services/firestore_memory_service.dart';
import '../services/firebase_auth_service.dart';

/// Repository for managing memory data operations
/// In MVVM, this handles all data access logic
class MemoryRepository {
  final FirestoreMemoryService _firestoreService;
  final FirebaseAuthService _authService;

  MemoryRepository(this._firestoreService, this._authService);

  /// Get current user ID
  String? get _userId => _authService.currentUser?.uid;

  /// Get stream of all memories for current user
  Stream<List<Memory>> getAllMemoriesStream() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }
    return _firestoreService.getMemoriesStream(userId);
  }

  /// Get all memories (legacy method for backward compatibility)
  Future<List<Memory>> getAllMemories() async {
    final userId = _userId;
    if (userId == null) {
      return [];
    }
    final stream = _firestoreService.getMemoriesStream(userId);
    return await stream.first;
  }

  /// Get memory by ID
  Future<Memory?> getMemoryById(String id) async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }
    try {
      return await _firestoreService.getMemoryById(userId, id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new memory
  /// The photoUrl should already be set in the memory object (from image picker)
  Future<void> addMemory(Memory memory) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User must be authenticated to add memories');
    }

    // Save memory directly - photoUrl is already set in the memory object
    try {
      await _firestoreService.addMemory(userId, memory);
    } catch (e) {
      throw Exception('Failed to save memory: ${e.toString()}');
    }
  }

  /// Delete a memory
  Future<bool> deleteMemory(String id) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }
    try {
      await _firestoreService.deleteMemory(userId, id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update a memory (for toggling star, etc.)
  Future<bool> updateMemory(Memory updatedMemory) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }
    try {
      await _firestoreService.updateMemory(
          userId, updatedMemory.id, updatedMemory);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get starred memories stream
  Stream<List<Memory>> getStarredMemoriesStream() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }
    return _firestoreService.getStarredMemoriesStream(userId);
  }

  /// Get starred memories (legacy method)
  Future<List<Memory>> getStarredMemories() async {
    final userId = _userId;
    if (userId == null) {
      return [];
    }
    final stream = _firestoreService.getStarredMemoriesStream(userId);
    return await stream.first;
  }
}
