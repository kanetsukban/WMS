import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../home/home_page.dart';
import '../../services/api_errors.dart';
import '../../services/api_errors.dart';

class LoginPage extends StatefulWidget {
  static const routeName = "/login";
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController(text: "amr@system");         // หรือ user@example.com
  final _passCtrl = TextEditingController(text: "amr@Passw0rd");
  bool _loading = false;
  String? _error;

  Future<void> _onLogin() async {
    try {
      setState(() { _loading = true; _error = null; });

      final id = _idCtrl.text.trim();
      // เดิม: final isEmail = id.contains('@');
      final ok = await context.read<AuthProvider>().login(
        username: id,                         // ✅ ส่ง username เสมอ
        email: null,                          // ❌ ไม่ใช้ email แล้ว
        password: _passCtrl.text,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (ok) {
        Navigator.pushReplacementNamed(context, HomePage.routeName);
      }
    } on ApiException catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    } catch (e) {
      setState(() { _loading = false; _error = 'Unexpected: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      resizeToAvoidBottomInset: true,
      body: LoadingOverlay(
        loading: _loading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _idCtrl, // ← เปลี่ยนจาก _userCtrl เป็น _idCtrl
                  decoration: const InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  onSubmitted: (_) => _onLogin(),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  text: "Login",
                  onPressed: _onLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

}
