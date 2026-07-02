using MarketplaceApi.DTOs;

namespace MarketplaceApi.Infrastructure;

public static class LegalDocumentStore
{
    public static readonly DateTime TermsUpdatedAt = new DateTime(2026, 7, 1, 0, 0, 0, DateTimeKind.Utc);

    public static readonly string TermsMarkdown = """
# Conditions Générales d'Utilisation

## 1. Objet

Les présentes conditions générales d'utilisation régissent l'accès et l'utilisation de l'application mobile et du service en ligne de la marketplace. L'application permet aux utilisateurs d'acheter, de vendre, de réserver des annonces et d'échanger des messages dans le cadre d'opérations entre particuliers.

## 2. Éligibilité

L'accès à l'application est réservé aux personnes physiques capables juridiquement d'accepter des conditions contractuelles. Les mineurs doivent obtenir l'autorisation d'un parent ou d'un tuteur légal pour utiliser le service. L'utilisateur doit être en mesure de conclure des transactions et de respecter ces conditions.

## 3. Inscription

Pour utiliser l'application, l'utilisateur doit créer un compte en fournissant des informations exactes, complètes et à jour. Il est responsable de l'authenticité des informations fournies, de la confidentialité de ses identifiants et de l'accès à son compte.

## 4. Responsabilités des utilisateurs

L'utilisateur s'engage à utiliser la plateforme de bonne foi, à respecter les lois applicables et à ne pas perturber le fonctionnement du service. Toute transaction, réservation, communication ou échange d'informations est effectuée entre utilisateurs sans intervention contractuelle directe de l'éditeur.

## 5. Utilisateurs vérifiés et non vérifiés

Les utilisateurs vérifiés disposent d'un badge visible et d'une information de confiance supplémentaire. Les utilisateurs non vérifiés peuvent utiliser la plateforme, mais la vérification ne crée pas de garantie absolue. Tous les utilisateurs restent responsables des contenus et des transactions qu'ils publient ou concluent.

## 6. Règles d'achat et de vente

Les annonces publiées doivent être conformes à la législation en vigueur et aux règles de la plateforme. Le vendeur doit décrire avec exactitude l'état du bien, son prix et ses conditions de vente. L'acheteur doit s'abstenir d'annonces frauduleuses, de sous-évaluation volontaire ou d'intentions de paiement fictives.

## 7. Fonctionnalité de réservation

La fonction de réservation permet de bloquer temporairement une annonce aux fins d'organisation d'une vente. La réservation ne constitue pas une garantie contractuelle définitive. Le vendeur peut accepter ou refuser une réservation, et l'acheteur doit confirmer l'accord final avant toute transaction.

## 8. Système de messagerie

La messagerie intégrée doit être utilisée pour échanger des informations liées aux annonces et aux rendez-vous. Les utilisateurs s'engagent à ne pas envoyer de messages harcelants, injurieux, publicitaires non sollicités ou de nature illégale.

## 9. Contenu et activités interdits

Les utilisateurs ne doivent pas publier de contenu ou mener d'activités qui sont :

- illégales, interdites ou contraires à l'ordre public ;
- diffamatoires, trompeuses ou agressives ;
- portant atteinte aux droits de propriété intellectuelle de tiers ;
- contrefaisant, dangereux ou réglementé ;
- destinées à la fraude, au phishing ou à l'usurpation d'identité.

L'éditeur se réserve le droit de supprimer toute annonce, message ou compte ne respectant pas ces règles.

## 10. Propriété intellectuelle

Tous les éléments de l'application (textes, logos, images, structures, codes, graphismes) sont protégés par le droit de la propriété intellectuelle. L'utilisation du service n'entraîne aucun transfert de droits sur ces éléments.

## 11. Confidentialité et données personnelles

Les données personnelles collectées sont traitées conformément à la politique de confidentialité de l'application. Les informations nécessaires à l'identification, à la gestion du compte et à l'amélioration du service peuvent être stockées. L'utilisateur dispose d'un droit d'accès, de rectification et de suppression de ses données.

## 12. Suspension ou résiliation de compte

L'éditeur peut suspendre, restreindre ou supprimer un compte en cas de violation de ces conditions, de comportement frauduleux ou d'utilisation abusive du service. En cas de résiliation, l'accès à l'application et aux fonctionnalités associées peut être interrompu sans préavis.

## 13. Limitation de responsabilité

La plateforme fournit un service d'intermédiation et ne peut être tenue responsable des transactions conclues entre utilisateurs, de la qualité des biens, des délais de livraison ou des pertes de données. L'utilisateur assume les risques liés à l'utilisation du service.

## 14. Modifications des conditions

L'éditeur se réserve le droit de modifier ces conditions à tout moment. Les modifications seront publiées sur l'application et entreront en vigueur dès leur mise en ligne. La poursuite de l'utilisation du service après mise à jour vaut acceptation des nouvelles conditions.

## 15. Droit applicable

Ces conditions sont régies par le droit algérien. En cas de litige, les tribunaux compétents seront ceux du lieu d'établissement de l'éditeur, sous réserve des dispositions légales impératives.

## 16. Contact

Pour toute question relative à ces conditions, l'utilisateur peut contacter le support via l'application ou par email à support@marketplace.com.
""";

