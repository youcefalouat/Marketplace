import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marketplace Contrôlée'**
  String get appTitle;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfile;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @saveTheme.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le theme sur cet appareil'**
  String get saveTheme;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get search;

  /// No description provided for @publish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publish;

  /// No description provided for @messages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @marketplaceListing.
  ///
  /// In fr, this message translates to:
  /// **'Petite annonce Marketplace'**
  String get marketplaceListing;

  /// No description provided for @viewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get viewDetails;

  /// No description provided for @moreOptions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get moreOptions;

  /// No description provided for @listingAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Annonce disponible'**
  String get listingAvailable;

  /// No description provided for @noMessages.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message'**
  String get noMessages;

  /// No description provided for @sendFirstMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez le premier message'**
  String get sendFirstMessage;

  /// No description provided for @chatMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre message...'**
  String get chatMessageHint;

  /// No description provided for @startConversation.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la conversation'**
  String get startConversation;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @myAnnonces.
  ///
  /// In fr, this message translates to:
  /// **'Mes annonces'**
  String get myAnnonces;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @discover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get discover;

  /// No description provided for @exploreByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Explorer par catégorie'**
  String get exploreByCategory;

  /// No description provided for @noAnnoncesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce disponible pour le moment.'**
  String get noAnnoncesAvailable;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune categorie disponible.'**
  String get noCategoriesAvailable;

  /// No description provided for @reload.
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get reload;

  /// No description provided for @viewAnnonces.
  ///
  /// In fr, this message translates to:
  /// **'Voir les annonces'**
  String get viewAnnonces;

  /// No description provided for @goodDeal.
  ///
  /// In fr, this message translates to:
  /// **'Bonne affaire'**
  String get goodDeal;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'{amount} DA'**
  String price(String amount);

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contacter'**
  String get contact;

  /// No description provided for @descriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionTitle;

  /// No description provided for @seller.
  ///
  /// In fr, this message translates to:
  /// **'Vendeur'**
  String get seller;

  /// No description provided for @rateSeller.
  ///
  /// In fr, this message translates to:
  /// **'Noter ce vendeur'**
  String get rateSeller;

  /// No description provided for @ratingSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Note envoyée avec succès !'**
  String get ratingSentSuccess;

  /// No description provided for @cannotOpenPhoneApp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application téléphone'**
  String get cannotOpenPhoneApp;

  /// No description provided for @mustBeLoggedInToMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour envoyer un message'**
  String get mustBeLoggedInToMessage;

  /// No description provided for @cannotChatWithSelf.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas discuter sur votre propre annonce'**
  String get cannotChatWithSelf;

  /// No description provided for @mustBeLoggedInToRate.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour noter un vendeur'**
  String get mustBeLoggedInToRate;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @commentOptional.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (optionnel)'**
  String get commentOptional;

  /// No description provided for @rate.
  ///
  /// In fr, this message translates to:
  /// **'Noter {name}'**
  String rate(String name);

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les catégories'**
  String get allCategories;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get all;

  /// No description provided for @subCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie'**
  String get subCategory;

  /// No description provided for @wilayas.
  ///
  /// In fr, this message translates to:
  /// **'Wilayas'**
  String get wilayas;

  /// No description provided for @selectWilayas.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner Wilayas'**
  String get selectWilayas;

  /// No description provided for @allWilayas.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les wilayas'**
  String get allWilayas;

  /// No description provided for @communes.
  ///
  /// In fr, this message translates to:
  /// **'Communes'**
  String get communes;

  /// No description provided for @selectCommunes.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner Communes'**
  String get selectCommunes;

  /// No description provided for @allCommunes.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les communes'**
  String get allCommunes;

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} sélectionnée(s)'**
  String selectedCount(int count);

  /// No description provided for @min.
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher...'**
  String get searchHint;

  /// No description provided for @noAnnoncesFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce trouvée'**
  String get noAnnoncesFound;

  /// No description provided for @newAnnonce.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle annonce'**
  String get newAnnonce;

  /// No description provided for @photosCount.
  ///
  /// In fr, this message translates to:
  /// **'Photos ({count}/5)'**
  String photosCount(int count);

  /// No description provided for @mainCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie principale'**
  String get mainCategory;

  /// No description provided for @condition.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get condition;

  /// No description provided for @newCondition.
  ///
  /// In fr, this message translates to:
  /// **'Neuf'**
  String get newCondition;

  /// No description provided for @usedCondition.
  ///
  /// In fr, this message translates to:
  /// **'Occasion'**
  String get usedCondition;

  /// No description provided for @title.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get title;

  /// No description provided for @priceDa.
  ///
  /// In fr, this message translates to:
  /// **'Prix (DA)'**
  String get priceDa;

  /// No description provided for @invalidPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get invalidPrice;

  /// No description provided for @exchangePossible.
  ///
  /// In fr, this message translates to:
  /// **'Échange possible'**
  String get exchangePossible;

  /// No description provided for @exchangeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'article peut être échangé contre un autre'**
  String get exchangeSubtitle;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @showPhone.
  ///
  /// In fr, this message translates to:
  /// **'Afficher mon numéro'**
  String get showPhone;

  /// No description provided for @showPhoneSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Si désactivé, les utilisateurs ne pourront pas vous appeler directement'**
  String get showPhoneSubtitle;

  /// No description provided for @wilaya.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @commune.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get commune;

  /// No description provided for @publishAnnonce.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'annonce'**
  String get publishAnnonce;

  /// No description provided for @compressingAndSending.
  ///
  /// In fr, this message translates to:
  /// **'Compression & Envoi...'**
  String get compressingAndSending;

  /// No description provided for @maxFivePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 5 photos autorisées'**
  String get maxFivePhotos;

  /// No description provided for @addAtLeastOnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins une photo'**
  String get addAtLeastOnePhoto;

  /// No description provided for @selectCategoryValidation.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une catégorie'**
  String get selectCategoryValidation;

  /// No description provided for @selectSubCategoryValidation.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une sous-catégorie'**
  String get selectSubCategoryValidation;

  /// No description provided for @enterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un titre'**
  String get enterTitle;

  /// No description provided for @titleMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Le titre doit contenir au moins 5 caractères'**
  String get titleMinLength;

  /// No description provided for @enterDescription.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une description'**
  String get enterDescription;

  /// No description provided for @descriptionMinLength.
  ///
  /// In fr, this message translates to:
  /// **'La description doit contenir au moins 20 caractères'**
  String get descriptionMinLength;

  /// No description provided for @enterPrice.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un prix'**
  String get enterPrice;

  /// No description provided for @enterPhone.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro de téléphone'**
  String get enterPhone;

  /// No description provided for @annonceCreatedPending.
  ///
  /// In fr, this message translates to:
  /// **'Annonce créée ! En attente de validation.'**
  String get annonceCreatedPending;

  /// No description provided for @creationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création'**
  String get creationError;

  /// No description provided for @imageCompressionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la compression des images: {error}'**
  String imageCompressionError(String error);

  /// No description provided for @verificationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vérification requise'**
  String get verificationRequired;

  /// No description provided for @phoneVerificationRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez vérifier votre numéro de téléphone avant de publier une annonce.'**
  String get phoneVerificationRequiredMessage;

  /// No description provided for @verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verify;

  /// No description provided for @errorWithMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String errorWithMessage(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
