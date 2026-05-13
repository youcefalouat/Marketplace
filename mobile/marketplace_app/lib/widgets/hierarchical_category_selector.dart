import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/category_localizations.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class HierarchicalCategorySelection {
  final CategoryModel category;
  final CategoryModel? parentCategory;
  final List<CategoryModel> path;

  const HierarchicalCategorySelection({
    required this.category,
    required this.parentCategory,
    required this.path,
  });

  int get selectedCategoryId => category.id;
  int? get parentCategoryId => parentCategory?.id;

  String localizedPath(BuildContext context) {
    return path
        .map((category) => localizedCategoryName(context, category))
        .join(' > ');
  }
}

class HierarchicalCategorySelector extends StatefulWidget {
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<HierarchicalCategorySelection?> onChanged;
  final String labelText;
  final String hintText;
  final bool allowClear;
  final bool onlyLeafSelection;
  final bool enabled;
  final FormFieldValidator<HierarchicalCategorySelection>? validator;

  const HierarchicalCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
    required this.labelText,
    required this.hintText,
    this.allowClear = false,
    this.onlyLeafSelection = false,
    this.enabled = true,
    this.validator,
  });

  @override
  State<HierarchicalCategorySelector> createState() =>
      _HierarchicalCategorySelectorState();
}

class _HierarchicalCategorySelectorState
    extends State<HierarchicalCategorySelector> {
  late List<_CategoryOption> _options;

  @override
  void initState() {
    super.initState();
    _options = _flattenCategories(widget.categories);
  }

  @override
  void didUpdateWidget(covariant HierarchicalCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories ||
        oldWidget.onlyLeafSelection != widget.onlyLeafSelection) {
      _options = _flattenCategories(widget.categories);
    }
  }

  List<_CategoryOption> _flattenCategories(List<CategoryModel> categories) {
    final options = <_CategoryOption>[];

    void collect(
      CategoryModel category,
      List<CategoryModel> path,
      CategoryModel? parent,
    ) {
      final nextPath = [...path, category];
      final hasChildren = category.subCategories.isNotEmpty;

      if (!widget.onlyLeafSelection || !hasChildren) {
        options.add(_CategoryOption(
          selection: HierarchicalCategorySelection(
            category: category,
            parentCategory: parent,
            path: nextPath,
          ),
          depth: nextPath.length - 1,
        ));
      }

      for (final child in category.subCategories) {
        collect(child, nextPath, category);
      }
    }

    for (final category in categories) {
      collect(category, const [], null);
    }

    return options;
  }

  HierarchicalCategorySelection? _selectedSelection() {
    if (widget.selectedCategoryId == null) return null;
    for (final option in _options) {
      if (option.selection.selectedCategoryId == widget.selectedCategoryId) {
        return option.selection;
      }
    }
    return null;
  }

  Future<void> _openSelector(
    BuildContext context,
    FormFieldState<HierarchicalCategorySelection> field,
  ) async {
    if (!widget.enabled) return;

    final result = await showDialog<_CategorySheetResult>(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: _CategoryPickerDialog(
            options: _options,
            selectedCategoryId: widget.selectedCategoryId,
            labelText: widget.labelText,
            allowClear: widget.allowClear,
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    field.didChange(result.selection);
    widget.onChanged(result.selection);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<HierarchicalCategorySelection>(
      initialValue: _selectedSelection(),
      validator: widget.validator,
      builder: (field) {
        final selected = _selectedSelection();
        final colors = Theme.of(context).extension<AppColors>()!;
        final displayText = selected?.localizedPath(context) ?? widget.hintText;

        return InkWell(
          borderRadius: AppLayout.borderRadiusMedium,
          onTap: widget.enabled ? () => _openSelector(context, field) : null,
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: InputDecoration(
              errorText: field.errorText,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color:
                    widget.enabled ? colors.textSecondary : colors.textTertiary,
              ),
            ),
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    selected == null ? colors.textTertiary : colors.textPrimary,
                fontWeight:
                    selected == null ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryOption {
  final HierarchicalCategorySelection selection;
  final int depth;

  const _CategoryOption({
    required this.selection,
    required this.depth,
  });

  bool matches(BuildContext context, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final parts = <String>[
      selection.localizedPath(context),
      selection.category.name,
      selection.category.arName,
      selection.category.slug,
      for (final item in selection.path) ...[
        item.name,
        item.arName,
        item.slug,
      ],
    ];

    return parts.any((part) => part.toLowerCase().contains(normalized));
  }
}

class _CategorySheetResult {
  final HierarchicalCategorySelection? selection;

  const _CategorySheetResult({this.selection});
}

class _CategoryPickerDialog extends StatefulWidget {
  final List<_CategoryOption> options;
  final int? selectedCategoryId;
  final String labelText;
  final bool allowClear;

  const _CategoryPickerDialog({
    required this.options,
    required this.selectedCategoryId,
    required this.labelText,
    required this.allowClear,
  });

  @override
  State<_CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<_CategoryPickerDialog> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final filteredOptions = _query.isEmpty
        ? widget.options
        : widget.options
            .where((option) => option.matches(context, _query))
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.labelText),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.allowClear)
            TextButton(
              onPressed: () {
                Navigator.pop(context, const _CategorySheetResult());
              },
              child: Text(l10n.all),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.screenPadding,
              AppLayout.spacing12,
              AppLayout.screenPadding,
              AppLayout.spacing8,
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: filteredOptions.length,
              itemBuilder: (itemContext, index) {
                final option = filteredOptions[index];
                final selection = option.selection;
                final selected =
                    selection.selectedCategoryId == widget.selectedCategoryId;

                return ListTile(
                  contentPadding: EdgeInsetsDirectional.only(
                    start: AppLayout.screenPadding +
                        (option.depth * AppLayout.spacing12),
                    end: AppLayout.screenPadding,
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.primaryMuted,
                      borderRadius: AppLayout.borderRadiusSmall,
                    ),
                    child: Icon(
                      option.depth == 0
                          ? Icons.category_outlined
                          : Icons.subdirectory_arrow_right,
                      size: 18,
                      color: selected ? colors.textOnPrimary : colors.primary,
                    ),
                  ),
                  title: Text(
                    selection.localizedPath(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: selection.parentCategory == null
                      ? null
                      : Text(
                          localizedCategoryName(
                            itemContext,
                            selection.parentCategory!,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: colors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      _CategorySheetResult(selection: selection),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
