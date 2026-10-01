import 'package:flutter/material.dart';

const aboutUrl = 'https://centuryspine.org';

/// Short warning shown in the footer.
const disclaimer =
    'Simulation indicative et non contractuelle : ni offre de prêt, ni '
    'conseil. Un crédit vous engage et doit être remboursé. Vérifiez vos '
    'capacités de remboursement avant de vous engager.';

Future<void> showLegalNotice(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const _LegalDialog(
    title: 'Mentions légales',
    sections: [
      (
        'Éditeur',
        'Simmo est un service gratuit, édité à titre personnel et non '
            'professionnel par Bruno Chappe, directeur de la publication. '
            'Présentation et contact : centuryspine.org.',
      ),
      (
        'Hébergeur',
        'Vercel Inc., 440 N Barranca Ave #4133, Covina, CA 91723, '
            'États-Unis (vercel.com).',
      ),
      (
        'Avertissement',
        'Les résultats sont des estimations calculées à partir des '
            'paramètres saisis et des règles connues en septembre 2026. Ils '
            'ne constituent ni une offre de prêt, ni un accord de '
            'financement, ni un conseil en crédit ou en investissement. '
            'Simmo n’est pas un intermédiaire en opérations de banque et '
            'n’est affilié à aucune banque, aucun courtier ni aucun '
            'organisme de caution. Seule l’offre de prêt d’un établissement '
            'de crédit fait foi ; l’emprunteur dispose d’un délai de '
            'réflexion de dix jours après l’avoir reçue. L’éditeur ne peut '
            'être tenu responsable des décisions prises sur la base de ces '
            'simulations.\n\nUn crédit vous engage et doit être remboursé. '
            'Vérifiez vos capacités de remboursement avant de vous engager.',
      ),
      (
        'Sources',
        'Normes du Haut Conseil de stabilité financière ; prêt à taux zéro '
            '(décret n° 2025-299) ; tarif des notaires et droits de mutation ; '
            'barème de l’impôt sur le revenu 2026 ; barème de garantie relevé '
            'sur le simulateur public de Crédit Logement ; taux moyens '
            'd’assurance emprunteur publiés en 2026. Zonage ABC : « Liste des '
            'communes selon le zonage ABC », Ministère de la Transition '
            'écologique, data.gouv.fr, Licence Ouverte 2.0.',
      ),
      (
        'Propriété intellectuelle',
        '© 2026 Simmo. Police Plus Jakarta Sans sous licence SIL Open Font '
            'License.',
      ),
    ],
  ),
);

/// RGPD information; [onClearData] erases what this device keeps.
Future<void> showPrivacy(
  BuildContext context,
  VoidCallback onClearData,
) => showDialog<void>(
  context: context,
  builder: (context) => _LegalDialog(
    title: 'Confidentialité',
    sections: const [
      (
        'Aucune collecte',
        'Simmo ne collecte, ne transmet ni ne vend aucune donnée '
            'personnelle. Tous les calculs sont faits dans votre '
            'navigateur : aucune valeur saisie n’est envoyée à un serveur.',
      ),
      (
        'Données gardées sur votre appareil',
        'Revenus, revenu fiscal, taux, prix, âge, taux de prélèvement, '
            'budget du logement (charges, taxe foncière, travaux) et prix '
            'de négociation saisis sont conservés dans le stockage local de '
            'votre navigateur, pour les retrouver à votre prochaine visite. '
            'Ils ne quittent pas votre appareil. Ce stockage sert '
            'uniquement au service que vous utilisez et ne demande donc '
            'pas de consentement. Vous pouvez l’effacer à tout moment.',
      ),
      (
        'Liens de partage',
        'Un lien de partage contient les valeurs de la simulation, '
            'placées après le « # » de l’adresse, partie que le '
            'navigateur n’envoie pas au serveur. Toute personne qui reçoit '
            'le lien voit ces valeurs : ne le partagez qu’avec des '
            'personnes de confiance.',
      ),
      (
        'Cookies et traceurs',
        'Aucun cookie, aucune mesure d’audience, aucune publicité. '
            'Polices et données sont servies par le site lui-même, sans '
            'service tiers.',
      ),
      (
        'Hébergement',
        'Comme tout hébergeur, Vercel traite des données techniques de '
            'connexion (adresse IP, date, page demandée) pour la sécurité '
            'et le fonctionnement du site, selon sa politique de '
            'confidentialité (vercel.com/legal/privacy-policy).',
      ),
      (
        'Vos droits',
        'Les données n’étant conservées que sur votre appareil, vous en '
            'gardez la maîtrise : effacez-les ci-dessous ou depuis les '
            'réglages de votre navigateur. Vous pouvez adresser une '
            'réclamation à la CNIL (cnil.fr).',
      ),
    ],
    action: TextButton.icon(
      onPressed: () {
        onClearData();
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Effacer les données de cet appareil'),
    ),
  ),
);

class _LegalDialog extends StatelessWidget {
  const _LegalDialog({
    required this.title,
    required this.sections,
    this.action,
  });

  final String title;
  final List<(String, String)> sections;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (heading, body) in sections) ...[
                Text(heading, style: text.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: text.bodyMedium),
                const SizedBox(height: 16),
              ],
              ?action,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
