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
  List<String> _attachedFiles = [];
  Timer? _debounceTimer;

  // Updated background color: a warmer, muted teal
  static const Color backgroundColor = Color.fromRGBO(249, 250, 251, 1);
  static  Color accentColor = Colors.grey.shade300; // Slightly lighter for contrast

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    super.dispose();
  }

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

  void _handleTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final text = _textController.text.trim();
      if (text.isEmpty && _existingNote != null) {
        await _notesService.deleteNote(documentId: _existingNote!.documentId);
        setState(() => _existingNote = null);
      } else if (text.isNotEmpty) {
        if (_existingNote == null) {
          await _createNewNote(text);
        } else {
          await _updateExistingNote(text);
        }
      }
    });
  }

  Future<void> _createNewNote(String text) async {
    final currentUser = AuthService.firebase().currentUser!;
    final newNote = await _notesService.createNewNote(
      ownerUserId: currentUser.id,
      text: text,
    );
    await _notesService.updateNoteWithAttachments(
      documentId: newNote.documentId,
      text: text,
      attachedFiles: _attachedFiles,
    );
    setState(() => _existingNote = newNote);
  }

  Future<void> _updateExistingNote(String text) async {
    await _notesService.updateNoteWithAttachments(
      documentId: _existingNote!.documentId,
      text: text,
      attachedFiles: _attachedFiles,
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files.map((file) => file.path ?? "").toList());
        });
        final text = _textController.text.trim();
        if (_existingNote != null && text.isNotEmpty) {
          await _updateExistingNote(text);
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
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: AppBar(
              backgroundColor: Colors.grey.shade300,
              elevation: 0,
              leadingWidth: 40,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.only(left: 8),
              ),
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _existingNote == null ? 'New Note' : 'Edit Note',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(31, 41, 55, 1),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _existingNote == null ? 'Draft' : 'Saved',
                      style: TextStyle(
                        color: _existingNote == null ? Colors.orangeAccent : Colors.greenAccent[700],
                        fontSize: 14,
                        
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save, size: 18),
                  onPressed: _manualSaveAndPop,
                  tooltip: 'Save',
                  color: Colors.black,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: _shareNote,
                  tooltip: 'Share Note',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [backgroundColor, accentColor], // Subtle gradient
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 16.0, top: 8.0), // Align with title
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            expands: true,
                            textAlign: TextAlign.left,
                            textAlignVertical: TextAlignVertical.top,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.5,
                                  color: Color.fromRGBO(31, 41, 55, 1),
                                ),
                            decoration: InputDecoration(
                              hintText: context.loc.start_typing_your_note,
                              hintStyle: TextStyle(
                                color:Color.fromRGBO(31, 41, 55, 1),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _existingNote != null
                                ? 'Last edited: ${DateTime.now().toString().substring(0, 16)}'
                                : 'Created: ${DateTime.now().toString().substring(0, 16)}',
                            style: TextStyle(
                              color: Color.fromRGBO(31, 41, 55, 1),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_attachedFiles.isNotEmpty)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: accentColor, // Match gradient end
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.attach_file,
                          color: Color.fromRGBO(31, 41, 55, 1),
                          size: 18,
                        ),
                        onPressed: _pickFiles,
                        tooltip: 'Attach File',
                      ),
                      Text(
                        '${_textController.text.length} characters',
                        style: TextStyle(
                          color: Color.fromRGBO(31, 41, 55, 1),
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