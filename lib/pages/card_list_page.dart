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
  List<CardModel> _cards = [];
  List<SoftwareModel> _softwareList = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  String _statusFilter = '';

  @override
  void initState() { super.initState(); _loadSoftware(); _loadCards(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadSoftware() async {
    _softwareList = await _dashService.getSoftwareList();
    if (mounted) setState(() {});
  }

  Future<void> _loadCards({bool refresh = true}) async {
    if (refresh) { _page = 1; _hasMore = true; }
    setState(() => _isLoading = refresh);
    final cards = await _cardService.getCards(
      page: _page, pageSize: 20,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    if (mounted) {
      setState(() {
        if (refresh) _cards = cards; else _cards.addAll(cards);
        _hasMore = cards.length >= 20; _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    _page++; await _loadCards(refresh: false);
  }

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
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(children: [
              const Expanded(child: Text('卡密管理', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)))),
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
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 38,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _loadCards(),
                style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
                decoration: InputDecoration(
                  hintText: '搜索卡密', hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 15),
                  prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: Color(0xFF8E8E93)),
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 32,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(children: ['', 'unused', 'used', 'banned'].map((s) {
                final labels = {'': '全部', 'unused': '未使用', 'used': '已使用', 'banned': '封禁'};
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
                    child: Text(labels[s]!, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : const Color(0xFF8E8E93))),
                  ),
                ));
              }).toList()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _cards.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(CupertinoIcons.creditcard, size: 48, color: const Color(0xFF8E8E93).withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('暂无卡密', style: TextStyle(color: Color(0xFF8E8E93))),
                      ]))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (s) { if (s.metrics.pixels >= s.metrics.maxScrollExtent - 100) _loadMore(); return false; },
                        child: RefreshIndicator(
                          color: const Color(0xFF007AFF),
                          onRefresh: () => _loadCards(refresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 1,
                            itemBuilder: (_, __) => Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(children: List.generate(_cards.length * 2 - 1, (i) {
                                if (i.isOdd) return const Divider(height: 1, indent: 36, color: Color(0xFFE5E5EA));
                                return _buildCardTile(_cards[i ~/ 2]);
                              })),
                            ),
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCardTile(CardModel card) {
    return GestureDetector(
      onTap: () async { await Navigator.push(context, CupertinoPageRoute(builder: (_) => CardDetailPage(card: card))); _loadCards(); },
      onLongPress: () => _showCardActions(card),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
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
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFC7C7CC)),
        ]),
      ),
    );
  }
}
