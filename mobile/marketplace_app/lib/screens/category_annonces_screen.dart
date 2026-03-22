import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/annonces_provider.dart';
import 'search_screen.dart';

class CategoryAnnoncesScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const CategoryAnnoncesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnnoncesProvider()..setFilters(categoryId: categoryId),
      child: SearchScreen(title: categoryName, lockCategory: true),
    );
  }
}
