import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';
import 'admin_categories_screen.dart';
import 'email_verification_screen.dart';
import 'my_annonces_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

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
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _loadWilayas();
  }

  Future<void> _loadWilayas() async {
    try {
      final wilayas = await ApiService().getWilayas();
      if (!mounted) return;
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      setState(() {
        _wilayas = wilayas;
        _loadingWilayas = false;
        if (user != null) {
          _selectedWilaya =
              wilayas.where((w) => w.id == user.wilayaId).firstOrNull;
          if (_selectedWilaya != null) {
            _loadCommunes(_selectedWilaya!.id,
                preselectCommuneId: user.communeId);
          }
        }
      });
    } catch (e) {
      setState(() => _loadingWilayas = false);
    }
  }

  Future<void> _loadCommunes(int wilayaId, {int? preselectCommuneId}) async {
    setState(() {
      _loadingCommunes = true;
      _selectedCommune = null;
      _communes = [];
    });
    try {
      final communes = await ApiService().getCommunes(wilayaId);
      setState(() {
        _communes = communes;
        _loadingCommunes = false;
        if (preselectCommuneId != null) {
          _selectedCommune =
              communes.where((c) => c.id == preselectCommuneId).firstOrNull;
        }
      });
    } catch (e) {
      setState(() => _loadingCommunes = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        _nameController.text = user?.name ?? '';
        _phoneController.text = user?.phone ?? '';
        // Reset location selections
        if (user != null) {
          _selectedWilaya =
              _wilayas.where((w) => w.id == user.wilayaId).firstOrNull;
          if (_selectedWilaya != null) {
            _loadCommunes(_selectedWilaya!.id,
                preselectCommuneId: user.communeId);
          }
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWilaya == null || _selectedCommune == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une wilaya et une commune'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      wilayaId: _selectedWilaya!.id,
      communeId: _selectedCommune!.id,
    );

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.accent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Erreur'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action supprimera votre compte ainsi que les données associées. Vous ne pourrez plus vous connecter ensuite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestAccountDeletion();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Votre demande de suppression a été prise en compte.'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.accent,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.error ?? 'Impossible de supprimer le compte'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myProfile),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _toggleEdit,
              child: const Text('Annuler'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Non connecté'));
          }

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    _AvatarUploadWidget(user: user),
                    const SizedBox(height: 16),

                    // Email (non-editable)
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .extension<AppColors>()!
                                .textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Email verification status
                    if (user.provider == null || user.provider!.isEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user.emailVerified
                                ? Icons.verified
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: user.emailVerified
                                ? Theme.of(context)
                                    .extension<AppColors>()!
                                    .accent
                                : Theme.of(context)
                                    .extension<AppColors>()!
                                    .warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.emailVerified
                                ? 'Email vérifié'
                                : 'Email non vérifié',
                            style: TextStyle(
                              fontSize: 13,
                              color: user.emailVerified
                                  ? Theme.of(context)
                                      .extension<AppColors>()!
                                      .accent
                                  : Theme.of(context)
                                      .extension<AppColors>()!
                                      .warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!user.emailVerified) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EmailVerificationScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  setState(() {});
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Vérifier',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nom',
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

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
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
                          return 'Veuillez entrer votre téléphone';
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
                            onChanged: !_isEditing
                                ? null
                                : (wilaya) {
                                    setState(() => _selectedWilaya = wilaya);
                                    if (wilaya != null)
                                      _loadCommunes(wilaya.id);
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
                            onChanged: !_isEditing || _selectedWilaya == null
                                ? null
                                : (commune) {
                                    setState(() => _selectedCommune = commune);
                                  },
                          ),
                    const SizedBox(height: 24),

                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: context.watch<ThemeProvider>().isDarkMode,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: Text(AppLocalizations.of(context)!.darkMode),
                            subtitle:
                                Text(AppLocalizations.of(context)!.saveTheme),
                            onChanged: (value) {
                              context.read<ThemeProvider>().setDarkMode(value);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: const Icon(Icons.language),
                            title: Text(AppLocalizations.of(context)!.language),
                            trailing: DropdownButton<String>(
                              value: context
                                  .watch<LocaleProvider>()
                                  .locale
                                  .languageCode,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                    value: 'fr', child: Text('Français')),
                                DropdownMenuItem(
                                    value: 'ar', child: Text('العربية')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<LocaleProvider>()
                                      .setLocale(Locale(value));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Enregistrer'),
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyAnnoncesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Mes annonces'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (user.role == 'Admin') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminCategoriesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.category),
                            label: const Text('Gestion des catégories (Admin)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .extension<AppColors>()!
                                  .textTertiary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _requestAccountDeletion,
                          icon: Icon(Icons.delete_forever,
                              color: Theme.of(context)
                                  .extension<AppColors>()!
                                  .error),
                          label: Text(
                            'Supprimer mon compte',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .extension<AppColors>()!
                                    .error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context)
                                    .extension<AppColors>()!
                                    .error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: Icon(Icons.logout,
                              color: Theme.of(context)
                                  .extension<AppColors>()!
                                  .error),
                          label: Text(
                            'Déconnexion',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .extension<AppColors>()!
                                    .error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context)
                                    .extension<AppColors>()!
                                    .error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AvatarUploadWidget extends StatefulWidget {
  final User user;

  const _AvatarUploadWidget({required this.user});

  @override
  State<_AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<_AvatarUploadWidget> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.uploadAvatar(File(picked.path));
    if (!mounted) return;
    setState(() => _uploading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Erreur lors du téléchargement'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? widget.user;

    final colors = Theme.of(context).extension<AppColors>()!;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        _uploading
            ? const CircleAvatar(
                radius: 50,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : UserAvatar(
                avatarUrl: user.avatarUrl,
                name: user.name,
                radius: 50,
              ),
        GestureDetector(
          onTap: _uploading ? null : _pickAndUpload,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.camera_alt,
              size: 16,
              color: colors.textOnPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
