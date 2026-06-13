import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class LegalScreen extends StatefulWidget {
  /// 'terms' or 'privacy'
  final String type;

  const LegalScreen({super.key, required this.type});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  LegalContent? _content;
  bool _isLoading = true;
  String? _error;

  bool get _isTerms => widget.type == 'terms';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final content = _isTerms
          ? await ApiService().getTerms()
          : await ApiService().getPrivacy();
      if (!mounted) return;
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode =
        context.watch<LocaleProvider>().locale.languageCode;
    final colors = Theme.of(context).extension<AppColors>()!;

    final defaultTitle = _isTerms
        ? (languageCode == 'ar' ? 'شروط الاستخدام' : 'Conditions d\'utilisation')
        : (languageCode == 'ar' ? 'سياسة الخصوصية' : 'Politique de confidentialité');

    final title = _content?.titleForLanguage(languageCode) ?? defaultTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(languageCode, colors),
    );
  }

  Widget _buildBody(String languageCode, AppColors colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null) return const SizedBox.shrink();

    final isRtl = languageCode == 'ar';
    final body = _content!.contentForLanguage(languageCode);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Text(
              isRtl
                  ? 'آخر تحديث: ${_formatDate(_content!.updatedAt)}'
                  : 'Dernière mise à jour : ${_formatDate(_content!.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Content — render markdown-like headings
            ..._parseContent(body, colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseContent(String content, AppColors colors) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            line.substring(3),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  height: 1.6,
                ),
          ),
        ));
      }
    }
    return widgets;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
