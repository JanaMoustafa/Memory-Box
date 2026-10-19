import 'package:cloud_firestore/cloud_firestore.dart';

class Memory {
  final String id;
  final String title;
  final String? note;
  final String? photoUrl;
  final String? emoji;
  final bool isStarred;
  final MemoryCoordinates coordinates;
  final DateTime timestamp;

  Memory({
    required this.id,
    required this.title,
    this.note,
    this.photoUrl,
    this.emoji,
    this.isStarred = false,
    required this.coordinates,
    required this.timestamp,
  });

  Memory copyWith({
    String? id,
    String? title,
    String? note,
    String? photoUrl,
    String? emoji,
    bool? isStarred,
    MemoryCoordinates? coordinates,
    DateTime? timestamp,
  }) {
    return Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      photoUrl: photoUrl ?? this.photoUrl,
      emoji: emoji ?? this.emoji,
      isStarred: isStarred ?? this.isStarred,
      coordinates: coordinates ?? this.coordinates,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert Memory to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'photoUrl': photoUrl,
      'emoji': emoji,
      'isStarred': isStarred,
      'coordinates': {
        'x': coordinates.x,
        'y': coordinates.y,
        'lat': coordinates.lat,
        'lng': coordinates.lng,
      },
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create Memory from Firestore document
  factory Memory.fromMap(Map<String, dynamic> map) {
    final coordinatesData = map['coordinates'] as Map<String, dynamic>?;
    final timestampData = map['timestamp'];

    return Memory(
      id: map['id'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      photoUrl: map['photoUrl'] as String?,
      emoji: map['emoji'] as String?,
      isStarred: map['isStarred'] as bool? ?? false,
      coordinates: coordinatesData != null
          ? MemoryCoordinates(
              x: (coordinatesData['x'] as num).toDouble(),
              y: (coordinatesData['y'] as num).toDouble(),
              lat: coordinatesData['lat'] as String,
              lng: coordinatesData['lng'] as String,
            )
          : MemoryCoordinates(
              x: 0,
              y: 0,
              lat: '0',
              lng: '0',
            ),
      timestamp: timestampData is Timestamp
          ? timestampData.toDate()
          : (timestampData as DateTime),
    );
  }
}

class MemoryCoordinates {
  final double x; // Percentage position on map for UI
  final double y; // Percentage position on map for UI
  final String lat; // Actual GPS latitude
  final String lng; // Actual GPS longitude

  MemoryCoordinates({
    required this.x,
    required this.y,
    required this.lat,
    required this.lng,
  });
}
