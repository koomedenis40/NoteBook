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

  // ✅ Flag to ensure we only create one note per session
  bool _noteCreationInProgress = false;

  // ✅ Track previous text to avoid redundant updates (if needed)
  String _previousText = "";

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

  // ✅ Load an existing note (if editing) 
  // This function is called once, so if you're editing, it loads the note.
  Future<void> _loadNoteIfEditing(BuildContext context) async {
    final noteArg = context.getArgument<CloudNote>();
    if (noteArg != null && _existingNote == null) {
      setState(() {
        _existingNote = noteArg;
        _textController.text = noteArg.text;
        _attachedFiles = noteArg.attachedFiles;
        _previousText = noteArg.text;
      });
    }
  }

  // ✅ Handle text changes
  // This function checks if a note already exists.
  // If not, and if text is non-empty, it creates a note only once.
  void _handleTextChanged() async {
    final text = _textController.text.trim();

    // If no note exists, text is non-empty, and creation is not already in progress:
    if (_existingNote == null && text.isNotEmpty && !_noteCreationInProgress) {
      _noteCreationInProgress = true; // set flag to avoid duplicate creation
      await _createNewNoteInFirestore(text);
      _noteCreationInProgress = false; // reset flag after creation
    }
    // If a note exists and text is non-empty, update it.
    else if (_existingNote != null && text.isNotEmpty) {
      await _notesService.updateNoteWithAttachments(
        documentId: _existingNote!.documentId,
        text: text,
        attachedFiles: _attachedFiles,
      );
    }
    // If a note exists and text is empty, delete it.
    else if (_existingNote != null && text.isEmpty) {
      await _notesService.deleteNote(documentId: _existingNote!.documentId);
      setState(() {
        _existingNote = null;
      });
    }
    _previousText = text;
  }

  // ✅ Create a new note in Firestore.
  // This function is only called once when the user first types non-empty text.
  Future<void> _createNewNoteInFirestore(String text) async {
    final currentUser = AuthService.firebase().currentUser!;
    // Pass the text even if it's non-empty because our listener ensures this is only called when text is provided.
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files.map((file) => file.path ?? ""));
        });
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

  // Manual save when the user taps Save.
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
      future: _loadNoteIfEditing(context), // Load note if editing; if not, note remains null until text is entered.
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _existingNote == null ? context.loc.note : "Edit Note",
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
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
      },
    );
  }
}
