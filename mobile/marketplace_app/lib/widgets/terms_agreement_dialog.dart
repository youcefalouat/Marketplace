import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/legal_screen.dart';

/// Reuses the app's existing legal screens while keeping social account
/// creation pending until the user explicitly accepts the terms.
Future<bool> showTermsAgreementDialog(
  BuildContext context, {
  bool allowCancel = true,
}) async {
  var accepted = false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: allowCancel,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        final linkStyle = TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        );
        return AlertDialog(
          title: Text(l10n.termsAgreementTitle),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: accepted,
                onChanged: (value) => setState(() => accepted = value ?? false),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(text: l10n.termsAgreementText),
                      TextSpan(
                        text: l10n.termsLink,
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LegalScreen(type: 'terms'),
                                ),
                              ),
                      ),
                      TextSpan(text: l10n.andText),
                      TextSpan(
                        text: l10n.privacyLink,
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LegalScreen(type: 'privacy'),
                                ),
                              ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (allowCancel)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
            ElevatedButton(
              onPressed: accepted ? () => Navigator.of(dialogContext).pop(true) : null,
              child: Text(l10n.accept),
            ),
          ],
        );
      },
    ),
  );
  return result ?? false;
}
