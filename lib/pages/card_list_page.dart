import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart';
import '../models/software.dart';
import '../services/card_service.dart';
import '../services/dashboard_service.dart';
import 'card_detail_page.dart';
import 'card_batch_create_page.dart';

class CardListPage extends StatefulWidget {
  const CardListPage({super.key});
  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> {
  final _cardService = CardService();
  final _dashService = DashboardService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<CardModel> _cards = [];
  List<SoftwareModel> _softwareList = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  String _statusFilter = '';
  int? _softwareFilter;
  Timer? _debounce;

  // Batch mode
  bool _batchMode = false;
  final Set<int> _selected = {};
  bool _batchLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSoftware();
    _loadCards();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _loadCards());
  }

  Future<void> _loadSoftware() async {
    _softwareList = await _dashService.getSoftwareList();
    if (mounted) setState(() {});
  }

  Future<void> _loadCards({bool refresh = true}) async {
    if (refresh) { _page = 1; _hasMore = true; }
    setState(() => _isLoading = refresh);
    try {
      final cards = await _cardService.getCards(
        page: _page, pageSize: 20,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _statusFilter.isEmpty ? null : _statusFilter,
        softwareId: _softwareFilter,
      );
      if (mounted) {
        setState(() {
          if (refresh) { _cards = cards; _selected.clear(); } else { _cards.addAll(cards); }
          _hasMore = cards.length >= 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showToast('加载失败'); }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    _page++;
    await _loadCards(refresh: false);
  }

  // ── Batch actions ──

  void _toggleBatchMode() {
    setState(() { _batchMode = !_batchMode; _selected.clear(); });
  }

  void _toggleSelect(int id) {
    setState(() { if (_selected.contains(id)) _selected.remove(id); else _selected.add(id); });
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _cards.length) { _selected.clear(); }
      else { _selected.addAll(_cards.map((c) => c.id)); }
    });
  }

  Future<void> _batchBan() async {
    if (_selected.isEmpty || _batchLoading) return;
    final confirm = await _confirm('批量封禁', '确定要封禁选中的 ${_selected.length} 张卡密吗？');
    if (confirm != true) return;
    setState(() => _batchLoading = true);
    try {
      await _cardService.batchStatus(_selected.toList(), 'banned');
      _showToast('已封禁 ${_selected.length} 张');
      _selected.clear();
      await _loadCards();
    } catch (e) { _showToast('操作失败'); }
    if (mounted) setState(() => _batchLoading = false);
  }

  Future<void> _batchUnban() async {
    if (_selected.isEmpty || _batchLoading) return;
    final confirm = await _confirm('批量启用', '确定要启用选中的 ${_selected.length} 张卡密吗？');
    if (confirm != true) return;
    setState(() => _batchLoading = true);
    try {
      await _cardService.batchStatus(_selected.toList(), 'unused');
      _showToast('已启用 ${_selected.length} 张');
      _selected.clear();
      await _loadCards();
    } catch (e) { _showToast('操作失败'); }
    if (mounted) setState(() => _batchLoading = false);
  }

  Future<void> _batchDelete() async {
    if (_selected.isEmpty || _batchLoading) return;
    final confirm = await _confirm('批量删除', '确定要删除选中的 ${_selected.length} 张卡密吗？\n删除后不可恢复！');
    if (confirm != true) return;
    setState(() => _batchLoading = true);
    try {
      await _cardService.deleteCards(_selected.toList());
      _showToast('已删除 ${_selected.length} 张');
      _selected.clear();
      await _loadCards();
    } catch (e) { _showToast('删除失败'); }
    if (mounted) setState(() => _batchLoading = false);
  }

  Future<bool?> _confirm(String title, String content) => showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title), content: Text(content),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), isDestructiveAction: true, child: const Text('确定')),
      ],
    ),
  );

  // ── Single card actions ──

  Color _statusColor(String status) {
    switch (status) {
      case 'unused': return const Color(0xFF007AFF);
      case 'used': return const Color(0xFF34C759);
      case 'expired': return const Color(0xFFFF9500);
      case 'banned': return const Color(0xFFFF3B30);
      default: return const Color(0xFF8E8E93);
    }
  }

  void _showCardActions(CardModel card) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(card.key, style: const TextStyle(fontSize: 12, fontFamily: 'Menlo')),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Clipboard.setData(ClipboardData(text: card.key)); Navigator.pop(ctx); _showToast('已复制'); },
            child: const Text('复制卡密'),
          ),
          if (card.status != 'banned')
            CupertinoActionSheetAction(
              onPressed: () async { Navigator.pop(ctx); await _cardService.batchStatus([card.id], 'banned'); _showToast('已封禁'); _loadCards(); },
              isDestructiveAction: true, child: const Text('封禁'),
            ),
          if (card.status == 'banned')
            CupertinoActionSheetAction(
              onPressed: () async { Navigator.pop(ctx); await _cardService.batchStatus([card.id], 'unused'); _showToast('已启用'); _loadCards(); },
              child: const Text('启用'),
            ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _confirm('确认删除', '删除后不可恢复，确定要删除这张卡密吗？');
              if (ok == true) { await _cardService.deleteCards([card.id]); _showToast('已删除'); _loadCards(); }
            },
            isDestructiveAction: true, child: const Text('删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ),
    );
  }

  void _showSoftwareFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择软件'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { setState(() => _softwareFilter = null); Navigator.pop(ctx); _loadCards(); },
            child: Text('全部软件', style: TextStyle(fontWeight: _softwareFilter == null ? FontWeight.w600 : FontWeight.w400)),
          ),
          ..._softwareList.map((sw) => CupertinoActionSheetAction(
            onPressed: () { setState(() => _softwareFilter = sw.id); Navigator.pop(ctx); _loadCards(); },
            child: Text(sw.name, style: TextStyle(fontWeight: _softwareFilter == sw.id ? FontWeight.w600 : FontWeight.w400)),
          )),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String get _softwareFilterLabel {
    if (_softwareFilter == null) return '全部软件';
    final sw = _softwareList.where((s) => s.id == _softwareFilter);
    return sw.isNotEmpty ? sw.first.name : '全部软件';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                Expanded(child: _batchMode
                  ? Text('已选 ${_selected.length} 张', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)))
                  : const Text('卡密管理', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                ),
                if (_batchMode) ...[
                  CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: _selectAll,
                    child: Text(_selected.length == _cards.length ? '取消全选' : '全选', style: const TextStyle(fontSize: 14, color: Color(0xFF007AFF)))),
                  CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: _toggleBatchMode,
                    child: const Text('取消', style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)))),
                ] else ...[
                  CupertinoButton(padding: EdgeInsets.zero, onPressed: _toggleBatchMode,
                    child: const Icon(CupertinoIcons.checkmark_circle, color: Color(0xFF007AFF), size: 24)),
                  const SizedBox(width: 6),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await Navigator.push(context, CupertinoPageRoute(builder: (_) => CardBatchCreatePage(softwareList: _softwareList)));
                      _loadCards();
                    },
                    child: Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(CupertinoIcons.add, color: Colors.white, size: 20)),
                  ),
                ],
              ]),
            ),

            // Search
            if (!_batchMode) Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 38,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    hintText: '搜索卡密', hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 15),
                    prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: Color(0xFF8E8E93)),
                    suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(onTap: () { _searchController.clear(); _loadCards(); },
                          child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: Color(0xFFC7C7CC)))
                      : null,
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // Filter row
            if (!_batchMode) Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: _showSoftwareFilter,
                  child: Container(
                    height: 30, padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _softwareFilter != null ? const Color(0xFF007AFF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(CupertinoIcons.cube_box, size: 13, color: _softwareFilter != null ? Colors.white : const Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      Text(_softwareFilterLabel, style: TextStyle(fontSize: 12, color: _softwareFilter != null ? Colors.white : const Color(0xFF8E8E93))),
                      const SizedBox(width: 2),
                      Icon(CupertinoIcons.chevron_down, size: 10, color: _softwareFilter != null ? Colors.white : const Color(0xFFC7C7CC)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${_cards.length} 条', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ]),
            ),

            // Status filter
            if (!_batchMode) Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                height: 32,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(children: ['', 'unused', 'used', 'expired', 'banned'].map((s) {
                  final labels = {'': '全部', 'unused': '未使用', 'used': '已使用', 'expired': '已过期', 'banned': '封禁'};
                  final isActive = _statusFilter == s;
                  return Expanded(child: GestureDetector(
                    onTap: () { setState(() => _statusFilter = s); _loadCards(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF007AFF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(labels[s]!, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : const Color(0xFF8E8E93))),
                    ),
                  ));
                }).toList()),
              ),
            ),

            // Card list
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _cards.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(CupertinoIcons.creditcard, size: 48, color: const Color(0xFF8E8E93).withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text('暂无卡密', style: TextStyle(color: Color(0xFF8E8E93))),
                        ]))
                      : RefreshIndicator(
                          color: const Color(0xFF007AFF),
                          onRefresh: () => _loadCards(refresh: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(16, 0, 16, _batchMode ? 80 : 100),
                            itemCount: _cards.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _cards.length) {
                                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CupertinoActivityIndicator()));
                              }
                              final card = _cards[i];
                              final isFirst = i == 0;
                              final isLast = i == _cards.length - 1 && !_hasMore;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isFirst ? 12 : 0),
                                    topRight: Radius.circular(isFirst ? 12 : 0),
                                    bottomLeft: Radius.circular(isLast ? 12 : 0),
                                    bottomRight: Radius.circular(isLast ? 12 : 0),
                                  ),
                                ),
                                child: Column(children: [
                                  _buildCardTile(card),
                                  if (!isLast) Divider(height: 1, indent: _batchMode ? 56 : 36, color: const Color(0xFFE5E5EA)),
                                ]),
                              );
                            },
                          ),
                        ),
            ),
          ]),

          // Batch action bar
          if (_batchMode && _selected.isNotEmpty)
            Positioned(
              left: 16, right: 16, bottom: 100,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: _batchLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _batchBtn(CupertinoIcons.nosign, '封禁', const Color(0xFFFF3B30), _batchBan),
                      Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                      _batchBtn(CupertinoIcons.checkmark_circle, '启用', const Color(0xFF34C759), _batchUnban),
                      Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                      _batchBtn(CupertinoIcons.trash, '删除', const Color(0xFFFF3B30), _batchDelete),
                    ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _batchBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildCardTile(CardModel card) {
    final isSelected = _selected.contains(card.id);
    return GestureDetector(
      onTap: _batchMode
          ? () => _toggleSelect(card.id)
          : () async { await Navigator.push(context, CupertinoPageRoute(builder: (_) => CardDetailPage(card: card))); _loadCards(); },
      onLongPress: _batchMode ? null : () => _showCardActions(card),
      child: Container(
        color: isSelected && _batchMode ? const Color(0xFF007AFF).withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          if (_batchMode) ...[
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              size: 22,
              color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFC7C7CC),
            ),
            const SizedBox(width: 12),
          ],
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(card.status), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.key, style: const TextStyle(fontSize: 14, fontFamily: 'Menlo', fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${card.softwareName ?? ""}  ${card.typeLabel}', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor(card.status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(card.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(card.status))),
          ),
          if (!_batchMode) ...[
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFC7C7CC)),
          ],
        ]),
      ),
    );
  }
}
