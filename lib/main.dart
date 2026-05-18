import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

// ==================== 颜色配置 ====================

const List<Color> noteColors = [
  Color(0xFFFFF9C4),
  Color(0xFFFFCCBC),
  Color(0xFFC8E6C9),
  Color(0xFFB3E5FC),
  Color(0xFFE1BEE7),
  Color(0xFFFFE0B2),
  Color(0xFFD1C4E9),
  Color(0xFFF0F4C3),
];

// ==================== App ====================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记事本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6ABF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6ABF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const NoteListPage(),
    );
  }
}

// ==================== Note 模型 ====================

class Note {
  String id;
  String title;
  String content;
  int colorIndex;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.colorIndex = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'colorIndex': colorIndex,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        colorIndex: json['colorIndex'] ?? 0,
        isPinned: json['isPinned'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

// ==================== 笔记列表页 ====================

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList('notes') ?? [];
    setState(() {
      _notes = notesJson
          .map((e) => Note.fromJson(jsonDecode(e)))
          .toList();
      _sortNotes();
      _filteredNotes = List.from(_notes);
    });
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = _notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = List.from(_notes);
      } else {
        _filteredNotes = _notes.where((n) {
          return n.title.toLowerCase().contains(query.toLowerCase()) ||
              n.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteNote(String id) async {
    setState(() {
      _notes.removeWhere((n) => n.id == id);
      _filteredNotes.removeWhere((n) => n.id == id);
    });
    await _saveNotes();
  }

  Future<void> _togglePin(Note note) async {
    setState(() {
      note.isPinned = !note.isPinned;
      _sortNotes();
      _filteredNotes = List.from(_notes);
    });
    await _saveNotes();
  }

  void _openEditor({Note? note}) async {
    final result = await Navigator.push<Note>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => NoteEditorPage(note: note),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (result != null) {
      setState(() {
        _notes.removeWhere((n) => n.id == result.id);
        _notes.add(result);
        _sortNotes();
        _filteredNotes = List.from(_notes);
      });
      await _saveNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部问候 + 搜索
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_notes.length} 条笔记',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _isGridView = !_isGridView);
                          },
                          icon: Icon(
                            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 搜索栏
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterNotes,
                        onTap: () => setState(() => _isSearching = true),
                        decoration: InputDecoration(
                          hintText: '搜索笔记...',
                          prefixIcon: Icon(Icons.search, color: cs.onSurface.withOpacity(0.4)),
                          suffixIcon: _isSearching
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterNotes('');
                                    FocusScope.of(context).unfocus();
                                    setState(() => _isSearching = false);
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 置顶区域标题
            if (_filteredNotes.any((n) => n.isPinned))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 20, 4),
                  child: Text(
                    '置顶',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            // 置顶笔记
            if (_filteredNotes.any((n) => n.isPinned))
              _buildNoteGrid(_filteredNotes.where((n) => n.isPinned).toList()),

            // 其他区域标题
            if (_filteredNotes.any((n) => n.isPinned) && _filteredNotes.any((n) => !n.isPinned))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 20, 4),
                  child: Text(
                    '其他',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            // 普通笔记
            _filteredNotes.any((n) => n.isPinned)
                ? _buildNoteGrid(_filteredNotes.where((n) => !n.isPinned).toList())
                : _buildNoteGrid(_filteredNotes),

            // 空状态
            if (_filteredNotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 72, color: cs.primary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty ? '没有找到相关笔记' : '还没有笔记',
                        style: TextStyle(fontSize: 18, color: cs.onSurface.withOpacity(0.4)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isNotEmpty ? '试试其他关键词' : '点击下方按钮开始创建',
                        style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建'),
        elevation: 2,
      ),
    );
  }

  Widget _buildNoteGrid(List<Note> notes) {
    if (notes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildNoteCard(notes[index]),
            childCount: notes.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildNoteCard(notes[index]),
          ),
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = noteColors[note.colorIndex % noteColors.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? bgColor.withOpacity(0.15) : bgColor;
    final timeStr = _formatTime(note.updatedAt);

    return GestureDetector(
      onTap: () => _openEditor(note: note),
      onLongPress: () => _showNoteOptions(note),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? bgColor.withOpacity(0.3) : bgColor.withOpacity(0.6),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                if (note.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin_rounded, size: 14, color: cs.primary),
                  ),
                Expanded(
                  child: Text(
                    note.title.isEmpty ? '无标题' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 内容预览
            Expanded(
              child: Text(
                note.content.isEmpty ? '暂无内容' : note.content,
                maxLines: _isGridView ? 6 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 底部时间
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return DateFormat('MM月dd日 HH:mm').format(dt);
  }

  void _showNoteOptions(Note note) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: cs.primary,
                ),
                title: Text(note.isPinned ? '取消置顶' : '置顶'),
                onTap: () {
                  Navigator.pop(ctx);
                  _togglePin(note);
                },
              ),
              // 颜色选择
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: cs.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 16),
                    ...List.generate(noteColors.length, (i) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            note.colorIndex = i;
                          });
                          _saveNotes();
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: noteColors[i],
                            shape: BoxShape.circle,
                            border: note.colorIndex == i
                                ? Border.all(color: cs.primary, width: 2.5)
                                : Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteDialog(note);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除笔记'),
        content: Text('确定删除「${note.title.isEmpty ? "无标题" : note.title}」？\n此操作无法撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNote(note.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ==================== 笔记编辑页 ====================

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late int _colorIndex;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _colorIndex = widget.note?.colorIndex ?? 0;
    _wordCount = _contentController.text.length;
    _contentController.addListener(() {
      setState(() => _wordCount = _contentController.text.length);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      colorIndex: _colorIndex,
      isPinned: widget.note?.isPinned ?? false,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = noteColors[_colorIndex % noteColors.length];
    final scaffoldBg = isDark ? cs.surface : bgColor.withOpacity(0.3);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _save,
        ),
        actions: [
          // 颜色选择
          PopupMenuButton<int>(
            icon: Icon(Icons.palette_outlined, color: cs.onSurface.withOpacity(0.7)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Wrap(
                  spacing: 8,
                  children: List.generate(noteColors.length, (i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _colorIndex = i);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: noteColors[i],
                          shape: BoxShape.circle,
                          border: _colorIndex == i
                              ? Border.all(color: cs.primary, width: 2.5)
                              : Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          FilledButton.tonal(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('保存'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '标题',
                      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3)),
                      border: InputBorder.none,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                      decoration: InputDecoration(
                        hintText: '写点什么...',
                        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.25)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部状态栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.5),
              border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields_rounded, size: 16, color: cs.onSurface.withOpacity(0.35)),
                const SizedBox(width: 6),
                Text(
                  '$_wordCount 字',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.35)),
                ),
                const Spacer(),
                if (widget.note != null)
                  Text(
                    '创建于 ${DateFormat('yyyy/MM/dd').format(widget.note!.createdAt)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.25)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
