import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: dp.usersLoading
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (dp.users.isEmpty)
                  const EmptyWidget(message: 'No users found', icon: Icons.people_outline)
                else
                  ...dp.users.map((u) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                              child: Text(
                                (u['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      const SizedBox(width: 6),
                                      StatusBadge(label: (u['role'] ?? '').toUpperCase(), color: AppTheme.primaryBlue),
                                    ],
                                  ),
                                  PhoneLink(phone: u['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Switch(
                              value: u['is_active'] ?? true,
                              activeColor: AppTheme.accentGreen,
                              onChanged: (val) async {
                                await dp.updateUser(u['id'], {'is_active': val});
                              },
                            ),
                          ],
                        ),
                      )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    String role = 'staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 10),
                TextField(controller: pwCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final ok = await context.read<DataProvider>().createUser({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'password': pwCtrl.text,
                  'role': role,
                });
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
