import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_config.dart';
import '../net77_theme.dart';
import 'net77_order_pay_page.dart';

class Net77OrderListPage extends StatefulWidget { const Net77OrderListPage({super.key}); @override State<Net77OrderListPage> createState() => _Net77OrderListPageState(); }
class _Net77OrderListPageState extends State<Net77OrderListPage> {
  late Future<List<dynamic>> _future;
  @override void initState() { super.initState(); _future = Net77Api.instance.orders(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.orders()); await _future; }
  Future<void> _open(Map<String, dynamic> order) async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => Net77OrderPayPage(order: order))); await _refresh(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('订单'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), body: FutureBuilder<List<dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
    final orders = snapshot.data ?? const [];
    if (orders.isEmpty) return const Center(child: Text('暂无订单'));
    return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(padding: const EdgeInsets.fromLTRB(22, 10, 22, 22), itemBuilder: (context, i) => _card(net77Map(orders[i])), separatorBuilder: (_, __) => const SizedBox(height: 12), itemCount: orders.length));
  }));
  Widget _card(Map<String, dynamic> o) { final plan = net77Map(o['plan']); return Net77Card(onTap: () => _open(o), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(net77Text(plan['name'] ?? o['plan_name'] ?? o['trade_no'], '订单'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('${net77DateOnly(o['created_at'])} · ${net77Text(o['period'])} · ${net77Text(o['status_text'])}', style: const TextStyle(color: Net77Theme.subText))])), Text('${Net77Config.defaultCurrency}${net77Money(o['total_amount'] ?? o['amount'])}') ])); }
}
class _Error extends StatelessWidget { final String error; final Future<void> Function() onRetry; const _Error({required this.error, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))]))); }
