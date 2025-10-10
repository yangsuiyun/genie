// Notes provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/note_service.dart';

// Note service provider
final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService();
});

// Notes provider
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final noteService = ref.read(noteServiceProvider);
  return noteService.notes;
});

// Selected note provider
final selectedNoteProvider = StateProvider<Note?>((ref) => null);

// Note filter provider
final noteFilterProvider = StateProvider<NoteFilter>((ref) => NoteFilter());

// Filtered notes provider
final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).value ?? [];
  final filter = ref.watch(noteFilterProvider);
  
  return notes.where((note) {
    if (filter.taskId != null && note.taskId != filter.taskId) return false;
    if (filter.search != null && filter.search!.isNotEmpty) {
      final searchLower = filter.search!.toLowerCase();
      if (!note.content.toLowerCase().contains(searchLower)) return false;
    }
    return true;
  }).toList();
});

// Note service class
class NoteService {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  void addNote(Note note) {
    _notes.add(note);
  }

  void updateNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    }
  }

  void deleteNote(String noteId) {
    _notes.removeWhere((n) => n.id == noteId);
  }
}

// Note filter class
class NoteFilter {
  final String? taskId;
  final String? search;

  NoteFilter({
    this.taskId,
    this.search,
  });

  NoteFilter copyWith({
    String? taskId,
    String? search,
  }) {
    return NoteFilter(
      taskId: taskId ?? this.taskId,
      search: search ?? this.search,
    );
  }
}

// Note model
class Note {
  final String id;
  final String taskId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? taskId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
