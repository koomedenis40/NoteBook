import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

@immutable
class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final List<String> attachedFiles;

  const CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.attachedFiles,
  });

  // Fix: Correctly initializing `attachedFiles` inside {}
  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName] as String,
        text = snapshot.data()[textFieldName] as String,
        attachedFiles = List<String>.from(snapshot.data()['attachedFiles'] ?? []);

  // Fix: Correct placement of `toJson` method inside class
  Map<String, dynamic> toJson() {
    return {
      'ownerUserId': ownerUserId,
      'text': text,
      'attachedFiles': attachedFiles,
    };
  }
}
