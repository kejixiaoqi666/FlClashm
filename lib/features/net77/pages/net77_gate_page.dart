import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_config.dart';
import '../net77_theme.dart';
import 'net77_auth_page.dart';
import 'net77_shell_page.dart';

class Net77GatePage extends StatefulWidget {
  final Widget fallback;

  const Net77GatePage({
    super.key,
    required this.fallback,
  });

  @override
  State<Net77GatePage> createState() => _Net77GatePageState();
}

class _Net77GatePageState extends State<Net77GatePage> {
  final _entryCodeController = TextEditingController();

  bool _codePassed = false;
  bool _checkingCode = false;
  bool _loading = false;
  bool _authed = false;
  bool _showFallback = false;

  String? _error;

  @override
  void dispose() {
    _entryCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitEntryCode() async {
    final code = _entryCodeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _error = '请输入识别码';
      });
      return;
    }

    setState(() {
      _checkingCode = true;
      _error = null;
    });

    try {
      await Net77Api.instance.verifyEntryCode(code);

      if (!mounted) return;

      setState(() {
        _codePassed = true;
        _checkingCode = false;
      });

      await _bootstrap();
    } on Object catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingCode = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Net77Api.instance.config();

      final token = await Net77Api.instance.authData;

      if (token != null && token.isNotEmpty) {
        await Net77Api.instance.dashboard();
      }

      if (!mounted) return;

      setState(() {
        _authed = token != null && token.isNotEmpty;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _authed = false;
        _loading = false;
      });
    }
  }

  void _enterClient() {
    setState(() {
      _showFallback = true;
    });
  }

  void _onAuthed() {
    setState(() {
      _authed = true;
      _showFallback = false;
    });
  }

  Future<void> _logout() async {
    await Net77Api.instance.logout();

    setState(() {
      _authed = false;
      _showFallback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback) {
      return widget.fallback;
    }

    return Theme(
      data: Net77Theme.data(context),
      child: Builder(
        builder: (context) {
          if (!_codePassed) {
            return _buildEntryCodePage(context);
          }

          if (_loading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (_authed) {
            return Net77ShellPage(
              onEnterClient: _enterClient,
              onLogout: _logout,
            );
          }

          return Net77AuthPage(
            initialError: _error,
            onAuthed: _onAuthed,
          );
        },
      ),
    );
  }

  Widget _buildEntryCodePage(BuildContext context) {
    return Scaffold(
      body: Net77OrbitBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Net77Logo(
                        size: 74,
                        square: true,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      Net77Config.appDisplayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: Net77Theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '请输入识别码',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Net77Theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '识别码正确后才能进入客户端功能页面',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Net77Theme.subText,
                      ),
                    ),
                    const SizedBox(height: 34),
                    if (_error != null && _error!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _entryCodeController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_checkingCode) {
                          _submitEntryCode();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: '识别码',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _checkingCode ? null : _submitEntryCode,
                      child: _checkingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('进入'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
