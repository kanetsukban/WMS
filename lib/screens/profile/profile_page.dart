import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login/login_page.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = "/profile";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลล่าสุดเมื่อเข้าหน้า (ครั้งแรก)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _loading = true);
      try {
        await context.read<AuthProvider>().refreshMe();
      } catch (_) {
        // ignore error; จะถูกบังคับ logout ตอน /me พังใน restore/refresh อยู่แล้ว
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _loading = true);
              await context.read<AuthProvider>().refreshMe();
              if (mounted) setState(() => _loading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile refreshed')),
                );
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('Username'),
                    subtitle: Text(user?.username ?? '-'),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('First name'),
                    subtitle: Text((user?.firstName ?? '').isEmpty ? '—' : user!.firstName),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.person_2_outlined),
                    title: const Text('Last name'),
                    subtitle: Text((user?.lastName ?? '').isEmpty ? '—' : user!.lastName),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text((user?.email ?? '').isEmpty ? '—' : user!.email),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Do you really want to logout?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                          ],
                        ),
                      );
                      if (confirm != true) return;

                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoginPage.routeName,
                          (route) => false,
                        );
                      }
                    },
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
