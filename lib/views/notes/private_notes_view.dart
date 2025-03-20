import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';

class PrivateNotesView extends StatefulWidget {
  const PrivateNotesView({super.key});

  @override
  State<PrivateNotesView> createState() => _PrivateNotesViewState();
}

class _PrivateNotesViewState extends State<PrivateNotesView> {
  late final FirebaseCloudStorage _notesService;
  bool _unlocked = false;
  final _passcodeController = TextEditingController();
  final _correctPasscode = "1234"; // for demonstration

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
  }

  String get userId => AuthService.firebase().currentUser!.id;

  void _checkPasscode() {
    if (_passcodeController.text.trim() == _correctPasscode) {
      setState(() {
        _unlocked = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect passcode")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text("Private Notes")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter passcode to unlock private notes:"),
                const SizedBox(height: 10),
                TextField(
                  controller: _passcodeController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Passcode"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _checkPasscode,
                  child: const Text("Unlock"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // show isPrivate = true notes
    return Scaffold(
      appBar: AppBar(title: const Text("Private Notes")),
      body: StreamBuilder(
        stream: _notesService.allNotes(ownerUserId: userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final allNotes = snapshot.data as Iterable<CloudNote>;
            final privateNotes = allNotes.where((n) => n.isPrivate);
            if (privateNotes.isEmpty) {
              return const Center(child: Text("No private notes yet!"));
            }
            return NotesListView(
              notes: privateNotes,
              isGridView: false,
              onDeleteNote: (note) async {
                await _notesService.deleteNote(documentId: note.documentId);
              },
              onTap: (note) {
                // open in createUpdateNoteView if you like
              },
              onTogglePin: (note) async {
                await _notesService.updateNote(
                  documentId: note.documentId,
                  text: note.text,
                  pinned: !note.pinned,
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
