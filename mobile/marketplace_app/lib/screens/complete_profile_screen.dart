import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

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
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWilaya == null || _selectedCommune == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner votre wilaya et commune'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final success = await authProvider.updateProfile(
      name: user.name, // Keep existing name from social login
      phone: _phoneController.text.trim(),
      wilayaId: _selectedWilaya!.id,
      communeId: _selectedCommune!.id,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Erreur lors de la mise à jour'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        automaticallyImplyLeading: false, // Force them to complete it
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenue ! Nous avons besoin de quelques informations supplémentaires pour terminer la création de votre compte.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

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
                        prefixIcon: const Icon(Icons.location_city_outlined),
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
                        if (value == null)
                          return 'Veuillez sélectionner une wilaya';
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
                      onChanged: _selectedWilaya == null
                          ? null
                          : (commune) {
                              setState(() => _selectedCommune = commune);
                            },
                      validator: (value) {
                        if (value == null)
                          return 'Veuillez sélectionner une commune';
                        return null;
                      },
                    ),
              const SizedBox(height: 32),

              // Submit button
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? CircularProgressIndicator(
                              color: Theme.of(context)
                                  .extension<AppColors>()!
                                  .textOnPrimary)
                          : const Text(
                              'Terminer',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
