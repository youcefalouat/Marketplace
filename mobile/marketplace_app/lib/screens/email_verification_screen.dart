import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _mockCode; // For dev: display the mock code

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService().sendEmailVerificationCode(
        Provider.of<AuthProvider>(context, listen: false).user!.email,
      );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isLoading = false;
        _mockCode = result['mockCode']?.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Code de vérification envoyé sur votre email !'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Veuillez entrer le code'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final updatedUser = await ApiService().verifyEmail(user.email, code);
      if (!mounted) return;

      // Update auth provider with verified user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setUser(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Email vérifié avec succès !'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.accent,
        ),
      );
      Navigator.pop(context, true); // Return true = verified
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification de l\'email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Vérifiez votre email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Un code de vérification sera envoyé à votre adresse email.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).extension<AppColors>()!.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email display (non-editable)
            TextFormField(
              initialValue: email,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Adresse email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (!_codeSent) ...[
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Theme.of(context).extension<AppColors>()!.textOnPrimary)
                      : const Text('Envoyer le code',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],

            if (_codeSent) ...[
              // Mock code display (dev only)
              if (_mockCode != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AppColors>()!.warningMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).extension<AppColors>()!.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).extension<AppColors>()!.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '[DEV] Code: $_mockCode',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Code input
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Code de vérification',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Theme.of(context).extension<AppColors>()!.textOnPrimary)
                      : const Text('Vérifier', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _codeSent = false;
                          _codeController.clear();
                          _mockCode = null;
                        });
                      },
                child: const Text('Renvoyer le code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
