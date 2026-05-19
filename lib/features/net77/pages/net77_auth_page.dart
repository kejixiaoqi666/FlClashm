import 'package:flutter/material.dart';

import '../net77_api.dart';
import '../net77_config.dart';
import '../net77_theme.dart';

class Net77AuthPage extends StatefulWidget {
  final VoidCallback onAuthed;
  final String? initialError;
  const Net77AuthPage({super.key, required this.onAuthed, this.initialError});
  @override
  State<Net77AuthPage> createState() => _Net77AuthPageState();
}

class _Net77AuthPageState extends State<Net77AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _invite = TextEditingController();
  bool _register = false;
  bool _loading = false;
  bool _visible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        await Net77Api.instance.register(
          email: _email.text.trim(),
          password: _password.text,
          inviteCode: _invite.text.trim(),
        );
      } else {
        await Net77Api.instance.login(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      widget.onAuthed();
    } on Object catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Net77OrbitBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Net77Logo(size: _register ? 62 : 74, rocket: _register, square: !_register),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _register ? '注册' : Net77Config.appDisplayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: Net77Theme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _register ? '创建账号' : '登录您的账户',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, color: Net77Theme.text),
                      ),
                      if (_register) ...[
                        const SizedBox(height: 10),
                        const Text(
                          '仅需几秒，即可连接至全球高速网络。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Net77Theme.subText),
                        ),
                      ],
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
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _field(
                        _email,
                        '邮箱',
                        Icons.mail_outline,
                        validator: (v) => (v == null || !v.contains('@')) ? '请输入正确邮箱' : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _password,
                        '密码',
                        Icons.lock_outline,
                        obscure: !_visible,
                        validator: (v) => (v ?? '').length < 6 ? '密码至少 6 位' : null,
                        suffix: IconButton(
                          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _visible = !_visible),
                        ),
                      ),
                      if (_register) ...[
                        const SizedBox(height: 14),
                        _field(
                          _confirm,
                          '确认密码',
                          Icons.lock_outline,
                          obscure: !_visible,
                          validator: (v) => v == _password.text ? null : '两次密码不一致',
                        ),
                        const SizedBox(height: 14),
                        _field(_invite, '邀请码（可选）', Icons.card_giftcard_outlined),
                      ] else ...[
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('忘记密码？'))),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_register ? '注册' : '登录'),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_register ? '已有账号？' : '还没有账户？'),
                          TextButton(
                            onPressed: _loading ? null : () => setState(() => _register = !_register),
                            child: Text(_register ? '回到登录' : '立即注册'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}
