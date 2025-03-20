import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  // Delete a note
  Future<void> deleteNote({
    required String documentId,
  }) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  // Update Note (Text, pinned, isPrivate) with updatedAt always set
  Future<void> updateNote({
    required String documentId,
    required String text,
    bool? pinned,
    bool? isPrivate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        textFieldName: text,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (pinned != null) {
        updateData['pinned'] = pinned;
      }
      if (isPrivate != null) {
        updateData['isPrivate'] = isPrivate;
      }
      await notes.doc(documentId).update(updateData);
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  // Update Note with Attachments
  Future<void> updateNoteWithAttachments({
    required String documentId,
    required String text,
    required List<String> attachedFiles,
    bool? pinned,
    bool? isPrivate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        textFieldName: text,
        'attachedFiles': attachedFiles,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (pinned != null) {
        updateData['pinned'] = pinned;
      }
      if (isPrivate != null) {
        updateData['isPrivate'] = isPrivate;
      }
      await notes.doc(documentId).update(updateData);
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  // Stream All Notes by User
  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) {
    final allNotes = notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) => event.docs.map((doc) => CloudNote.fromSnapshot(doc)));
    return allNotes;
  }

  // Create a New Note
  // pinned, isPrivate = false by default
  // createdAt, updatedAt = serverTimestamp
  Future<CloudNote> createNewNote({
    required String ownerUserId,
    required String text,
  }) async {
    try {
      final documentRef = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        textFieldName: text,
        'attachedFiles': [],
        'pinned': false,
        'isPrivate': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final fetchNote = await documentRef.get();
      return CloudNote.fromSnapshot(
        fetchNote as QueryDocumentSnapshot<Map<String, dynamic>>,
      );
    } catch (e) {
      throw CouldNotCreateNoteException();
    }
  }

  // Singleton
  static final FirebaseCloudStorage _shared = FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
