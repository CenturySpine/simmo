import 'package:flutter/material.dart';

import '../../../shared/external_link.dart';
import 'legal_dialogs.dart';

/// Page footer: warning, legal links, copyright (in that usual order).
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.onClearData});

  /// Erases the values kept on this device (RGPD dialog).
  final VoidCallback onClearData;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              disclaimer,
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FooterLink(
                'Mentions légales',
                onTap: () => showLegalNotice(context),
              ),
              Text('·', style: text.bodySmall),
              _FooterLink(
                'Confidentialité',
                onTap: () => showPrivacy(context, onClearData),
              ),
              Text('·', style: text.bodySmall),
              _FooterLink(
                'À propos',
                onTap: () => openExternal(aboutUrl),
                external: true,
              ),
            ],
          ),
          Text('© 2026 Simmo', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, {required this.onTap, this.external = false});

  final String label;
  final VoidCallback onTap;

  /// Opens another site: shown with the usual "new tab" icon.
  final bool external;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: Theme.of(context).textTheme.labelMedium,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (external) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}
