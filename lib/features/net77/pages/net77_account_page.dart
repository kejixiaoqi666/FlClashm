import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../net77_api.dart';
import '../net77_config.dart';
import '../net77_theme.dart';
import 'net77_node_status_page.dart';
import 'net77_order_list_page.dart';
import 'net77_ticket_page.dart';
import 'net77_traffic_detail_page.dart';

class Net77AccountPage extends StatefulWidget {
  final Future<void> Function() onLogout;
  const Net77AccountPage({super.key, required this.onLogout});
  @override
  State<Net77AccountPage> createState() => _Net77AccountPageState();
}

class _Net77AccountPageState extends State<Net77AccountPage> {
  late Future<Map<String, dynamic>> _future;
  bool _auto = false;
  bool _expire = true;
  bool _traffic = true;
  @override
  void initState() { super.initState(); _future = Net77Api.instance.dashboard(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.dashboard()); await _future; }
  Future<void> _openUrl(String? url) async { if (url == null || url.isEmpty) return; final uri = Uri.tryParse(url); if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication); }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: FutureBuilder<Map<String, dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
    final data = snapshot.data ?? <String, dynamic>{};
    final user = net77Map(data['user']);
    final links = net77Map(data['links']);
    return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 18), children: [
      const Text('账号', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
      const SizedBox(height: 22),
      _header(user),
      const _Label('账户设置'),
      Net77Card(padding: EdgeInsets.zero, child: Column(children: [_switch(Icons.sync, '自动续费', _auto, (v) => setState(() => _auto = v)), _switch(Icons.mail_outline, '到期邮件提醒', _expire, (v) => setState(() => _expire = v)), _switch(Icons.notifications_none, '流量邮件提醒', _traffic, (v) => setState(() => _traffic = v))])),
      const _Label('更多操作'),
      Net77Card(padding: EdgeInsets.zero, child: Column(children: [_action(Icons.lock_outline, '修改密码', () => _openUrl(links['user_center_url']?.toString())), const Divider(height: 1), _action(Icons.card_giftcard_outlined, '礼品卡兑换', () => _openUrl(links['user_center_url']?.toString()))])),
      const _Label('快捷入口'),
      GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55, children: [
        _quick(Icons.card_giftcard, '邀请返利', const Color(0xFFFFF4D8), () => _openUrl(links['user_center_url']?.toString())),
        _quick(Icons.dns_outlined, '节点状态', const Color(0xFFE3F6F2), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Net77NodeStatusPage()))),
        _quick(Icons.bar_chart, '流量明细', const Color(0xFFEAF3FF), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Net77TrafficDetailPage()))),
        _quick(Icons.receipt_long_outlined, '订单', const Color(0xFFF5EAFE), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Net77OrderListPage()))),
        _quick(Icons.support_agent, '我的工单', const Color(0xFFEFF4F7), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Net77TicketPage()))),
        _quick(Icons.language, '官网', const Color(0xFFE9F8EA), () => _openUrl(links['official_url']?.toString())),
      ]),
    ]));
  })));

  Widget _header(Map<String, dynamic> user) { final email = net77Text(user['email'], '未登录'); final name = email.contains('@') ? email.split('@').first : Net77Config.appDisplayName; return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF8BD8CB), Color(0xFFE4F7EF)])), child: Row(children: [const CircleAvatar(radius: 32, backgroundColor: Color(0x2A007866), child: Icon(Icons.person, color: Net77Theme.primary, size: 34)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(email), const SizedBox(height: 8), Row(children: [Text('¥${net77Money(user['balance'])}', style: const TextStyle(color: Net77Theme.primary, fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(width: 12), TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Net77OrderListPage())), child: const Text('充值'))])])), TextButton(onPressed: widget.onLogout, child: const Text('退出'))])); }
  Widget _switch(IconData icon, String title, bool value, ValueChanged<bool> onChanged) => Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), child: Row(children: [Icon(icon, color: Net77Theme.subText), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(fontSize: 16))), Switch(value: value, onChanged: onChanged, activeColor: Net77Theme.primary)]));
  Widget _action(IconData icon, String title, VoidCallback onTap) => ListTile(leading: Icon(icon, color: Net77Theme.subText), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  Widget _quick(IconData icon, String title, Color color, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: Net77Theme.primary), const SizedBox(width: 6), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)), const Icon(Icons.chevron_right, size: 16)])));
}

class _Label extends StatelessWidget { final String text; const _Label(this.text); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4), child: Text(text, style: const TextStyle(color: Net77Theme.subText))); }
class _Error extends StatelessWidget { final String error; final Future<void> Function() onRetry; const _Error({required this.error, required this.onRetry}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))]))); }
