import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记事本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const NoteListPage(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList('notes') ?? [];
    setState(() {
      _notes = notesJson
          .map((e) => Note.fromJson(jsonDecode(e)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = _notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }

  Future<void> _deleteNote(String id) async {
    setState(() {
      _notes.removeWhere((n) => n.id == id);
    });
    await _saveNotes();
  }

  void _openEditor({Note? note}) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(note: note),
      ),
    );
    if (result != null) {
      setState(() {
        _notes.removeWhere((n) => n.id == result.id);
        _notes.insert(0, result);
      });
      await _saveNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的记事本'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有笔记', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('点击右下角 + 创建', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return _buildNoteCard(note);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final timeStr = DateFormat('MM/dd HH:mm').format(note.updatedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          note.title.isEmpty ? '无标题' : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
        onTap: () => _openEditor(note: note),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteDialog(note),
        ),
      ),
    );
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定删除「${note.title.isEmpty ? "无标题" : note.title}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNote(note.id);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '写点什么...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
