import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_theme.dart';

class Net77TicketPage extends StatefulWidget { const Net77TicketPage({super.key}); @override State<Net77TicketPage> createState() => _Net77TicketPageState(); }
class _Net77TicketPageState extends State<Net77TicketPage> {
  late Future<List<dynamic>> _future;
  @override void initState() { super.initState(); _future = Net77Api.instance.tickets(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.tickets()); await _future; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('我的工单'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), floatingActionButton: FloatingActionButton(backgroundColor: Net77Theme.primary, foregroundColor: Colors.white, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新建工单可先在用户中心完成'))), child: const Icon(Icons.add)), body: FutureBuilder<List<dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
    final tickets = snapshot.data ?? const [];
    return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(22, 10, 22, 22), children: [
      Text('工单数 ${tickets.length}'),
      const SizedBox(height: 12),
      if (tickets.isEmpty) const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('暂无工单'))) else for (final raw in tickets) ...[_card(net77Map(raw)), const SizedBox(height: 12)],
    ]));
  }));
  Widget _card(Map<String, dynamic> t) => Net77Card(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(net77Text(t['subject'] ?? t['title'], '工单'), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('${net77Text(t['status_text'])} · ${net77Text(t['level_text'])} · ${net77Text(t['updated_at'] ?? t['created_at'])}', style: const TextStyle(color: Net77Theme.subText))])), const Icon(Icons.chevron_right)]));
}
class _Error extends StatelessWidget { final String error; final Future<void> Function() onRetry; const _Error({required this.error, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))]))); }
