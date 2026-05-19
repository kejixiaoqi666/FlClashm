import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_theme.dart';

class Net77TrafficDetailPage extends StatefulWidget { const Net77TrafficDetailPage({super.key}); @override State<Net77TrafficDetailPage> createState() => _Net77TrafficDetailPageState(); }
class _Net77TrafficDetailPageState extends State<Net77TrafficDetailPage> {
  late Future<List<dynamic>> _future;
  @override void initState() { super.initState(); _future = Net77Api.instance.trafficLogs(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.trafficLogs()); await _future; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('流量明细'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), body: FutureBuilder<List<dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
    final rows = snapshot.data ?? const [];
    return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(22, 10, 22, 22), children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Net77Theme.mint, borderRadius: BorderRadius.circular(8)), child: const Text('说明：合计流量 =（上行流量 + 下行流量）* 节点倍率')),
      const SizedBox(height: 18),
      Text('记录数 ${rows.length}'),
      const SizedBox(height: 12),
      if (rows.isEmpty) const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('暂无流量明细'))) else for (final raw in rows) ...[_card(net77Map(raw)), const SizedBox(height: 12)],
    ]));
  }));
  Widget _card(Map<String, dynamic> r) => Net77Card(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(net77Text(r['record_at_text'] ?? r['record_at']), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), Text('↑ ${net77Text(r['u_text'], net77TrafficText(r['u']))}  ↓ ${net77Text(r['d_text'], net77TrafficText(r['d']))}  合计 ${net77Text(r['total_text'], net77TrafficText(r['total']))} (${net77Text(r['server_rate'], '1.00')} ×)', style: const TextStyle(color: Net77Theme.subText))]));
}
class _Error extends StatelessWidget { final String error; final Future<void> Function() onRetry; const _Error({required this.error, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))]))); }
