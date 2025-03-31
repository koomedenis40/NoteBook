import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:async';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _existingNote;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textController;
  late final TextEditingController _titleController;
  List<String> _attachedFiles = [];
  Timer? _debounceTimer;
  bool _isCreatingNote = false; // Added: Flag to prevent multiple creations

  static const Color backgroundColor = Color.fromRGBO(249, 250, 251, 1);
  static Color accentColor = Colors.grey.shade300;

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    _textController.addListener(_handleTextChanged);
    _titleController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_handleTextChanged);
    _titleController.removeListener(_handleTextChanged);
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteIfEditing(BuildContext context) async {
    final noteArg = context.getArgument<CloudNote>();
    if (noteArg != null && _existingNote == null) {
      setState(() {
        _existingNote = noteArg;
        _textController.text = noteArg.text;
        _titleController.text = noteArg.title;
        _attachedFiles = noteArg.attachedFiles;
      });
    }
  }

  void _handleTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      final text = _textController.text.trim();
      final title = _titleController.text.trim();

      if (text.isEmpty && title.isEmpty && _existingNote != null) {
        // Delete note if both text and title are empty
        await _notesService.deleteNote(documentId: _existingNote!.documentId);
        setState(() {
          _existingNote = null;
          _isCreatingNote = false; // Reset flag
        });
      } else if ((text.isNotEmpty || title.isNotEmpty) && _existingNote != null) {
        // Update existing note only
        await _updateExistingNote(title, text);
      }
      // Note creation is now handled manually or on first save, not here
    });
  }

  Future<void> _createNewNote(String title, String text) async {
    if (_isCreatingNote) return; // Prevent multiple creations
    setState(() => _isCreatingNote = true); // Set flag

    final currentUser = AuthService.firebase().currentUser!;
    final newNote = await _notesService.createNewNote(
      ownerUserId: currentUser.id,
      text: text,
      title: title,
    );
    setState(() {
      _existingNote = newNote; // Set immediately
      _isCreatingNote = false; // Reset flag after creation
    });
    await _notesService.updateNoteWithAttachments(
      documentId: newNote.documentId,
      text: text,
      title: title,
      attachedFiles: _attachedFiles,
    );
  }

  Future<void> _updateExistingNote(String title, String text) async {
    if (_existingNote == null) return;
    await _notesService.updateNoteWithAttachments(
      documentId: _existingNote!.documentId,
      text: text,
      title: title,
      attachedFiles: _attachedFiles,
    );
  }

  Future<void> _manualSaveAndPop() async {
    final text = _textController.text.trim();
    final title = _titleController.text.trim();
    if (text.isNotEmpty || title.isNotEmpty) {
      if (_existingNote == null) {
        await _createNewNote(title, text); // Create only on explicit save if new
      } else {
        await _updateExistingNote(title, text);
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files.map((file) => file.path ?? "").toList());
        });
        final text = _textController.text.trim();
        final title = _titleController.text.trim();
        if (text.isNotEmpty || title.isNotEmpty) {
          if (_existingNote == null) {
            await _createNewNote(title, text); // Create only when attaching if new
          } else {
            await _updateExistingNote(title, text);
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  Future<void> _openFile(String filePath) async {
    await OpenFilex.open(filePath);
  }

  Future<void> _shareNote() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      await showCannotShareEmptyNoteDialog(context);
    } else {
      Share.share(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadNoteIfEditing(context),
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 0,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Note',
                                style: TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              Expanded(child: Container()),
                              if (_existingNote != null)
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        await _notesService.deleteNote(documentId: _existingNote!.documentId);
                                        Navigator.pop(context);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              InkWell(
                                onTap: _manualSaveAndPop,
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: _shareNote,
                                child: const Icon(
                                  Icons.share,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: Colors.black,
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                _existingNote != null
                                    ? 'Last edited: ${DateTime.now().toString().substring(0, 16)}'
                                    : 'Created: ${DateTime.now().toString().substring(0, 16)}',
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                              ),
                              Expanded(child: Container()),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _titleController,
                            onChanged: (value) => setState(() {}),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: const TextStyle(fontSize: 48, color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Title',
                              hintStyle: const TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(25),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: TextField(
                            controller: _textController,
                            onChanged: (value) => setState(() {}),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                            decoration: InputDecoration(
                              hintText: context.loc.start_typing_your_note,
                              hintStyle: const TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(70),
                            ],
                          ),
                        ),
                        if (_attachedFiles.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _attachedFiles.length,
                                itemBuilder: (context, index) {
                                  final filePath = _attachedFiles[index];
                                  final fileName = filePath.split('/').last;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () => _openFile(filePath),
                                      child: Chip(
                                        label: Text(
                                          fileName,
                                          style: const TextStyle(
                                            color: Color.fromRGBO(31, 41, 55, 1),
                                          ),
                                        ),
                                        backgroundColor: accentColor.withOpacity(0.8),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _pickFiles,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Attach Files',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_textController.text.length} characters',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
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