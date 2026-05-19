import 'package:fl_clash/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../net77_api.dart';
import '../net77_theme.dart';
import 'net77_node_status_page.dart';

class Net77HomePage extends StatefulWidget {
  final VoidCallback onEnterClient;
  final VoidCallback onOpenStore;
  const Net77HomePage({super.key, required this.onEnterClient, required this.onOpenStore});
  @override
  State<Net77HomePage> createState() => _Net77HomePageState();
}

class _Net77HomePageState extends State<Net77HomePage> {
  late Future<Map<String, dynamic>> _future;
  bool _submitting = false;
  @override
  void initState() { super.initState(); _future = Net77Api.instance.dashboard(); }
  Future<void> _refresh() async { setState(() => _future = Net77Api.instance.dashboard()); await _future; }
  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  Future<void> _importSubscribe() async {
    setState(() => _submitting = true);
    try {
      final data = await Net77Api.instance.subscribe();
      final url = data['subscribe_url']?.toString();
      if (url == null || url.isEmpty) { _toast('订阅地址为空，请确认账号套餐是否有效'); return; }
      await Clipboard.setData(ClipboardData(text: url));
      await appController.addProfileFormURL(url);
      _toast('订阅已导入，同时已复制到剪贴板');
      widget.onEnterClient();
    } catch (e) { _toast(e.toString()); } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _Error(error: snapshot.error.toString(), onRetry: _refresh);
            final data = snapshot.data ?? <String, dynamic>{};
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                children: [
                  Row(children: [const Text('首页', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)), const Spacer(), const Icon(Icons.circle, color: Net77Theme.online, size: 14), const SizedBox(width: 18), IconButton(onPressed: widget.onEnterClient, icon: const Icon(Icons.edit))]),
                  const SizedBox(height: 22),
                  _PlanCard(data: data, onUpgrade: widget.onOpenStore),
                  const SizedBox(height: 16),
                  Net77Card(onTap: widget.onEnterClient, child: const Row(children: [Icon(Icons.account_tree_outlined), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('节点选择', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('GLOBAL · DIRECT')])), Icon(Icons.chevron_right)])),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _RuntimeCard(loading: _submitting, onStart: _submitting ? null : _importSubscribe)),
                    const SizedBox(width: 14),
                    Expanded(child: _ModeCard(onTap: widget.onEnterClient)),
                  ]),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _TrafficCard(data: data)),
                    const SizedBox(width: 14),
                    Expanded(child: _NetworkCard(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Net77NodeStatusPage())))),
                  ]),
                  const SizedBox(height: 16),
                  Net77Card(onTap: widget.onEnterClient, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.devices_outlined), SizedBox(width: 8), Text('内网 IP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]), SizedBox(height: 12), Text('10.0.2.16', style: TextStyle(fontSize: 18, letterSpacing: 1.2))])),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUpgrade;
  const _PlanCard({required this.data, required this.onUpgrade});
  @override
  Widget build(BuildContext context) {
    final user = net77Map(data['user']);
    final plan = net77Map(data['plan']);
    final traffic = net77Map(data['traffic']);
    final percent = (net77Number(traffic['percent']) / 100).clamp(0, 1).toDouble();
    return Net77Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.desktop_windows_outlined), const SizedBox(width: 8), const Text('套餐信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: onUpgrade, style: TextButton.styleFrom(backgroundColor: Net77Theme.mint, foregroundColor: Net77Theme.primary), child: const Text('升级套餐'))]),
      Text(net77Text(plan['name'], '暂无套餐'), style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: percent, minHeight: 8, backgroundColor: Net77Theme.mintSoft, color: Net77Theme.primary)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: Text('${net77Text(traffic['used_text'], '0 B')} / ${net77Text(traffic['total_text'], '0 B')}')), Text('到期：${net77DateOnly(plan['expired_at'] ?? user['expired_at'])}')]),
      const SizedBox(height: 4),
      Text('流量重置日：${net77Text(data['reset_day'] ?? traffic['next_reset_at'], '每月0日')}', style: const TextStyle(color: Net77Theme.subText)),
    ]));
  }
}

class _RuntimeCard extends StatelessWidget {
  final bool loading;
  final VoidCallback? onStart;
  const _RuntimeCard({required this.loading, required this.onStart});
  @override
  Widget build(BuildContext context) => Net77Card(onTap: onStart, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.power_settings_new), SizedBox(width: 8), Text('启动时间', style: TextStyle(fontWeight: FontWeight.w600))]), const SizedBox(height: 18), Row(children: [loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.pause, color: Net77Theme.primary), const SizedBox(width: 12), const Text('00:00:00', style: TextStyle(fontSize: 18))]), const SizedBox(height: 8), const Text('点击导入订阅', style: TextStyle(color: Net77Theme.subText))]));
}

class _ModeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ModeCard({required this.onTap});
  @override
  Widget build(BuildContext context) => Net77Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.account_tree_outlined), SizedBox(width: 8), Text('出站模式', style: TextStyle(fontWeight: FontWeight.w600))]), _radio('规则', false), _radio('全局', true), _radio('直连', false)]));
  Widget _radio(String text, bool selected) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? Net77Theme.primary : Net77Theme.subText), const SizedBox(width: 8), Text(text)])));
}

class _TrafficCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TrafficCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final t = net77Map(data['traffic']);
    return Net77Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.donut_large), SizedBox(width: 8), Text('流量统计', style: TextStyle(fontWeight: FontWeight.w600))]), const SizedBox(height: 14), Row(children: [Net77Donut(percent: net77Number(t['percent'])), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('━ 上传'), Text('━ 下载')]))]), const SizedBox(height: 12), Text('↑ ${net77Text(t['upload_text'] ?? t['u_text'], '0 B')}'), Text('↓ ${net77Text(t['download_text'] ?? t['d_text'], '0 B')}')]));
  }
}

class _NetworkCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NetworkCard({required this.onTap});
  @override
  Widget build(BuildContext context) => Net77Card(onTap: onTap, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('🇸🇬'), SizedBox(width: 8), Text('网络检测', style: TextStyle(fontWeight: FontWeight.w600)), Spacer(), Icon(Icons.settings_outlined, size: 18)]), SizedBox(height: 16), Text('点击查看节点状态')]));
}

class _Error extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _Error({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('重试'))])));
}