    public static readonly string TermsHtml = """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Conditions Générales d'Utilisation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 0; background: #f9f9f9; color: #222; }
        .page { max-width: 960px; margin: 0 auto; padding: 2rem; background: #fff; }
        h1, h2, h3 { color: #1f2937; }
        h1 { margin-bottom: 0.5rem; }
        ul { margin: 0.5rem 0 1rem 1.5rem; }
        p { margin: 0.75rem 0; }
        .meta { color: #555; margin-bottom: 1.5rem; }
        .section { margin-bottom: 1.5rem; }
    </style>
</head>
<body>
    <div class="page">
        <h1>Conditions Générales d'Utilisation</h1>
        <p class="meta">Version 1.0 • Dernière mise à jour : 1 juillet 2026</p>

        <div class="section">
            <h2>1. Objet</h2>
            <p>Ces conditions générales d'utilisation régissent l'accès et l'utilisation de l'application mobile et du service en ligne de la marketplace. L'application permet aux utilisateurs d'acheter, de vendre, de réserver des annonces et de communiquer entre eux.</p>
        </div>

        <div class="section">
            <h2>2. Éligibilité</h2>
            <p>L'accès à l'application est réservé aux personnes physiques capables juridiquement d'accepter des conditions contractuelles. Les mineurs doivent obtenir l'autorisation d'un parent ou d'un tuteur légal pour utiliser le service.</p>
        </div>

        <div class="section">
            <h2>3. Inscription</h2>
            <p>Pour utiliser l'application, l'utilisateur doit créer un compte en fournissant des informations exactes, complètes et à jour. Il est responsable de la confidentialité de ses identifiants et de l'accès à son compte.</p>
        </div>

        <div class="section">
            <h2>4. Responsabilités des utilisateurs</h2>
            <p>L'utilisateur s'engage à utiliser la plateforme de bonne foi, à respecter les lois applicables et à ne pas perturber le fonctionnement du service. Toute transaction, réservation, ou communication est conclue entre utilisateurs sans intervention contractuelle directe de l'éditeur.</p>
        </div>

        <div class="section">
            <h2>5. Utilisateurs vérifiés et non vérifiés</h2>
            <p>Les utilisateurs vérifiés disposent d'un badge visible et d'une information de confiance supplémentaire. Les utilisateurs non vérifiés peuvent utiliser la plateforme, mais la vérification ne crée pas de garantie absolue.</p>
        </div>

        <div class="section">
            <h2>6. Règles d'achat et de vente</h2>
            <p>Les annonces doivent être conformes à la législation et aux règles de la plateforme. Le vendeur doit décrire avec exactitude l'état du bien, son prix et ses conditions de mise à disposition.</p>
        </div>

        <div class="section">
            <h2>7. Réservation</h2>
            <p>La fonction de réservation permet de bloquer temporairement une annonce afin d'organiser une vente. La réservation ne constitue pas une garantie contractuelle définitive et peut être annulée si les conditions ne sont pas respectées.</p>
        </div>

        <div class="section">
            <h2>8. Messagerie</h2>
            <p>La messagerie intégrée doit être utilisée pour échanger des informations liées aux annonces et aux rendez-vous. Les messages doivent être respectueux et pertinents.</p>
        </div>

        <div class="section">
            <h2>9. Contenu et activités interdits</h2>
            <p>Les utilisateurs ne doivent pas publier de contenu ou mener d'activités qui sont :</p>
            <ul>
                <li>illégales, interdites ou contraires à l'ordre public ;</li>
                <li>diffamatoires, trompeuses ou agressives ;</li>
                <li>portant atteinte aux droits de propriété intellectuelle de tiers ;</li>
                <li>contenants des éléments contrefaits, dangereux ou réglementés ;</li>
                <li>visant la fraude, le phishing ou l'usurpation d'identité.</li>
            </ul>
        </div>

        <div class="section">
            <h2>10. Propriété intellectuelle</h2>
            <p>Tous les éléments de l'application (textes, logos, images, codes, graphismes) sont protégés par le droit de la propriété intellectuelle. L'utilisation du service n'entraîne aucun transfert de droits sur ces éléments.</p>
        </div>

        <div class="section">
            <h2>11. Confidentialité et données personnelles</h2>
            <p>Les données personnelles collectées sont traitées conformément à la politique de confidentialité. Les informations nécessaires à l'identification, à la gestion du compte et à l'amélioration du service peuvent être stockées.</p>
        </div>

        <div class="section">
            <h2>12. Suspension ou résiliation de compte</h2>
            <p>L'éditeur peut suspendre, restreindre ou supprimer un compte en cas de violation des conditions, de comportement frauduleux ou d'utilisation abusive du service.</p>
        </div>

        <div class="section">
            <h2>13. Limitation de responsabilité</h2>
            <p>La plateforme fournit un service d'intermédiation et ne peut être tenue responsable des transactions conclues entre utilisateurs, de la qualité des biens ou des pertes de données.</p>
        </div>

        <div class="section">
            <h2>14. Modifications des conditions</h2>
            <p>L'éditeur se réserve le droit de modifier ces conditions à tout moment. Les modifications sont publiées sur l'application et entrent en vigueur dès leur mise en ligne.</p>
        </div>

        <div class="section">
            <h2>15. Droit applicable</h2>
            <p>Ces conditions sont régies par le droit algérien. En cas de litige, les tribunaux compétents seront ceux du lieu d'établissement de l'éditeur.</p>
        </div>

        <div class="section">
            <h2>16. Contact</h2>
            <p>Pour toute question relative à ces conditions, contactez le support via l'application ou par email à <a href="mailto:support@marketplace.com">support@marketplace.com</a>.</p>
        </div>
    </div>
</body>
</html>
""";
}
