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

  // Layout toggle: grid vs list
  bool _isGridView = true;

  // Index for bottom navigation: 0=All, 1=Pinned, 2=Private
  int _currentIndex = 0;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // -------------------------
      // APP BAR
      // -------------------------
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: StreamBuilder(
          stream: _notesService.allNotes(ownerUserId: userId).getLength,
          builder: (context, AsyncSnapshot<int> snapshot) {
            if (snapshot.hasData) {
              final noteCount = snapshot.data ?? 0;
              final text = context.loc.notes_title(noteCount);
              return Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
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
          // 1) Toggle Grid/List
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),

          // 2) Sort popup (with a sort icon)
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
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
              const PopupMenuItem(
                value: 'Sort by Created',
                child: Text('Sort by Created'),
              ),
              const PopupMenuItem(
                value: 'Sort by Updated',
                child: Text('Sort by Updated'),
              ),
              const PopupMenuItem(
                value: 'Sort by Name',
                child: Text('Sort by Name'),
              ),
            ],
          ),

          // 3) Add Note
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),

          // 4) Logout popup
          PopupMenuButton<MenuAction>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
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

      // -------------------------
      // BODY: we display the appropriate subset of notes
      // based on _currentIndex
      // -------------------------
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
                        // Filter the notes based on _currentIndex
                        final filtered = _filterNotesByIndex(allNotes);

                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text(
                              "No notes yet, tap + to create one!",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          );
                        }
                        // sort pinned first, then sort by _sortCriterion
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

      // -------------------------
      // BOTTOM NAVIGATION BAR
      // -------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Color.fromARGB(255, 10, 19, 36),
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.white,
        onTap: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'All Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.push_pin),
            label: 'Pinned',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: 'Private Notes',
          ),
        ],
      ),
    );
  }

  // Decide how to filter notes based on bottom nav index
  // 0 => All (non-private)
  // 1 => pinned & non-private
  // 2 => private
  Iterable<CloudNote> _filterNotesByIndex(Iterable<CloudNote> allNotes) {
    switch (_currentIndex) {
      case 1:
        // pinned & not private
        return allNotes.where((n) => n.pinned && !n.isPrivate);
      case 2:
        // isPrivate
        return allNotes.where((n) => n.isPrivate);
      default:
        // index=0 => non-private (includes pinned & unpinned)
        return allNotes.where((n) => !n.isPrivate);
    }
  }

  // We separate pinned from unpinned, then sort each group
  // using _compareNotes, and place pinned group first
  List<CloudNote> _sortAndPin(Iterable<CloudNote> notes) {
    final pinnedNotes = notes.where((n) => n.pinned).toList();
    final unpinnedNotes = notes.where((n) => !n.pinned).toList();
    pinnedNotes.sort(_compareNotes);
    unpinnedNotes.sort(_compareNotes);
    return [...pinnedNotes, ...unpinnedNotes];
  }

  // Sort by created/updated/name
  int _compareNotes(CloudNote a, CloudNote b) {
    switch (_sortCriterion) {
      case SortCriterion.dateCreated:
        // Newest first
        return b.createdAt.compareTo(a.createdAt);
      case SortCriterion.dateUpdated:
        // Newest first
        return b.updatedAt.compareTo(a.updatedAt);
      case SortCriterion.name:
        return a.text.toLowerCase().compareTo(b.text.toLowerCase());
    }
  }
}
