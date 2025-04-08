import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:mynotes/utilities/generics/list_formatting_utils.dart';
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
  late final FocusNode _titleFocusNode;
  late final FocusNode _textFocusNode;
  late final ScrollController _scrollController;
  List<String> _attachedFiles = [];
  Timer? _debounceTimer;
  bool _isCreatingNote = false;

  static Color accentColor = Colors.grey.shade300;

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    _titleFocusNode = FocusNode();
    _textFocusNode = FocusNode();
    _scrollController = ScrollController(); // Initialize ScrollController
    // Focus immediately on the text field if it's empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textController.text.isEmpty) {
        FocusScope.of(context).requestFocus(
            _textFocusNode); // Make sure the focus is correctly set
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_handleTextChanged);
    _titleController.removeListener(_handleTextChanged);
    _textController.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _textFocusNode.dispose();
    _scrollController.dispose(); // Dispose ScrollController
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
        await _notesService.deleteNote(documentId: _existingNote!.documentId);
        setState(() {
          _existingNote = null;
          _isCreatingNote = false;
        });
      } else if ((text.isNotEmpty || title.isNotEmpty) &&
          _existingNote != null) {
        await _updateExistingNote(title, text);
      }
    });
  }

  Future<void> _createNewNote(String title, String text) async {
    if (_isCreatingNote) return;
    setState(() => _isCreatingNote = true);

    final currentUser = AuthService.firebase().currentUser!;
    final newNote = await _notesService.createNewNote(
      ownerUserId: currentUser.id,
      text: text,
      title: title,
    );
    setState(() {
      _existingNote = newNote;
      _isCreatingNote = false;
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
        await _createNewNote(title, text);
      } else {
        await _updateExistingNote(title, text);
      }
    } else if (_existingNote != null) {
      await _notesService.deleteNote(documentId: _existingNote!.documentId);
      setState(() {
        _existingNote = null;
        _isCreatingNote = false;
      });
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles
              .addAll(result.files.map((file) => file.path ?? "").toList());
        });
        final text = _textController.text.trim();
        final title = _titleController.text.trim();
        if (text.isNotEmpty || title.isNotEmpty) {
          if (_existingNote == null) {
            await _createNewNote(title, text);
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
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    if (text.isEmpty || title.isEmpty) {
      await showCannotShareEmptyNoteDialog(context);
      return;
    }
    final shareContent = [
      if (title.isNotEmpty) title,
      if (title.isNotEmpty && text.isNotEmpty) '',
      if (text.isNotEmpty) text,
    ].join('\n');

    Share.share(shareContent);
  }

  void _scrollToCursor() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _manualSaveAndPop();
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Allow resizing with keyboard
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'My Note',
                          style: TextStyle(fontSize: 28, color: Colors.black),
                        ),
                        Expanded(child: Container()),
                        if (_existingNote != null)
                          Row(
                            children: [
                              InkWell(
                                onTap: () async {
                                  final shouldDelete = await showDeleteDialog(context);
                                  if (shouldDelete) {
                                    await _notesService.deleteNote(documentId: _existingNote!.documentId);
                                    if (mounted) Navigator.pop(context);
                                  }
                                },
                                child: const Icon(Icons.delete, color: Colors.red, size: 18),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        InkWell(
                          onTap: _manualSaveAndPop,
                          child: const Icon(Icons.save_as_outlined, color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _shareNote,
                          child: const Icon(Icons.share, color: Colors.blue, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Divider(color: Colors.black, thickness: 1),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      onChanged: (value) => setState(() {}),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context).requestFocus(_textFocusNode);
                      },
                      style: const TextStyle(fontSize: 26, color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    ),
                  ],
                ),
              ),
              // Text Area (Expanded to push footer down)
              Expanded(
                child: FutureBuilder(
                  future: _loadNoteIfEditing(context),
                  builder: (context, snapshot) {
                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(2),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: TextField(
                            controller: _textController,
                            focusNode: _textFocusNode,
                            onChanged: (value) {
                              final previousSelection = _textController.selection;
                              setState(() {});
                              ListFormattingUtils.handleListFormatting(value, _textController, previousSelection);
                              _scrollToCursor(); // Scroll to cursor
                            },
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: context.loc.start_typing_your_note,
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Footer (Fixed at bottom)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          Icon(Icons.attach_file, size: 16),
                          SizedBox(width: 8),
                          Text('Attach', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Text(
                      '${_textController.text.length} characters',
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Attachments (if any)
              if (_attachedFiles.isNotEmpty)
                SizedBox(
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
                              style: const TextStyle(color: Color.fromRGBO(31, 41, 55, 1)),
                            ),
                            backgroundColor: accentColor.withOpacity(0.8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}