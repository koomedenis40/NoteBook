import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enum/menu_action.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import 'package:mynotes/enum/selection_action.dart';

extension Count<T extends Iterable> on Stream {
  Stream<int> get getLength => map((event) => event.length);
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final FirebaseCloudStorage _notesService;
  late SortCriterion _sortCriterion;
  bool _isGridView = true; // Grid view by default
  int _currentIndex = 0; // Bottom navigation index

  String get userId => AuthService.firebase().currentUser!.id;

  @override
  void initState() {
    super.initState();
    _notesService = FirebaseCloudStorage();
    _sortCriterion = SortCriterion.dateUpdated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade300,
        title: StreamBuilder(
          stream: _notesService.allNotes(ownerUserId: userId).getLength,
          builder: (context, AsyncSnapshot<int> snapshot) {
            if (snapshot.hasData) {
              final noteCount = snapshot.data ?? 0;
              final text = context.loc.notes_title(noteCount);
              return Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              );
            } else {
              return const Text('');
            }
          },
        ),
        actions: [
          // Toggle Grid/List
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
                debugPrint('Toggled to ${_isGridView ? "Grid" : "List"}');
              });
            },
          ),
          // Sort popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            onSelected: (value) {
              setState(() {
                if (value == 'Sort by Created') {
                  _sortCriterion = SortCriterion.dateCreated;
                } else if (value == 'Sort by Updated') {
                  _sortCriterion = SortCriterion.dateUpdated;
                } else if (value == 'Sort by Name') {
                  _sortCriterion = SortCriterion.name;
                }
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'Sort by Created', child: Text('Sort by Created')),
              const PopupMenuItem(value: 'Sort by Updated', child: Text('Sort by Updated')),
              const PopupMenuItem(value: 'Sort by Name', child: Text('Sort by Name')),
            ],
          ),
          // Add Note
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
            },
            icon: const Icon(Icons.add, color: Colors.black),
          ),
          // Logout popup
          PopupMenuButton<MenuAction>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout && mounted) {
                    context.read<AuthBloc>().add(const AuthEventLogOut());
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text(context.loc.logout_button),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _notesService.allNotes(ownerUserId: userId),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      if (snapshot.hasData) {
                        final allNotes = snapshot.data as Iterable<CloudNote>;
                        final filtered = _filterNotesByIndex(allNotes);
                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text(
                              "No notes yet, tap + to create one!",
                              style: TextStyle(
                                color: Color.fromRGBO(31, 41, 55, 1),
                                fontSize: 16,
                              ),
                            ),
                          );
                        }
                        final sorted = _sortAndPin(filtered);
                        return NotesListView(
                          notes: sorted,
                          isGridView: _isGridView,     
                          onDeleteNote: (note) async {
                            await _notesService.deleteNote(documentId: note.documentId);
                          },
                          onTap: (note) {
                            Navigator.of(context).pushNamed(
                              createOrUpdateNoteRoute,
                              arguments: note,
                            );
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
                    default:
                      return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: Colors.white10),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.grey.shade300,
            unselectedItemColor: Colors.black,
            selectedItemColor: Colors.white,
            onTap: (newIndex) {
              setState(() {
                _currentIndex = newIndex;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'All Notes'),
              BottomNavigationBarItem(icon: Icon(Icons.push_pin), label: 'Pinned Notes'),
              BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Private Notes'),
            ],
          ),
        ],
      ),
    );
  }

  Iterable<CloudNote> _filterNotesByIndex(Iterable<CloudNote> allNotes) {
    switch (_currentIndex) {
      case 1:
        return allNotes.where((n) => n.pinned && !n.isPrivate);
      case 2:
        return allNotes.where((n) => n.isPrivate);
      default:
        return allNotes.where((n) => !n.pinned && !n.isPrivate);
    }
  }

  List<CloudNote> _sortAndPin(Iterable<CloudNote> notes) {
    final pinnedNotes = notes.where((n) => n.pinned).toList();
    final unpinnedNotes = notes.where((n) => !n.pinned).toList();
    pinnedNotes.sort(_compareNotes);
    unpinnedNotes.sort(_compareNotes);
    return [...pinnedNotes, ...unpinnedNotes];
  }

  int _compareNotes(CloudNote a, CloudNote b) {
    switch (_sortCriterion) {
      case SortCriterion.dateCreated:
        return b.createdAt.compareTo(a.createdAt);
      case SortCriterion.dateUpdated:
        return b.updatedAt.compareTo(a.updatedAt);
      case SortCriterion.name:
        return a.text.toLowerCase().compareTo(b.text.toLowerCase());
    }
  }
}