// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Marketplace Contrôlée';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get language => 'Langue';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get saveTheme => 'Enregistrer le theme sur cet appareil';

  @override
  String get home => 'Accueil';

  @override
  String get search => 'Recherche';

  @override
  String get publish => 'Publier';

  @override
  String get messages => 'Messages';

  @override
  String get marketplaceListing => 'Petite annonce Marketplace';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get listingAvailable => 'Annonce disponible';

  @override
  String get noMessages => 'Aucun message';

  @override
  String get sendFirstMessage => 'Envoyez le premier message';

  @override
  String get chatMessageHint => 'Votre message...';

  @override
  String get startConversation => 'Démarrer la conversation';

  @override
  String get profile => 'Profil';

  @override
  String get myAnnonces => 'Mes annonces';

  @override
  String get logout => 'Déconnexion';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get login => 'Connexion';

  @override
  String get discover => 'Découvrir';

  @override
  String get exploreByCategory => 'Explorer par catégorie';

  @override
  String get noAnnoncesAvailable => 'Aucune annonce disponible pour le moment.';

  @override
  String get noCategoriesAvailable => 'Aucune categorie disponible.';

  @override
  String get reload => 'Recharger';

  @override
  String get viewAnnonces => 'Voir les annonces';

  @override
  String get goodDeal => 'Bonne affaire';

  @override
  String price(String amount) {
    return '$amount DA';
  }

  @override
  String get call => 'Appeler';

  @override
  String get contact => 'Contacter';

  @override
  String get descriptionTitle => 'Description';

  @override
  String get seller => 'Vendeur';

  @override
  String get rateSeller => 'Noter ce vendeur';

  @override
  String get ratingSentSuccess => 'Note envoyée avec succès !';

  @override
  String get cannotOpenPhoneApp =>
      'Impossible d\'ouvrir l\'application téléphone';

  @override
  String get mustBeLoggedInToMessage =>
      'Vous devez être connecté pour envoyer un message';

  @override
  String get cannotChatWithSelf =>
      'Vous ne pouvez pas discuter sur votre propre annonce';

  @override
  String get mustBeLoggedInToRate =>
      'Vous devez être connecté pour noter un vendeur';

  @override
  String get retry => 'Réessayer';

  @override
  String get send => 'Envoyer';

  @override
  String get commentOptional => 'Commentaire (optionnel)';

  @override
  String rate(String name) {
    return 'Noter $name';
  }

  @override
  String get filters => 'Filtres';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get category => 'Catégorie';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get all => 'Toutes';

  @override
  String get subCategory => 'Sous-catégorie';

  @override
  String get wilayas => 'Wilayas';

  @override
  String get selectWilayas => 'Sélectionner Wilayas';

  @override
  String get allWilayas => 'Toutes les wilayas';

  @override
  String get communes => 'Communes';

  @override
  String get selectCommunes => 'Sélectionner Communes';

  @override
  String get allCommunes => 'Toutes les communes';

  @override
  String selectedCount(int count) {
    return '$count sélectionnée(s)';
  }

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get apply => 'Appliquer';

  @override
  String get searchHint => 'Rechercher...';

  @override
  String get noAnnoncesFound => 'Aucune annonce trouvée';

  @override
  String get newAnnonce => 'Nouvelle annonce';

  @override
  String photosCount(int count) {
    return 'Photos ($count/5)';
  }

  @override
  String get mainCategory => 'Catégorie principale';

  @override
  String get condition => 'État';

  @override
  String get newCondition => 'Neuf';

  @override
  String get usedCondition => 'Occasion';

  @override
  String get title => 'Titre';

  @override
  String get priceDa => 'Prix (DA)';

  @override
  String get invalidPrice => 'Prix invalide';

  @override
  String get exchangePossible => 'Échange possible';

  @override
  String get exchangeSubtitle => 'L\'article peut être échangé contre un autre';

  @override
  String get phone => 'Téléphone';

  @override
  String get gallery => 'Galerie';

  @override
  String get photo => 'Photo';

  @override
  String get showPhone => 'Afficher mon numéro';

  @override
  String get showPhoneSubtitle =>
      'Si désactivé, les utilisateurs ne pourront pas vous appeler directement';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get commune => 'Commune';

  @override
  String get publishAnnonce => 'Publier l\'annonce';

  @override
  String get compressingAndSending => 'Compression & Envoi...';

  @override
  String get maxFivePhotos => 'Maximum 5 photos autorisées';

  @override
  String get addAtLeastOnePhoto => 'Veuillez ajouter au moins une photo';

  @override
  String get selectCategoryValidation => 'Veuillez sélectionner une catégorie';

  @override
  String get selectSubCategoryValidation =>
      'Veuillez sélectionner une sous-catégorie';

  @override
  String get enterTitle => 'Veuillez entrer un titre';

  @override
  String get titleMinLength => 'Le titre doit contenir au moins 5 caractères';

  @override
  String get enterDescription => 'Veuillez entrer une description';

  @override
  String get descriptionMinLength =>
      'La description doit contenir au moins 20 caractères';

  @override
  String get enterPrice => 'Veuillez entrer un prix';

  @override
  String get enterPhone => 'Veuillez entrer un numéro de téléphone';

  @override
  String get annonceCreatedPending =>
      'Annonce créée ! En attente de validation.';

  @override
  String get creationError => 'Erreur lors de la création';

  @override
  String imageCompressionError(String error) {
    return 'Erreur lors de la compression des images: $error';
  }

  @override
  String get verificationRequired => 'Vérification requise';

  @override
  String get phoneVerificationRequiredMessage =>
      'Vous devez vérifier votre numéro de téléphone avant de publier une annonce.';

  @override
  String get verify => 'Vérifier';

  @override
  String errorWithMessage(String error) {
    return 'Erreur: $error';
  }
}
