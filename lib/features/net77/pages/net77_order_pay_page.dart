import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../net77_api.dart';
import '../net77_config.dart';
import '../net77_theme.dart';

class Net77OrderPayPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const Net77OrderPayPage({super.key, required this.order});
  @override
  State<Net77OrderPayPage> createState() => _Net77OrderPayPageState();
}

class _Net77OrderPayPageState extends State<Net77OrderPayPage> {
  late Map<String, dynamic> _order;
  late Future<List<dynamic>> _methodsFuture;
  int? _method;
  bool _loading = false;
  @override
  void initState() { super.initState(); _order = widget.order; _methodsFuture = Net77Api.instance.paymentMethods(); }
  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  Future<void> _refresh() async { final no = net77Text(_order['trade_no'], ''); if (no.isEmpty) return; try { final d = await Net77Api.instance.orderDetail(no); setState(() => _order = d); } catch (e) { _toast(e.toString()); } }
  Future<void> _pay() async { final no = net77Text(_order['trade_no'], ''); if (_method == null) { _toast('请选择支付方式'); return; } setState(() => _loading = true); try { final r = await Net77Api.instance.checkoutOrder(tradeNo: no, method: _method!); final url = r['pay_url']?.toString(); if (url != null && url.isNotEmpty) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); await _refresh(); } catch (e) { _toast(e.toString()); } finally { if (mounted) setState(() => _loading = false); } }
  Future<void> _cancel() async { final no = net77Text(_order['trade_no'], ''); if (no.isEmpty) return; setState(() => _loading = true); try { await Net77Api.instance.cancelOrder(no); _toast('订单已取消'); await _refresh(); } catch (e) { _toast(e.toString()); } finally { if (mounted) setState(() => _loading = false); } }

  @override
  Widget build(BuildContext context) {
    final plan = net77Map(_order['plan']);
    final price = net77Money(_order['total_amount'] ?? _order['amount']);
    final fee = net77Money(_order['handling_amount']);
    final total = net77Number(_order['total_amount']) + net77Number(_order['handling_amount']);
    return Scaffold(appBar: AppBar(title: const Text('订单支付'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), body: FutureBuilder<List<dynamic>>(future: _methodsFuture, builder: (context, snapshot) {
      final methods = snapshot.data ?? const [];
      if (_method == null && methods.isNotEmpty) _method = int.tryParse(net77Text(net77Map(methods.first)['id'], ''));
      return ListView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 28), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF006F65), Color(0xFF0B806E)]), borderRadius: BorderRadius.circular(6)), child: Column(children: [_summary('订单号', net77Text(_order['trade_no']), light: true), const SizedBox(height: 16), _summary('状态', net77Text(_order['status_text'], '待支付'), light: true)])),
        const SizedBox(height: 14),
        Net77Card(child: GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.7, children: [_info('下单时间', net77Text(_order['created_at'])), _info('套餐名称', net77Text(plan['name'] ?? _order['plan_name'], '套餐')), _info('套餐周期', net77Text(_order['period'])), _info('套餐流量', net77Text(plan['transfer_text'])), _info('带宽速率', '${net77Text(plan['speed_limit'], '0')} Mbps'), _info('原价', '${Net77Config.defaultCurrency}$price') ])),
        const SizedBox(height: 14),
        Net77Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('选择支付方式', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), const SizedBox(height: 12), if (snapshot.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()) else if (methods.isEmpty) const Text('暂无可用支付方式') else for (final m in methods) _methodTile(net77Map(m))])),
        const SizedBox(height: 18),
        Net77Card(child: Column(children: [_summary('原价', '${Net77Config.defaultCurrency}$price'), const SizedBox(height: 10), _summary('手续费', '+${Net77Config.defaultCurrency}$fee') ])),
        const SizedBox(height: 16),
        FilledButton(onPressed: _loading ? null : _pay, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text('立即支付 ${Net77Config.defaultCurrency}${total <= 0 ? price : total.toStringAsFixed(2)}')),
        TextButton(onPressed: _loading ? null : _cancel, child: const Text('取消订单', style: TextStyle(color: Color(0xFFB23A48)))),
      ]);
    }));
  }

  Widget _methodTile(Map<String, dynamic> m) { final id = int.tryParse(net77Text(m['id'], '')); final selected = id == _method; return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: () => setState(() => _method = id), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(color: selected ? Net77Theme.mintSoft : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? Net77Theme.primary : Net77Theme.line)), child: Row(children: [Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? Net77Theme.primary : Net77Theme.text), const SizedBox(width: 12), Expanded(child: Text(net77Text(m['name'] ?? m['payment'], '支付方式'), style: const TextStyle(fontWeight: FontWeight.w600)))])))); }
  Widget _info(String a, String b) => Padding(padding: const EdgeInsets.all(4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(a, style: const TextStyle(color: Net77Theme.subText, fontSize: 12)), const SizedBox(height: 6), Text(b, style: const TextStyle(fontWeight: FontWeight.w600))]));
  Widget _summary(String a, String b, {bool light = false}) => Row(children: [Text(a, style: TextStyle(color: light ? Colors.white70 : Net77Theme.subText)), const Spacer(), Flexible(child: Text(b, textAlign: TextAlign.right, style: TextStyle(color: light ? Colors.white : Net77Theme.text, fontWeight: FontWeight.w600)))]);
}
