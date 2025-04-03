import 'package:flutter/material.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
import 'package:mynotes/views/notes/private_view.dart';
import 'package:mynotes/utilities/dialogs/password_dialogs.dart';

typedef NoteCallback = void Function(CloudNote note);

class NotesListView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;
  final NoteCallback onTogglePin;
  final bool isGridView;
  final int currentIndex;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onDeleteNote,
    required this.onTap,
    required this.onTogglePin,
    required this.isGridView,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGrid();
    } else {
      return _buildList();
    }
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20), // Consistent padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes.elementAt(index);
        return _buildNoteCard(context, note, isList: true);
      },
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16), // Distinct padding
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes.elementAt(index);
        return _buildListItem(context, note, index + 1);
      },
    );
  }

  Widget _buildListItem(BuildContext context, CloudNote note, int index) {
    return InkWell(
      onTap: () => onTap(note),
      child: Column(
        children: [
          if (index > 1) // Skip divider for first item
            Container(
              height: 1,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index < 10 ? '0$index /' : '$index /',
                style: TextStyle(fontSize: 20, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.text.isNotEmpty
                          ? (note.text.length > 50
                              ? '${note.text.substring(0, 50)}...'
                              : note.text)
                          : 'No content',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16), // Add spacing before timestamp
                    Text(
                      "Created: ${_formattedDate(note, updated: false)}", // Use createdAt
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, CloudNote note,
      {bool isList = false}) {
    final privateManager = PrivateNotesManager();

    return IntrinsicHeight(
      child: GestureDetector(
        onTap: () => onTap(note),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isList
              ? Colors.white70
              : Colors.white, // Subtle difference for list
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title.isNotEmpty ? note.title : 'Untitled',
                  style: const TextStyle(
                    color: Color.fromRGBO(31, 41, 55, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    note.text.isNotEmpty ? note.text : 'No content',
                    style: const TextStyle(
                      color: Color.fromRGBO(31, 41, 55, 1),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.fade,
                    maxLines:
                        isList ? 4 : 8, // Fewer lines in list for distinction
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Created: ${_formattedDate(note, updated: false)}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIcon(
                      icon: note.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: note.pinned ? Colors.yellow : Colors.blue,
                      onPressed: () => onTogglePin(note),
                    ),
                    _buildIcon(
                      icon: Icons.delete,
                      color: Colors.redAccent,
                      onPressed: () async {
                        final shouldDelete = await showDeleteDialog(context);
                        if (shouldDelete) {
                          onDeleteNote(note);
                        }
                      },
                    ),
                    _buildIcon(
                      icon:
                          note.isPrivate ? Icons.lock_open : Icons.lock_outline,
                      color: Colors.blue,
                      onPressed: () async {
                        final successs = await privateManager.togglePrivacy(
                          note: note,
                          onSuccess: () {
                            // Refresh UI
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(note.isPrivate
                                    ? 'Note Unlocked'
                                    : 'Note Locked'),
                              ),
                            );
                          },
                           onSetPassword: (docId, text, isPrivate) => showSetPasswordDialog(context, privateManager),
                          onVerifyPassword: (title) => showVerifyPasswordDialog(context, privateManager, title: title),
                          onRecoverPassword: privateManager.recoverPassword,
                        );

                        if (!successs && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Action Failed'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      width: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
  }

  String _formattedDate(CloudNote note, {bool updated = false}) {
    final date = updated ? note.updatedAt : note.createdAt;

    final now = DateTime.now();
    final difference = now.difference(date);

    // Less than 12 hours: Show time (e.g., "2:30 PM")
    if (difference.inHours < 12) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';
      return "$hour:$minute $period";
    }
    // Less than 24 hours: "Today"
    else if (difference.inHours < 24) {
      return "Today";
    }
    // 24–48 hours: "Yesterday"
    else if (difference.inHours < 48) {
      return "Yesterday";
    }
    // 2–6 days: "X days ago"
    else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    }
    // 7–13 days: "Last week"
    else if (difference.inDays < 14) {
      return "Last week";
    }
    // 14–30 days: "Last month"
    else if (difference.inDays < 31) {
      return "Last month";
    }
    // 31–365 days: "Last year"
    else if (difference.inDays < 366) {
      return "Last year";
    }
    // Over a year: Full date
    else {
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";
    }
  }
}
