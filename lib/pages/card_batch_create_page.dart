import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/software.dart';
import '../services/card_service.dart';

class CardBatchCreatePage extends StatefulWidget {
  final List<SoftwareModel> softwareList;
  const CardBatchCreatePage({super.key, required this.softwareList});
  @override
  State<CardBatchCreatePage> createState() => _CardBatchCreatePageState();
}

class _CardBatchCreatePageState extends State<CardBatchCreatePage> {
  final _cardService = CardService();
  final _countCtrl = TextEditingController(text: '10');
  final _durationCtrl = TextEditingController(text: '30');
  final _prefixCtrl = TextEditingController();
  final _unbindCtrl = TextEditingController(text: '3');
  SoftwareModel? _selectedSw;
  int _unitIdx = 1;
  bool _noLimit = false;
  bool _loading = false;
  List<String>? _keys;

  @override
  void initState() { super.initState(); if (widget.softwareList.isNotEmpty) _selectedSw = widget.softwareList.first; }

  @override
  void dispose() { _countCtrl.dispose(); _durationCtrl.dispose(); _prefixCtrl.dispose(); _unbindCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_selectedSw == null) { _toast('请选择软件'); return; }
    final count = int.tryParse(_countCtrl.text.trim()) ?? 0;
    if (count <= 0 || count > 500) { _toast('数量 1-500'); return; }
    final units = ['hour', 'day', 'permanent'];
    final unit = units[_unitIdx];
    int? dur;
    if (unit != 'permanent') { dur = int.tryParse(_durationCtrl.text.trim()) ?? 0; if (dur <= 0) { _toast('请输入时长'); return; } }
    setState(() => _loading = true);
    try {
      final resp = await _cardService.batchCreate(softwareId: _selectedSw!.id, count: count, durationUnit: unit, durationValue: dur,
        prefix: _prefixCtrl.text.trim().isEmpty ? null : _prefixCtrl.text.trim(),
        unbindLimit: _noLimit ? null : int.tryParse(_unbindCtrl.text.trim()));
      if (mounted) {
        if (resp['code'] == 0 && resp['data'] != null) {
          setState(() { _keys = List<String>.from(resp['data']['keys'] ?? []); _loading = false; });
        } else { _toast(resp['msg'] ?? '失败'); setState(() => _loading = false); }
      }
    } catch (e) { if (mounted) { _toast('网络错误'); setState(() => _loading = false); } }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    if (_keys != null) return _resultPage();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7), elevation: 0, scrolledUnderElevation: 0,
        leading: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)), onPressed: () => Navigator.pop(context)),
        title: const Text('批量生成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))), centerTitle: true,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _label('所属软件'),
        GestureDetector(
          onTap: () => showCupertinoModalPopup(context: context, builder: (ctx) => CupertinoActionSheet(
            title: const Text('选择软件'),
            actions: widget.softwareList.map((sw) => CupertinoActionSheetAction(
              onPressed: () { setState(() => _selectedSw = sw); Navigator.pop(ctx); },
              child: Text('${sw.name} (${sw.instanceId})'),
            )).toList(),
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          )),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(child: Text(_selectedSw?.name ?? '请选择', style: TextStyle(color: _selectedSw != null ? const Color(0xFF1C1C1E) : const Color(0xFFC7C7CC)))),
              const Icon(CupertinoIcons.chevron_down, size: 14, color: Color(0xFFC7C7CC)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        _label('生成数量'),
        _input(_countCtrl, '1-500', TextInputType.number),
        const SizedBox(height: 20),
        _label('卡密类型'),
        SizedBox(width: double.infinity, child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _unitIdx,
          children: const {0: Text('小时卡'), 1: Text('天卡'), 2: Text('永久卡')},
          onValueChanged: (v) => setState(() => _unitIdx = v ?? 1),
        )),
        if (_unitIdx != 2) ...[const SizedBox(height: 20), _label(_unitIdx == 0 ? '时长（小时）' : '时长（天）'), _input(_durationCtrl, _unitIdx == 0 ? '24' : '30', TextInputType.number)],
        const SizedBox(height: 20),
        _label('前缀（可选）'),
        _input(_prefixCtrl, 'VIP-', null),
        const SizedBox(height: 20),
        _label('换绑上限'),
        Row(children: [
          Expanded(child: _input(_unbindCtrl, '次数', TextInputType.number, enabled: !_noLimit)),
          const SizedBox(width: 12),
          GestureDetector(onTap: () => setState(() => _noLimit = !_noLimit), child: Row(children: [
            Icon(_noLimit ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square, color: _noLimit ? const Color(0xFF007AFF) : const Color(0xFFC7C7CC), size: 22),
            const SizedBox(width: 6),
            const Text('不限', style: TextStyle(color: Color(0xFF1C1C1E))),
          ])),
        ]),
        const SizedBox(height: 32),
        SizedBox(height: 50, child: CupertinoButton(
          color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(12),
          onPressed: _loading ? null : _create,
          child: _loading ? const CupertinoActivityIndicator(color: Colors.white) : const Text('生成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _resultPage() => Scaffold(
    backgroundColor: const Color(0xFFF2F2F7),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF2F2F7), elevation: 0, scrolledUnderElevation: 0,
      leading: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)), onPressed: () => Navigator.pop(context)),
      title: const Text('生成完成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))), centerTitle: true,
      actions: [CupertinoButton(padding: const EdgeInsets.only(right: 16), onPressed: () { Clipboard.setData(ClipboardData(text: _keys!.join('\n'))); _toast('已复制 ${_keys!.length} 张'); }, child: const Text('全部复制', style: TextStyle(color: Color(0xFF007AFF))))],
    ),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF34C759).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF34C759), size: 20),
          const SizedBox(width: 10),
          Text('成功生成 ${_keys!.length} 张卡密', style: const TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.w600)),
        ]),
      )),
      Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListView.separated(
          padding: EdgeInsets.zero, itemCount: _keys!.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E5EA)),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(child: Text(_keys![i], style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, color: Color(0xFF1C1C1E)))),
              GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: _keys![i])); _toast('已复制'); },
                child: const Icon(CupertinoIcons.doc_on_clipboard, size: 15, color: Color(0xFFC7C7CC))),
            ]),
          ),
        ),
      )),
      const SizedBox(height: 20),
    ]),
  );

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))));

  Widget _input(TextEditingController c, String hint, TextInputType? kb, {bool enabled = true}) => Container(
    height: 48,
    decoration: BoxDecoration(color: enabled ? Colors.white : const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(10)),
    child: TextField(
      controller: c, enabled: enabled, keyboardType: kb,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    ),
  );
}
