import 'package:flutter/widgets.dart';

import '../models/models.dart';

const _categoryNames = {
  'ar': {
    'electromenager': 'الأجهزة المنزلية',
    'électroménager': 'الأجهزة المنزلية',
    'meubles': 'الأثاث',
    'literie': 'المفروشات',
    'decoration': 'الديكور',
    'décoration': 'الديكور',
    'gros-electromenager': 'الأجهزة المنزلية الكبيرة',
    'gros électroménager': 'الأجهزة المنزلية الكبيرة',
    'petit-electromenager': 'الأجهزة المنزلية الصغيرة',
    'petit électroménager': 'الأجهزة المنزلية الصغيرة',
    'salon': 'غرفة المعيشة',
    'chambre': 'غرفة النوم',
    'chauffage': 'التدفئة',
    'climatisation': 'التكييف',
    'cuisine': 'المطبخ',
    'réfrigérateur': 'ثلاجة',
    'refrigerateur': 'ثلاجة',
    'frigidaire': 'ثلاجة',
  },
};

String localizedCategoryName(BuildContext context, CategoryModel category) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ar' && category.arName.trim().isNotEmpty) {
    return category.arName;
  }

  return localizedCategoryText(
    context,
    category.slug.isNotEmpty ? category.slug : category.name,
    fallback: category.name,
    arName: category.arName,
  );
}

String localizedCategoryText(
  BuildContext context,
  String value, {
  String? fallback,
  String? arName,
}) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ar' && arName != null && arName.trim().isNotEmpty) {
    return arName;
  }

  final map = _categoryNames[locale];
  if (map == null) return fallback ?? value;

  final normalized = value.trim().toLowerCase();
  return map[normalized] ?? fallback ?? value;
}
