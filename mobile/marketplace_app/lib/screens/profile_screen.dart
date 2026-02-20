import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

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
        const SnackBar(
          content: Text('Veuillez sélectionner une wilaya et une commune'),
          backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Erreur'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email (non-editable)
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
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
                          value: _selectedWilaya,
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
                                  if (wilaya != null) _loadCommunes(wilaya.id);
                                },
                        ),
                  const SizedBox(height: 16),

                  // Commune dropdown
                  _loadingCommunes
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<Commune>(
                          value: _selectedCommune,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Commune',
                            prefixIcon: const Icon(Icons.location_on_outlined),
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
                  const SizedBox(height: 32),

                  // Save or Logout button
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
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Enregistrer'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
