import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory.dart';

/// Service for Firestore memory operations
class FirestoreMemoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get stream of memories for a user
  Stream<List<Memory>> getMemoriesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('memories')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure the document ID is used as the memory ID
        data['id'] = doc.id;
        return Memory.fromMap(data);
      }).toList();
    });
  }

  /// Add a new memory
  /// Returns the document ID of the created memory
  Future<String> addMemory(String userId, Memory memory) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('memories')
          .doc();

      // Update memory with the document ID
      final memoryWithId = memory.copyWith(id: docRef.id);
      final memoryMap = memoryWithId.toMap();
      memoryMap['userId'] = userId; // Store userId for security rules

      await docRef.set(memoryMap);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add memory: ${e.toString()}');
    }
  }

  /// Update an existing memory
  Future<void> updateMemory(
      String userId, String memoryId, Memory memory) async {
    try {
      final memoryMap = memory.toMap();
      memoryMap['userId'] = userId; // Ensure userId is included

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('memories')
          .doc(memoryId)
          .update(memoryMap);
    } catch (e) {
      throw Exception('Failed to update memory: ${e.toString()}');
    }
  }

  /// Delete a memory
  Future<void> deleteMemory(String userId, String memoryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('memories')
          .doc(memoryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete memory: ${e.toString()}');
    }
  }

  /// Get a single memory by ID
  Future<Memory?> getMemoryById(String userId, String memoryId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('memories')
          .doc(memoryId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Ensure the document ID is used as the memory ID
        data['id'] = doc.id;
        return Memory.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get memory: ${e.toString()}');
    }
  }

  /// Get starred memories stream
  Stream<List<Memory>> getStarredMemoriesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('memories')
        .where('isStarred', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure the document ID is used as the memory ID
        data['id'] = doc.id;
        return Memory.fromMap(data);
      }).toList();
    });
  }
}
