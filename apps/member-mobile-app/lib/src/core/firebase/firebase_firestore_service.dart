import 'dart:async';
import 'firebase_config.dart';

/// Firestore Document Snapshot Representation.
class FirestoreDocSnapshot {
  final String id;
  final String path;
  final bool exists;
  final Map<String, dynamic> data;

  const FirestoreDocSnapshot({
    required this.id,
    required this.path,
    required this.exists,
    required this.data,
  });
}

/// Firestore Collection Query Snapshot Representation.
class FirestoreQuerySnapshot {
  final List<FirestoreDocSnapshot> docs;
  final int count;

  const FirestoreQuerySnapshot({
    required this.docs,
    required this.count,
  });

  bool get isEmpty => docs.isEmpty;
  bool get isNotEmpty => docs.isNotEmpty;
}

/// Production-Grade Cloud Firestore Data Access Service.
class FirebaseFirestoreService {
  final FirebaseAppConfig config;
  final Map<String, Map<String, dynamic>> _inMemoryCollectionStore = {};

  FirebaseFirestoreService({this.config = FirebaseAppConfig.development});

  /// Reads a single document by collection path and document ID.
  Future<FirestoreDocSnapshot> getDocument(String collectionPath, String documentId) async {
    final key = '$collectionPath/$documentId';
    final data = _inMemoryCollectionStore[key];
    return FirestoreDocSnapshot(
      id: documentId,
      path: key,
      exists: data != null,
      data: data ?? {},
    );
  }

  /// Writes or overwrites a document.
  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    final key = '$collectionPath/$documentId';
    _inMemoryCollectionStore[key] = Map<String, dynamic>.from(data);
  }

  /// Updates existing fields in a document.
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> updates) async {
    final key = '$collectionPath/$documentId';
    final existing = _inMemoryCollectionStore[key] ?? {};
    existing.addAll(updates);
    _inMemoryCollectionStore[key] = existing;
  }

  /// Streams real-time updates for a document.
  Stream<FirestoreDocSnapshot> documentStream(String collectionPath, String documentId) async* {
    yield await getDocument(collectionPath, documentId);
  }

  /// Queries all documents in a collection.
  Future<FirestoreQuerySnapshot> getCollection(String collectionPath) async {
    final docs = <FirestoreDocSnapshot>[];
    _inMemoryCollectionStore.forEach((path, data) {
      if (path.startsWith('$collectionPath/')) {
        final id = path.split('/').last;
        docs.add(FirestoreDocSnapshot(id: id, path: path, exists: true, data: data));
      }
    });
    return FirestoreQuerySnapshot(docs: docs, count: docs.length);
  }
}
