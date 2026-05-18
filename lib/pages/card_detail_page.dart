import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/card.dart';
import '../services/card_service.dart';

class CardDetailPage extends StatefulWidget {
  final CardModel card;
  const CardDetailPage({super.key, required this.card});
  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  final _cardService = CardService();
  late CardModel _card;
  @override
  void initState() { super.initState(); _card = widget.card; }

  void _showToast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  Future<void> _toggleBan() async {
    final isBanned = _card.status == 'banned';
    final label = isBanned ? '启用' : '封禁';
    final confirm = await showCupertinoDialog<bool>(context: context, builder: (ctx) => CupertinoAlertDialog(
      title: Text('确认$label'), content: Text('确定要${label}这张卡密吗？'),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), isDestructiveAction: !isBanned, child: Text(label)),
      ],
    ));
    if (confirm == true) {
      await _cardService.batchStatus([_card.id], isBanned ? 'unused' : 'banned');
      _showToast('已$label');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _resetHwid() async {
    final confirm = await showCupertinoDialog<bool>(context: context, builder: (ctx) => CupertinoAlertDialog(
      title: const Text('重置机器码'), content: const Text('确定要重置该卡密的机器码绑定吗？'),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), isDestructiveAction: true, child: const Text('重置')),
      ],
    ));
    if (confirm == true) {
      await _cardService.resetHwid(_card.id);
      _showToast('机器码已重置');
      if (mounted) Navigator.pop(context);
    }
  }

  String _fmt(DateTime? dt) => dt == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Color get _statusColor {
    switch (_card.status) {
      case 'unused': return const Color(0xFF007AFF);
      case 'used': return const Color(0xFF34C759);
      case 'banned': return const Color(0xFFFF3B30);
      default: return const Color(0xFFFF9500);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7), elevation: 0, scrolledUnderElevation: 0,
        leading: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)), onPressed: () => Navigator.pop(context)),
        title: const Text('卡密详情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))), centerTitle: true,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(CupertinoIcons.creditcard_fill, color: _statusColor, size: 24)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_card.statusLabel, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _statusColor)),
              const SizedBox(height: 2),
              Text('${_card.softwareName ?? ""}  ${_card.typeLabel}', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _section([
          _row('卡密 Key', _card.key, mono: true, copyable: true),
          _row('机器码', _card.hwid ?? '-', mono: true, copyable: _card.hwid != null && _card.hwid!.isNotEmpty),
        ]),
        const SizedBox(height: 16),
        _section([
          _row('类型', _card.typeLabel),
          _row('到期时间', _card.expireDate != null ? _fmt(_card.expireDate) : '永久'),
          _row('换绑次数', _card.unbindLimit != null ? '${_card.unbindCount} / ${_card.unbindLimit}' : '不限'),
          _row('首次 IP', _card.firstIp ?? '-', mono: true),
          _row('最后 IP', _card.lastIp ?? '-', mono: true),
          _row('激活时间', _fmt(_card.activatedAt)),
          _row('最后在线', _fmt(_card.lastSeen)),
          if (_card.remarks != null && _card.remarks!.isNotEmpty) _row('备注', _card.remarks!),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          if (_card.hwid != null && _card.hwid!.isNotEmpty) ...[
            Expanded(child: SizedBox(height: 48, child: CupertinoButton(color: const Color(0xFFFF9500), borderRadius: BorderRadius.circular(12), padding: EdgeInsets.zero, onPressed: _resetHwid, child: const Text('重置机器码', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))))),
            const SizedBox(width: 12),
          ],
          Expanded(child: SizedBox(height: 48, child: CupertinoButton(
            color: _card.status == 'banned' ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
            borderRadius: BorderRadius.circular(12), padding: EdgeInsets.zero, onPressed: _toggleBan,
            child: Text(_card.status == 'banned' ? '启用' : '封禁', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))))),
        ]),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _section(List<Widget> rows) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(children: List.generate(rows.length * 2 - 1, (i) {
      if (i.isOdd) return const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E5EA));
      return rows[i ~/ 2];
    })),
  );

  Widget _row(String label, String value, {bool mono = false, bool copyable = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
      const Spacer(),
      Flexible(child: Text(value, style: TextStyle(fontSize: 13, color: const Color(0xFF1C1C1E), fontFamily: mono ? 'Menlo' : null), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
      if (copyable) ...[const SizedBox(width: 8), GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: value)); _showToast('已复制'); }, child: const Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: Color(0xFFC7C7CC)))],
    ]),
  );
}
