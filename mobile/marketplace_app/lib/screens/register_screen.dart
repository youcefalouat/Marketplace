import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../services/social_auth_service.dart';
import '../theme/app_colors.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';
import 'complete_profile_screen.dart';
import 'phone_verification_screen.dart';
import 'legal_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  // Location state
  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];
  Wilaya? _selectedWilaya;
  Commune? _selectedCommune;
  bool _loadingWilayas = true;
  bool _loadingCommunes = false;

  @override
  void initState() {
    super.initState();
    _loadWilayas();
  }

  Future<void> _loadWilayas() async {
    try {
      final wilayas = await ApiService().getWilayas();
      if (!mounted) return;
      setState(() {
        _wilayas = wilayas;
        _loadingWilayas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingWilayas = false);
    }
  }

  Future<void> _loadCommunes(int wilayaId) async {
    setState(() {
      _loadingCommunes = true;
      _selectedCommune = null;
      _communes = [];
    });
    try {
      final communes = await ApiService().getCommunes(wilayaId);
      if (!mounted) return;
      setState(() {
        _communes = communes;
        _loadingCommunes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCommunes = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWilaya == null || _selectedCommune == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner votre wilaya et commune'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Veuillez accepter les conditions d\'utilisation pour continuer'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      wilayaId: _selectedWilaya!.id,
      communeId: _selectedCommune!.id,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.emailVerificationRequired) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? "Erreur lors de l'inscription"),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  Future<void> _googleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await SocialAuthService.signInWithGoogle();
      if (result == null) return;

      final success = await authProvider.socialLogin(
        provider: result.provider,
        providerId: result.providerId,
        email: result.email,
        name: result.name,
        accessToken: result.accessToken,
      );

      if (success && mounted) {
        if (authProvider.user?.phone.isEmpty ?? true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Erreur de connexion Google'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
          ),
        );
      }
    }
  }

  void _phoneLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhoneVerificationScreen()),
    );
  }

  void _openLegal(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(type: type)),
    );
  }

  Widget _buildTermsCheckbox(String languageCode) {
    final isFr = languageCode != 'ar';
    final linkColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final linkStyle = TextStyle(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
      fontWeight: FontWeight.w600,
    );

    final textSpan = isFr
        ? TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
            children: [
              const TextSpan(text: 'En créant un compte, vous acceptez les '),
              TextSpan(
                text: 'Conditions d\'utilisation',
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _openLegal('terms'),
              ),
              const TextSpan(text: ' et la '),
              TextSpan(
                text: 'Politique de confidentialité',
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _openLegal('privacy'),
              ),
              const TextSpan(text: '.'),
            ],
          )
        : TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
            children: [
              const TextSpan(text: 'بإنشاء حساب، فإنك توافق على '),
              TextSpan(
                text: 'شروط الاستخدام',
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _openLegal('terms'),
              ),
              const TextSpan(text: ' و'),
              TextSpan(
                text: 'سياسة الخصوصية',
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _openLegal('privacy'),
              ),
              const TextSpan(text: '.'),
            ],
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: RichText(text: textSpan),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);
    final languageCode =
        context.watch<LocaleProvider>().locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).extension<AppColors>()!.backgroundPrimary,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Wilaya dropdown
                _loadingWilayas
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Wilaya>(
                        initialValue: _selectedWilaya,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Wilaya',
                          prefixIcon:
                              const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _wilayas
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text('${w.code} - ${w.name}'),
                                ))
                            .toList(),
                        onChanged: (wilaya) {
                          setState(() => _selectedWilaya = wilaya);
                          if (wilaya != null) _loadCommunes(wilaya.id);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une wilaya';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Commune dropdown
                _loadingCommunes
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Commune>(
                        initialValue: _selectedCommune,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Commune',
                          prefixIcon:
                              const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _communes
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: _selectedWilaya == null
                            ? null
                            : (commune) {
                                setState(() => _selectedCommune = commune);
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une commune';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Terms & Conditions checkbox
                _buildTermsCheckbox(languageCode),
                const SizedBox(height: 24),

                // Register button — disabled if terms not accepted
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (isLoading || !_acceptedTerms) ? null : _register,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context)
                                  .extension<AppColors>()!
                                  .textOnPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "S'inscrire",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OU'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Google button
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _googleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text("S'inscrire avec Google"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone OTP button
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _phoneLogin,
                  icon: const Icon(Icons.phone_android),
                  label: const Text("S'inscrire avec Téléphone"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte?'),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
