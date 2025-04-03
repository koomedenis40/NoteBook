import 'package:mynotes/services/cloud/cloud_note.dart';

class NoteFilter {
  final int currentIndex;

  NoteFilter(this.currentIndex);

  Iterable<CloudNote> filterNotes(Iterable<CloudNote> allNotes) {
    switch (currentIndex) {
      case 1:
        return allNotes.where((n) => n.pinned && !n.isPrivate); // Pinned, non-private
      case 2:
        return allNotes.where((n) => n.isPrivate); // Private notes
      default:
        return allNotes.where((n) => !n.pinned && !n.isPrivate); // Unpinned, non-private
    }
  }
}