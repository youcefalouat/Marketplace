import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/services/image_compressor.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/annonces_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/hierarchical_category_selector.dart';
import 'phone_verification_screen.dart';

class CreateAnnonceScreen extends StatefulWidget {
  const CreateAnnonceScreen({super.key});

  @override
  State<CreateAnnonceScreen> createState() => _CreateAnnonceScreenState();
}

class _CreateAnnonceScreenState extends State<CreateAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();

  HierarchicalCategorySelection? _selectedCategorySelection;
  int? _selectedParentCategoryId;
  int? _selectedCategoryId;
  List<CategoryModel> _apiCategories = [];
  bool _loadingCategories = true;
  int _selectedState = 0;
  bool _isExchange = false;
  bool _showPhone = true;
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // Location state
  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];
  Wilaya? _selectedWilaya;
  Commune? _selectedCommune;
  bool _loadingWilayas = true;
  bool _loadingCommunes = false;

  bool _isPickingImage = false;
  bool _isSubmitting = false; // New state variable for submission

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadWilayas();
    _prefillUserData();
    _checkPhoneVerification();
  }

  void _checkPhoneVerification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null && !user.phoneVerified) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.verificationRequired),
            content: Text(
              AppLocalizations.of(context)!.phoneVerificationRequiredMessage,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final verified = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneVerificationScreen(),
                    ),
                  );
                  if (verified != true && mounted) {
                    Navigator.pop(context); // Not verified, go back
                  }
                },
                child: Text(AppLocalizations.of(context)!.verify),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService().getCategories();
      if (!mounted) return;
      setState(() {
        _apiCategories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadWilayas() async {
    try {
      final wilayas = await ApiService().getWilayas();
      if (!mounted) return;
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      setState(() {
        _wilayas = wilayas;
        _loadingWilayas = false;
        // Pre-select user's wilaya
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

  void _prefillUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPickingImage) return;

    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxFivePhotos)),
      );
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - _images.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        setState(() {
          _images.addAll(filesToAdd.map((xFile) => File(xFile.path)));
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_isPickingImage) return;

    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxFivePhotos)),
      );
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addAtLeastOnePhoto),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }

    final selectedCategory = _selectedCategorySelection;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectCategoryValidation),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
      return;
    }

    final int finalCategoryId = selectedCategory.selectedCategoryId;

    final provider = Provider.of<AnnoncesProvider>(context, listen: false);

    // Show loading state and compress images
    setState(() => _isSubmitting = true);

    List<File> finalImages;
    try {
      finalImages = await ImageCompressor.compressImages(_images);
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .imageCompressionError(e.toString()))),
      );
      return;
    }

    final success = await provider.createAnnonce(
      categoryId: finalCategoryId,
      parentCategoryId: _selectedParentCategoryId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      state: _selectedState,
      phone: _phoneController.text.trim(),
      wilayaId: _selectedWilaya?.id,
      communeId: _selectedCommune?.id,
      isExchange: _isExchange,
      showPhone: _showPhone,
      images: finalImages,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.annonceCreatedPending),
          backgroundColor: Theme.of(context).extension<AppColors>()!.accent,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.error ?? AppLocalizations.of(context)!.creationError),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final states = [l10n.newCondition, l10n.usedCondition];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newAnnonce),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos section
            Text(
              l10n.photosCount(_images.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildPhotosSection(),
            const SizedBox(height: 24),

            // Category
            Text(
              l10n.category,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            _loadingCategories
                ? const Center(child: CircularProgressIndicator())
                : HierarchicalCategorySelector(
                    categories: _apiCategories,
                    selectedCategoryId: _selectedCategoryId,
                    labelText: l10n.category,
                    hintText: l10n.allCategories,
                    onlyLeafSelection: true,
                    validator: (selection) => selection == null
                        ? l10n.selectCategoryValidation
                        : null,
                    onChanged: (selection) {
                      setState(() {
                        _selectedCategorySelection = selection;
                        _selectedCategoryId = selection?.selectedCategoryId;
                        _selectedParentCategoryId = selection?.parentCategoryId;
                      });
                    },
                  ),
            const SizedBox(height: 16),

            // State
            Text(
              l10n.condition,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(states.length, (index) {
                return ChoiceChip(
                  label: Text(states[index]),
                  selected: _selectedState == index,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedState = index);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.title,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterTitle;
                }
                if (value.length < 5) {
                  return l10n.titleMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.descriptionTitle,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterDescription;
                }
                if (value.length < 20) {
                  return l10n.descriptionMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.priceDa,
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterPrice;
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return l10n.invalidPrice;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // IsExchange toggle
            SwitchListTile(
              title: Text(l10n.exchangePossible),
              subtitle: Text(l10n.exchangeSubtitle),
              value: _isExchange,
              onChanged: (value) => setState(() => _isExchange = value),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterPhone;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Show Phone toggle
            SwitchListTile(
              title: Text(l10n.showPhone),
              subtitle: Text(l10n.showPhoneSubtitle),
              value: _showPhone,
              onChanged: (value) => setState(() => _showPhone = value),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 16),

            // Wilaya dropdown
            _loadingWilayas
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Wilaya>(
                    initialValue: _selectedWilaya,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.wilaya,
                      prefixIcon: const Icon(Icons.location_city),
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
                  ),
            const SizedBox(height: 16),

            // Commune dropdown
            _loadingCommunes
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Commune>(
                    initialValue: _selectedCommune,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.commune,
                      prefixIcon: const Icon(Icons.location_on),
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
                  ),
            const SizedBox(height: 32),

            // Submit button
            Consumer<AnnoncesProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (provider.isLoading || _isSubmitting) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: (provider.isLoading || _isSubmitting)
                        ? CircularProgressIndicator(
                            color: Theme.of(context)
                                .extension<AppColors>()!
                                .textOnPrimary)
                        : Text(
                            _isSubmitting
                                ? l10n.compressingAndSending
                                : l10n.publishAnnonce,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).extension<AppColors>()!.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        children: [
          // Add photo buttons
          if (_images.length < 5) ...[
            _buildAddPhotoButton(
              icon: Icons.photo_library,
              label: AppLocalizations.of(context)!.gallery,
              onTap: _pickImages,
            ),
            const SizedBox(width: 8),
            _buildAddPhotoButton(
              icon: Icons.camera_alt,
              label: AppLocalizations.of(context)!.photo,
              onTap: _takePhoto,
            ),
            const SizedBox(width: 8),
          ],
          // Existing images
          ..._images.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      entry.value,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).extension<AppColors>()!.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context)
                              .extension<AppColors>()!
                              .textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).extension<AppColors>()!.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).extension<AppColors>()!.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 32,
                color: Theme.of(context).extension<AppColors>()!.textTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).extension<AppColors>()!.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
