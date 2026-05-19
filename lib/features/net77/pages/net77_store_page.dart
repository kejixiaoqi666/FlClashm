import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_config.dart';
import '../net77_theme.dart';
import 'net77_order_pay_page.dart';

class Net77StorePage extends StatefulWidget {
  const Net77StorePage({super.key});
  @override
  State<Net77StorePage> createState() => _Net77StorePageState();
}

class _Net77StorePageState extends State<Net77StorePage> {
  late Future<List<dynamic>> _future;
  int _tab = 0;
  bool _creating = false;
  @override
  void initState() { super.initState(); _future = Net77Api.instance.plans(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.plans()); await _future; }
  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Map<String, dynamic>? _period(Map<String, dynamic> plan) {
    final ps = net77List(plan['periods']).map(net77Map).toList();
    if (ps.isEmpty) return null;
    final monthly = ps.where((e) => net77Text(e['period'], '') == 'month').toList();
    return monthly.isNotEmpty ? monthly.first : ps.first;
  }

  List<String> _features(Map<String, dynamic> plan) {
    final content = net77Text(plan['content'], '').replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n').replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('，', '\n');
    final lines = content.split(RegExp(r'[\n;；]')).map((e) => e.trim()).where((e) => e.isNotEmpty).take(6).toList();
    if (lines.isNotEmpty) return lines;
    return [
      '每月 ${net77Text(plan['transfer_text'], '不限')} 流量',
      '最高 ${net77Text(plan['speed_limit'], '100')}M 速率',
      '解锁 Netflix / Disney+ / HBO',
      '解锁 ChatGPT / Gemini',
      '全球多个高速节点',
    ];
  }

  Future<void> _buy(Map<String, dynamic> plan) async {
    final id = int.tryParse(net77Text(plan['id'], ''));
    final period = _period(plan);
    if (id == null || period == null) { _toast('该套餐暂无可购买周期'); return; }
    setState(() => _creating = true);
    try {
      final order = await Net77Api.instance.createOrder(planId: id, period: net77Text(period['period'], 'month'));
      if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => Net77OrderPayPage(order: order)));
    } catch (e) { _toast(e.toString()); } finally { if (mounted) setState(() => _creating = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 18), children: [
    const Text('商店', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
    const SizedBox(height: 34),
    _Segment(index: _tab, onChange: (v) => setState(() => _tab = v)),
    const SizedBox(height: 26),
    FutureBuilder<List<dynamic>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
      final plans = snapshot.data ?? const [];
      if (plans.isEmpty) return const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('暂无可购买套餐')));
      return Column(children: [for (final raw in plans) ...[_PlanCard(plan: net77Map(raw), period: _period(net77Map(raw)), features: _features(net77Map(raw)), disabled: _creating, onBuy: () => _buy(net77Map(raw))), const SizedBox(height: 18)]]);
    }),
  ]))));
}

class _Segment extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  const _Segment({required this.index, required this.onChange});
  @override
  Widget build(BuildContext context) {
    final items = [const [Icons.grid_view, '全部'], const [Icons.calendar_month_outlined, '周期'], const [Icons.sync, '流量']];
    return Container(height: 48, decoration: BoxDecoration(border: Border.all(color: Net77Theme.text), borderRadius: BorderRadius.circular(24)), child: Row(children: List.generate(items.length, (i) {
      final active = i == index;
      return Expanded(child: InkWell(onTap: () => onChange(i), borderRadius: BorderRadius.circular(24), child: Container(height: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: active ? Net77Theme.mint : Colors.transparent, borderRadius: BorderRadius.circular(24)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(items[i][0] as IconData, size: 18), const SizedBox(width: 8), Text(items[i][1] as String, style: const TextStyle(fontWeight: FontWeight.w600))]))));
    })));
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic>? period;
  final List<String> features;
  final bool disabled;
  final VoidCallback onBuy;
  const _PlanCard({required this.plan, required this.period, required this.features, required this.disabled, required this.onBuy});
  @override
  Widget build(BuildContext context) {
    final price = net77Money(period?['price'] ?? plan['price']);
    return Net77Card(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(net77Text(plan['name'], '套餐'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${Net77Config.defaultCurrency}$price', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Net77Theme.primary)), const Text('/ 月付', style: TextStyle(color: Net77Theme.subText))])]),
      const SizedBox(height: 18),
      Wrap(spacing: 8, children: [if (net77Text(plan['transfer_text'], '').isNotEmpty) _Badge(text: net77Text(plan['transfer_text'])), if (net77Text(plan['speed_limit'], '').isNotEmpty) _Badge(text: '${net77Text(plan['speed_limit'])}Mbps')]),
      const SizedBox(height: 16),
      for (final f in features) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, size: 18, color: Net77Theme.online), const SizedBox(width: 8), Expanded(child: Text(f))])),
      const SizedBox(height: 12),
      FilledButton(onPressed: disabled ? null : onBuy, child: const Text('购买')),
    ]));
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Net77Theme.mintSoft, borderRadius: BorderRadius.circular(8)), child: Text(text, style: const TextStyle(color: Net77Theme.primary)));
}

class _Error extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _Error({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 80), child: Column(children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))]));
}
