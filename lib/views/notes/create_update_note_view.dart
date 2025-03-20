import 'package:flutter/material.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _existingNote;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textController;
  List<String> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    super.dispose();
  }

  // If we're editing an existing note, load it
  Future<void> _loadNoteIfEditing(BuildContext context) async {
    final noteArg = context.getArgument<CloudNote>();
    if (noteArg != null && _existingNote == null) {
      setState(() {
        _existingNote = noteArg;
        _textController.text = noteArg.text;
        _attachedFiles = noteArg.attachedFiles;
      });
    }
  }

  // Called whenever the text field changes
  void _handleTextChanged() async {
    final text = _textController.text.trim();
    // 1) If no existing note & text is non-empty => create new doc
    if (_existingNote == null && text.isNotEmpty) {
      await _createNewNoteInFirestore(text);
    }
    // 2) If we have an existing note & text is non-empty => update doc
    else if (_existingNote != null && text.isNotEmpty) {
      await _notesService.updateNoteWithAttachments(
        documentId: _existingNote!.documentId,
        text: text,
        attachedFiles: _attachedFiles,
      );
    }
    // 3) If we have an existing note & user cleared the text => delete doc
    else if (_existingNote != null && text.isEmpty) {
      await _notesService.deleteNote(documentId: _existingNote!.documentId);
      setState(() {
        _existingNote = null;
      });
    }
  }

  // Create a new note doc in Firestore
  Future<void> _createNewNoteInFirestore(String text) async {
    final currentUser = AuthService.firebase().currentUser!;
    final newNote = await _notesService.createNewNote(
      ownerUserId: currentUser.id,
      text: text,
    );
    if (_attachedFiles.isNotEmpty) {
      await _notesService.updateNoteWithAttachments(
        documentId: newNote.documentId,
        text: text,
        attachedFiles: _attachedFiles,
      );
    }
    setState(() {
      _existingNote = newNote;
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files.map((file) => file.path ?? ""));
        });
        // If we already have a note & text is non-empty => update attachments
        final text = _textController.text.trim();
        if (_existingNote != null && text.isNotEmpty) {
          await _notesService.updateNoteWithAttachments(
            documentId: _existingNote!.documentId,
            text: text,
            attachedFiles: _attachedFiles,
          );
        }
      }
    } catch (e, stacktrace) {
      debugPrint("Error picking files: $e");
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> _openFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    debugPrint("Open result: $result");
  }

  // The user may tap Save manually. We do one last update & pop.
  Future<void> _manualSaveAndPop() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty && _existingNote != null) {
      await _notesService.updateNoteWithAttachments(
        documentId: _existingNote!.documentId,
        text: text,
        attachedFiles: _attachedFiles,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadNoteIfEditing(context),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
          case ConnectionState.done:
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  _existingNote == null
                      ? context.loc.note // "Create Note"
                      : "Edit Note",
                  style: const TextStyle(color: Colors.white),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                actions: [
                  // Share
                  IconButton(
                    onPressed: () async {
                      final text = _textController.text.trim();
                      if (text.isEmpty) {
                        await showCannotShareEmptyNoteDialog(context);
                      } else {
                        Share.share(text);
                      }
                    },
                    icon: const Icon(Icons.share, color: Colors.white),
                  ),
                  // Save icon (user can manually save & pop)
                  IconButton(
                    onPressed: _manualSaveAndPop,
                    icon: const Icon(Icons.save, color: Colors.white),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: context.loc.start_typing_your_note,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_attachedFiles.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _attachedFiles.map((file) {
                                    final fileName = file.split('/').last;
                                    return GestureDetector(
                                      onTap: () => _openFile(file),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.insert_drive_file,
                                                color: Colors.blueGrey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                fileName,
                                                style: const TextStyle(color: Colors.black54),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file, color: Colors.white),
                      label: const Text("Attach File", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
