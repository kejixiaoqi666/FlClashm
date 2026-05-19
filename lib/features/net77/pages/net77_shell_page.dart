import 'package:flutter/material.dart';

import '../net77_theme.dart';
import 'net77_account_page.dart';
import 'net77_home_page.dart';
import 'net77_settings_page.dart';
import 'net77_store_page.dart';

class Net77ShellPage extends StatefulWidget {
  final VoidCallback onEnterClient;
  final Future<void> Function() onLogout;
  const Net77ShellPage({super.key, required this.onEnterClient, required this.onLogout});
  @override
  State<Net77ShellPage> createState() => _Net77ShellPageState();
}

class _Net77ShellPageState extends State<Net77ShellPage> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      Net77HomePage(onEnterClient: widget.onEnterClient, onOpenStore: () => setState(() => _index = 1)),
      const Net77StorePage(),
      Net77AccountPage(onLogout: widget.onLogout),
      Net77SettingsPage(onEnterClient: widget.onEnterClient),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        backgroundColor: Net77Theme.page,
        selectedItemColor: Net77Theme.primary,
        unselectedItemColor: Net77Theme.text,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: '商店'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: '账号'),
          BottomNavigationBarItem(icon: Icon(Icons.construction), label: '设置'),
        ],
      ),
    );
  }
}
