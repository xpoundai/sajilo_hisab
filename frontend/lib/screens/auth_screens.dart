import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.asset('assets/logo.png', width: 120, height: 120, fit: BoxFit.contain),
                    ),
                  ),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to Sajilo Hisab',
                    style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: AppTheme.errorRed, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Phone / Username
                  TextField(
                    controller: _identifierCtrl,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number / Username',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter phone or admin username',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              final success = await auth.login(
                                _identifierCtrl.text.trim(),
                                _passwordCtrl.text,
                              );
                              if (success && mounted) context.go('/dashboard');
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Login', style: TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register link
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      'Register New Business',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Register ────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register Business')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(auth.error!, style: const TextStyle(color: AppTheme.errorRed)),
                    ),

                  TextField(controller: _businessNameCtrl, decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.store_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name', prefixIcon: Icon(Icons.person_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outlined))),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              final success = await auth.register({
                                'business_name': _businessNameCtrl.text.trim(),
                                'owner_name': _ownerNameCtrl.text.trim(),
                                'phone': _phoneCtrl.text.trim(),
                                'email': _emailCtrl.text.trim(),
                                'address': _addressCtrl.text.trim(),
                                'password': _passwordCtrl.text,
                                'confirm_password': _confirmCtrl.text,
                              });
                              if (success && mounted) context.go('/dashboard');
                            },
                      child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Register', style: TextStyle(fontSize: 17)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
