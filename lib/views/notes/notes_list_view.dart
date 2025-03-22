import 'package:flutter/material.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';

typedef NoteCallback = void Function(CloudNote note);

class NotesListView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;
  final NoteCallback onTogglePin;
  final bool isGridView;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onDeleteNote,
    required this.onTap,
    required this.onTogglePin,
    required this.isGridView,
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
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes.elementAt(index);
        return _buildNoteCard(context, note);
      },
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes.elementAt(index);
        return _buildNoteCard(context, note);
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, CloudNote note) {
    return GestureDetector(
      onTap: () => onTap(note),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Color.fromRGBO(61, 90, 127, 1.0),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note text at the top
              Text(
                note.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.fade,
                maxLines: 10,
              ),

              const Spacer(),

              // 1st bottom row: Updated time
              Text(
                "Updated: ${_formattedDate(note, updated: true)}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 8),

              // 2nd bottom row: Icons aligned right
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  children: [
                    _buildIcon(
                      icon: note.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: note.pinned ? Colors.yellow : Colors.white,
                      onPressed: () => onTogglePin(note),
                    ),
                    const SizedBox(width: 4),
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
                    const SizedBox(width: 4),
                    _buildIcon(
                      icon: Icons.lock_outline,
                      color: Colors.white,
                      onPressed: () {
                        // TODO: Lock note
                      },
                    ),
                  ],
                ),
              ),
            ],
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
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')} ";

  }
}
