import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

@immutable
class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final List<String> attachedFiles;
  final bool pinned;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.attachedFiles,
    required this.pinned,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
  });

  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName] as String,
        text = snapshot.data()[textFieldName] as String? ?? '',
        attachedFiles = List<String>.from(snapshot.data()['attachedFiles'] ?? []),
        pinned = snapshot.data()['pinned'] as bool? ?? false,
        isPrivate = snapshot.data()['isPrivate'] as bool? ?? false,
        createdAt = (snapshot.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt = (snapshot.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      ownerUserIdFieldName: ownerUserId,
      textFieldName: text,
      'attachedFiles': attachedFiles,
      'pinned': pinned,
      'isPrivate': isPrivate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
