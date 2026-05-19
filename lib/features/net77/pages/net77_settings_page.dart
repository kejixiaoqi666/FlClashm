import 'package:flutter/material.dart';

import '../net77_theme.dart';

class Net77SettingsPage extends StatelessWidget {
  final VoidCallback onEnterClient;
  const Net77SettingsPage({super.key, required this.onEnterClient});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 18), children: [
    const Text('设置', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
    const SizedBox(height: 34),
    const _Label('查看'),
    _group([_item(Icons.article_outlined, '请求', '查看最近请求记录'), _item(Icons.grid_view_outlined, '连接', '查看当前连接数据'), _item(Icons.storage_outlined, '资源', '外部资源相关信息'), _item(Icons.functions, '脚本', '配置全局覆写脚本'), _item(Icons.bug_report_outlined, '日志', '查看日志捕获记录')]),
    const _Label('设置'),
    _group([_item(Icons.language, '语言', '简体中文'), _item(Icons.style_outlined, '主题', '设置主题色彩及图标'), _item(Icons.table_view_outlined, '访问控制', '配置应用访问代理'), _item(Icons.edit, '内核配置', '编辑运行参数')]),
  ])));
  Widget _group(List<Widget> items) => Net77Card(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < items.length; i++) ...[items[i], if (i != items.length - 1) const Divider(height: 1)]]));
  Widget _item(IconData icon, String title, String sub) => ListTile(minVerticalPadding: 14, leading: Icon(icon, color: Net77Theme.text), title: Text(title, style: const TextStyle(fontSize: 17)), subtitle: Text(sub), onTap: onEnterClient);
}
class _Label extends StatelessWidget { final String text; const _Label(this.text); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4), child: Text(text, style: const TextStyle(color: Net77Theme.subText))); }
