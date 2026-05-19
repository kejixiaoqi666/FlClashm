import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_theme.dart';

class Net77NodeStatusPage extends StatefulWidget {
  const Net77NodeStatusPage({super.key});
  @override
  State<Net77NodeStatusPage> createState() => _Net77NodeStatusPageState();
}
class _Net77NodeStatusPageState extends State<Net77NodeStatusPage> {
  late Future<List<dynamic>> _future;
  @override
  void initState() { super.initState(); _future = Net77Api.instance.nodeStatus(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.nodeStatus()); await _future; }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Row(children: [Icon(Icons.dns_outlined, color: Net77Theme.primary), SizedBox(width: 10), Text('节点状态')]), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), body: FutureBuilder<List<dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
    final nodes = snapshot.data ?? const [];
    final online = nodes.where((e) => net77Map(e)['online'] == true || net77Map(e)['status'] == 'online').length;
    return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(22, 10, 22, 22), children: [
      Wrap(spacing: 10, runSpacing: 10, children: [_chip(Icons.list_alt, '总数 ${nodes.length}', Net77Theme.primary), _chip(Icons.circle, '在线 $online', Net77Theme.online), _chip(Icons.circle, '离线 ${nodes.length - online}', Net77Theme.danger)]),
      const SizedBox(height: 20),
      if (nodes.isEmpty) const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('暂无节点状态数据'))) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.3), itemCount: nodes.length, itemBuilder: (context, index) => _node(net77Map(nodes[index]))),
    ]));
  }));
  Widget _chip(IconData icon, String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: Net77Theme.mintSoft, borderRadius: BorderRadius.circular(8), border: Border.all(color: Net77Theme.line)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(text)]));
  Widget _node(Map<String, dynamic> n) { final online = n['online'] == true || n['status'] == 'online'; return Net77Card(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(net77Text(n['flag'], '🌐'), style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Expanded(child: Text(net77Text(n['name'], '节点'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))), Icon(Icons.circle, size: 14, color: online ? Net77Theme.online : Net77Theme.danger)]), const SizedBox(height: 14), Text('倍率: x${net77Text(n['rate'], '1.0')}', style: const TextStyle(color: Net77Theme.subText)), const SizedBox(height: 8), Text('最后更新时间: ${net77Text(n['last_updated_at'])}', style: const TextStyle(color: Net77Theme.subText, fontSize: 12))])); }
}
class _Error extends StatelessWidget { final String error; final Future<void> Function() onRetry; const _Error({required this.error, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))]))); }
