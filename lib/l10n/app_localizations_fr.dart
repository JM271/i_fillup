// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'i fillup';

  @override
  String get view => 'Voir';

  @override
  String get welcome => 'Bienvenue sur i fillup';

  @override
  String get tagline => 'De l’eau fraîche. Des voyages partagés.';

  @override
  String get takeWater => 'Trouver de l’eau';

  @override
  String get takeWaterDescription =>
      'Trouvez un point d’eau, consultez les détails et organisez votre prochain plein.';

  @override
  String get offerWater => 'Offrir de l’eau';

  @override
  String get offerWaterDescription =>
      'Partagez votre point d’eau, fixez votre prix et gérez les demandes des voyageurs.';

  @override
  String get switchToTake => 'Trouver';

  @override
  String get switchToOffer => 'Offrir';

  @override
  String get homeFooter =>
      'Une seule app. Trouvez ou proposez de l’eau quand vous le souhaitez.';

  @override
  String get home => 'Accueil';

  @override
  String get language => 'Langue';

  @override
  String get languageAuto => 'Langue de l’appareil';

  @override
  String get newRefillRequest => 'Vous avez une nouvelle demande d’eau.';

  @override
  String get account => 'Compte';

  @override
  String get yourAccount => 'Votre compte';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get close => 'Fermer';

  @override
  String get signOutFailed =>
      'Impossible de se déconnecter. Veuillez réessayer.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get passwordIncorrect => 'Le mot de passe est incorrect.';

  @override
  String get deleteAccountFailed =>
      'Impossible de supprimer votre compte. Veuillez réessayer.';

  @override
  String get deleteAccountTitle => 'Supprimer votre compte ?';

  @override
  String get deleteAccountBody =>
      'Cela supprime définitivement votre compte, votre point d’eau, votre profil et vos demandes. Cette action est irréversible.';

  @override
  String get password => 'Mot de passe';

  @override
  String get keepAccount => 'Garder le compte';

  @override
  String get deleting => 'Suppression…';

  @override
  String get enterEmailFirst => 'Saisissez d’abord votre adresse e-mail.';

  @override
  String get resetSent =>
      'Si un compte existe pour cette adresse, un lien de réinitialisation a été envoyé.';

  @override
  String get emailInUse =>
      'Un compte existe déjà pour cette adresse. Connectez-vous plutôt.';

  @override
  String get invalidEmail => 'Saisissez une adresse e-mail valide.';

  @override
  String get weakPassword =>
      'Choisissez un mot de passe plus sûr d’au moins 6 caractères.';

  @override
  String get wrongCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get tooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get checkConnection =>
      'Vérifiez votre connexion Internet et réessayez.';

  @override
  String get signInDisabled =>
      'La connexion par e-mail et mot de passe doit être activée dans Firebase Authentication.';

  @override
  String get authFailed => 'L’authentification a échoué. Veuillez réessayer.';

  @override
  String get couldNotConnect => 'Connexion impossible. Veuillez réessayer.';

  @override
  String get loginTagline => 'De l’eau fraîche pour la vie sur la route.';

  @override
  String get createYourAccount => 'Créez votre compte';

  @override
  String get logIn => 'Se connecter';

  @override
  String get email => 'E-mail';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get enterPassword => 'Saisissez votre mot de passe.';

  @override
  String get passwordTooShort => 'Utilisez au moins 6 caractères.';

  @override
  String get pleaseWait => 'Veuillez patienter…';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get haveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get createAnAccount => 'Créer un compte';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get photoOpenFailed => 'Impossible d’ouvrir la photo.';

  @override
  String get photoTooLarge =>
      'Cette photo est trop grande. Choisissez-en une autre.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get choosePhoto => 'Choisir une photo';

  @override
  String get remove => 'Retirer';

  @override
  String get fillInField => 'Veuillez remplir ce champ';

  @override
  String get profileSaveFailed =>
      'Impossible d’enregistrer votre profil. Veuillez réessayer.';

  @override
  String get yourProfile => 'Votre profil';

  @override
  String get profileIntro =>
      'Les hôtes voient votre profil dans les demandes que vous leur envoyez.';

  @override
  String get name => 'Nom';

  @override
  String get nameHint => 'Prénom ou surnom';

  @override
  String get vehicle => 'Véhicule';

  @override
  String get vehicleHint => 'Fourgon aménagé, 6 m';

  @override
  String get phoneOptional => 'Téléphone (facultatif)';

  @override
  String get phoneHelper =>
      'Partagé uniquement avec les hôtes à qui vous envoyez une demande.';

  @override
  String get aboutMe => 'À propos de moi (facultatif)';

  @override
  String get aboutMeHint =>
      'En voyage avec deux enfants et un chien, tuyau personnel';

  @override
  String get vehiclePhoto => 'Photo de votre véhicule (facultatif)';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get saveProfile => 'Enregistrer le profil';

  @override
  String get profileLoadFailed => 'Impossible de charger votre profil.';

  @override
  String get noTravelerProfile =>
      'Pas de profil voyageur (envoyé avant l’existence des profils)';

  @override
  String callPhone(String phone) {
    return 'Appeler le $phone';
  }

  @override
  String get locationServicesOff =>
      'Activez la localisation de l’appareil ou choisissez un lieu manuellement.';

  @override
  String get locationBlocked =>
      'L’accès à la position est bloqué. Autorisez-le dans les réglages de l’appareil ou du navigateur, ou touchez la carte manuellement.';

  @override
  String get locationDenied =>
      'L’autorisation de localisation a été refusée. Vous pouvez toujours toucher la carte pour choisir un lieu.';

  @override
  String get locationTimeout =>
      'La localisation a pris trop de temps. Réessayez ou touchez la carte manuellement.';

  @override
  String get locationFailed =>
      'Impossible d’accéder à votre position. Réessayez ou touchez la carte manuellement.';

  @override
  String get chooseYourPlace => 'Choisissez votre lieu';

  @override
  String get locationPickerIntro =>
      'Commencez à votre position actuelle, puis touchez pour ajuster l’épingle du point d’eau. L’adresse se saisit séparément.';

  @override
  String get myLocation => 'Ma position';

  @override
  String get useThisLocation => 'Utiliser ce lieu';

  @override
  String get addressSearchUnavailable =>
      'La recherche d’adresse est indisponible. Veuillez réessayer.';

  @override
  String get addressTooShort =>
      'Saisissez au moins 3 caractères, avec une ville.';

  @override
  String get addressSearchFailed =>
      'La recherche d’adresse a échoué. Vérifiez votre connexion et réessayez, ou saisissez l’adresse et placez l’épingle manuellement.';

  @override
  String get chooseAnAddress => 'Choisir une adresse';

  @override
  String get addressFieldLabel => 'Rue, numéro et ville';

  @override
  String get searchAddresses => 'Rechercher des adresses';

  @override
  String get addressSearchIntro =>
      'Recherchez, puis choisissez un résultat ci-dessous. Vérifiez l’épingle avant d’enregistrer votre offre.';

  @override
  String get noAddressesFound => 'Aucune adresse trouvée';

  @override
  String get noAddressesHint =>
      'Essayez d’ajouter un code postal, une ville ou un pays.';

  @override
  String get googleIncompleteAddress =>
      'Google a renvoyé une adresse incomplète. Choisissez un autre résultat.';

  @override
  String get routeUnavailable =>
      'Le calcul d’itinéraire est indisponible. Veuillez réessayer.';

  @override
  String get noRouteFound => 'Aucun itinéraire trouvé vers cette destination.';

  @override
  String get cloudUnavailable => 'Connexion au cloud indisponible';

  @override
  String get firebaseAuthNotConfigured =>
      'La connexion Firebase n’est pas configurée pour ce projet. Dans Firebase Console → i-fillup → Authentication, terminez la configuration et activez E-mail/Mot de passe.';

  @override
  String get firebaseConnectFailed =>
      'Connexion à Firebase impossible. Vérifiez votre connexion et la configuration Firebase, puis réessayez.';

  @override
  String get connecting => 'Connexion…';

  @override
  String get retryCloud => 'Réessayer la connexion';

  @override
  String get openPreview => 'Ouvrir l’aperçu sans cloud';

  @override
  String get previewNote =>
      'Les données d’aperçu restent dans cette session. Les offres et demandes ne sont pas partagées.';

  @override
  String get waterPlaces => 'Points d’eau';

  @override
  String get tapDrop => 'Touchez une goutte pour voir les détails.';

  @override
  String viewPlace(String name) {
    return 'Voir $name';
  }

  @override
  String get mapLegend =>
      'Turquoise : hôte privé · Foncé : borne d’eau\nFaites glisser pour explorer · Pincez pour zoomer · Carte nécessitant Internet';

  @override
  String get vehicleCampervan => 'Fourgon jusqu’à 6 m';

  @override
  String get vehicleMotorhome => 'Camping-car 6–8 m';

  @override
  String get vehicleLarge => 'Grand camping-car de plus de 8 m';

  @override
  String get vehicleTrailer => 'Caravane ou remorque';

  @override
  String get serviceFarmShop => 'Vente à la ferme';

  @override
  String get serviceShop => 'Magasin';

  @override
  String get serviceFood => 'Café ou restaurant';

  @override
  String get serviceFuel => 'Carburant';

  @override
  String get serviceCampsite => 'Camping ou stationnement de nuit';

  @override
  String get serviceDump => 'Vidange des eaux usées';

  @override
  String get serviceElectricity => 'Électricité';

  @override
  String get serviceRepairs => 'Atelier ou réparations';

  @override
  String get free => 'Gratuit';

  @override
  String pricePerFill(String amount) {
    return 'CHF $amount / plein';
  }

  @override
  String distanceAway(String distance) {
    return 'à $distance';
  }

  @override
  String get atYourLocation => 'À votre position';

  @override
  String get atYourStart => 'Au départ';

  @override
  String afterDistance(String distance) {
    return 'Après $distance';
  }

  @override
  String get onRoute => 'sur l’itinéraire';

  @override
  String offRoute(String distance) {
    return 'à $distance de l’itinéraire';
  }

  @override
  String areaPrice(String area, String price) {
    return '$area · $price';
  }

  @override
  String openingTimesValue(String times) {
    return 'Horaires : $times';
  }

  @override
  String suitableFor(String vehicles) {
    return 'Adapté pour : $vehicles';
  }

  @override
  String get alsoHere => 'Aussi sur place';

  @override
  String alsoHereList(String services) {
    return 'Aussi sur place : $services';
  }

  @override
  String get demoListingNote =>
      'Annonce de démonstration. Qualité de l’eau, disponibilité et prix non vérifiés. Confirmez avec l’hôte que l’eau est potable.';

  @override
  String get confirmWithHost =>
      'Confirmez la qualité de l’eau, l’accès et la disponibilité avec l’hôte avant d’arriver.';

  @override
  String arrangeFillUp(String host) {
    return 'Organiser un plein avec $host';
  }

  @override
  String get profileLoadRetry =>
      'Impossible de charger votre profil. Veuillez réessayer.';

  @override
  String get firstRequestIntro =>
      'Avant votre première demande, dites aux hôtes qui arrive. Ils voient ce profil dans vos demandes.';

  @override
  String get planFillUp => 'Planifier un plein';

  @override
  String toHost(String host) {
    return 'À $host';
  }

  @override
  String fromRequester(String name, String vehicle) {
    return 'De $name · $vehicle';
  }

  @override
  String get asap => 'Dès que possible';

  @override
  String get asapTooltip => 'Demander un plein dès que possible';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get chooseDateTime => 'Choisir la date et l’heure';

  @override
  String get arrivalInFuture => 'Choisissez une heure d’arrivée future.';

  @override
  String dateAtTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String get litersNeeded => 'Eau nécessaire (litres)';

  @override
  String get positiveNumber => 'Saisissez un nombre positif';

  @override
  String get arrivalMessage => 'Heure d’arrivée et message';

  @override
  String get arrivalMessageHint => 'Demain à 10 h, avec un fourgon de 6 m…';

  @override
  String get arrivalMessageMissing =>
      'Indiquez votre heure d’arrivée et un message';

  @override
  String get demoNoMessage =>
      'Démo uniquement. Aucun message n’est envoyé à l’hôte.';

  @override
  String get cancel => 'Annuler';

  @override
  String get saveDemoRequest => 'Enregistrer la demande de démo';

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String litersAndMessage(int liters, String message) {
    return '$liters litres · $message';
  }

  @override
  String sendRequestFailed(String error) {
    return 'Impossible d’envoyer la demande : $error';
  }

  @override
  String get deleteRequest => 'Supprimer la demande';

  @override
  String get deleteRequestTitle => 'Supprimer la demande ?';

  @override
  String get deleteSentPendingBody =>
      'Elle est retirée de vos demandes et annulée. L’hôte verra que vous l’avez annulée.';

  @override
  String get deleteRequestBody => 'Elle est retirée de vos demandes.';

  @override
  String get keep => 'Garder';

  @override
  String get cancelAndDelete => 'Annuler et supprimer';

  @override
  String get delete => 'Supprimer';

  @override
  String deleteRequestFailed(String error) {
    return 'Impossible de supprimer la demande : $error';
  }

  @override
  String get requestDeleted => 'Demande supprimée';

  @override
  String get locating => 'Localisation…';

  @override
  String get planning => 'Calcul…';

  @override
  String get useMyLocation => 'Utiliser ma position';

  @override
  String get chooseDestination => 'Choisir une destination';

  @override
  String get nearYourLocation => 'Près de vous';

  @override
  String toDestination(String destination) {
    return 'Vers $destination';
  }

  @override
  String get drivingFromYou => 'Distance en voiture depuis votre position';

  @override
  String driveFromYou(String distance) {
    return '$distance de route depuis votre position';
  }

  @override
  String get updateMyLocation => 'Mettre à jour ma position';

  @override
  String get changeDestination => 'Changer de destination';

  @override
  String get clearRoute => 'Effacer l’itinéraire';

  @override
  String get within => 'Dans un rayon de';

  @override
  String get findWater => 'Trouver de l’eau';

  @override
  String get requests => 'Demandes';

  @override
  String get bannerTakeTitle => 'De l’eau fraîche.\nLa route libre.';

  @override
  String get bannerTakeSubtitle =>
      'Bornes d’eau et hôtes privés pour votre van.';

  @override
  String get searchPlaceHint => 'Rechercher une ville ou un lieu';

  @override
  String get allPlaces => 'Tous les lieux';

  @override
  String get privateHosts => 'Hôtes privés';

  @override
  String get refillStops => 'Bornes d’eau';

  @override
  String get all => 'Tous';

  @override
  String get nearMe => 'Près de moi';

  @override
  String get onMyRoute => 'Trajet';

  @override
  String get discoverRefill => 'Découvrir un point d’eau';

  @override
  String placesWithinYou(int count, int km) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux à moins de $km km',
      one: '1 lieu à moins de $km km',
    );
    return '$_temp0';
  }

  @override
  String placesWithinRoute(int count, int km) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux à moins de $km km de votre trajet',
      one: '1 lieu à moins de $km km de votre trajet',
    );
    return '$_temp0';
  }

  @override
  String demoPlacesCount(int count) {
    return '$count lieux de démo · Exemples en Suisse';
  }

  @override
  String livePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux · Annonces de la communauté',
      one: '1 lieu · Annonces de la communauté',
    );
    return '$_temp0';
  }

  @override
  String get map => 'Carte';

  @override
  String placesLoadFailed(String error) {
    return 'Impossible de charger les lieux : $error';
  }

  @override
  String noPlacesNearYou(int km) {
    return 'Aucun lieu à moins de $km km. Essayez une distance plus grande.';
  }

  @override
  String noPlacesNearRoute(int km) {
    return 'Aucun lieu à moins de $km km de votre trajet. Essayez une distance plus grande.';
  }

  @override
  String get noPlacesMatch =>
      'Aucun lieu ne correspond. Essayez une autre ville ou un autre filtre.';

  @override
  String get privateHost => 'Hôte privé';

  @override
  String get refillStop => 'Borne d’eau';

  @override
  String get listFooter =>
      'Un petit arrêt. Une grande aide pour votre prochaine aventure.';

  @override
  String get yourRequests => 'Vos demandes';

  @override
  String get demoRequestsNote =>
      'Aperçus de démo uniquement. Rien n’est envoyé et tout s’efface au redémarrage.';

  @override
  String get requestsIntro => 'Vos demandes et leur statut apparaissent ici.';

  @override
  String get nextStopTitle => 'Votre prochain arrêt commence ici';

  @override
  String get nextStopHint => 'Choisissez un lieu et organisez un plein.';

  @override
  String requestsLoadFailed(String error) {
    return 'Impossible de charger les demandes : $error';
  }

  @override
  String requestSummary(int liters, String message, String status) {
    return '$liters litres · $message\nStatut : $status';
  }

  @override
  String demoPrefix(String text) {
    return 'Démo · $text';
  }

  @override
  String get statusPending => 'en attente';

  @override
  String get statusAccepted => 'acceptée';

  @override
  String get statusDeclined => 'refusée';

  @override
  String get statusCancelled => 'annulée';

  @override
  String get onePlaceRule =>
      'Chaque compte peut proposer un seul point d’eau, pour des annonces fiables.';

  @override
  String keepPlaceTitle(String name) {
    return 'Garder $name ?';
  }

  @override
  String get keepPlaceOnly =>
      'Il devient votre unique point d’eau et est de nouveau visible pour les voyageurs.';

  @override
  String keepPlaceOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Il devient votre unique point d’eau. Vos $count autres lieux seront supprimés. Les demandes reçues restent dans Demandes.',
      one: 'Il devient votre unique point d’eau. Votre autre lieu sera supprimé. Les demandes reçues restent dans Demandes.',
    );
    return '$_temp0';
  }

  @override
  String get keepThisOne => 'Garder celui-ci';

  @override
  String placesUpdateFailed(String error) {
    return 'Impossible de mettre à jour les lieux : $error';
  }

  @override
  String isYourPlace(String name) {
    return '$name est votre point d’eau';
  }

  @override
  String deletePlaceTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get deletePlaceBody =>
      'Les voyageurs ne verront plus ce lieu. Les demandes reçues restent dans Demandes.';

  @override
  String placeDeleteFailed(String error) {
    return 'Impossible de supprimer le lieu : $error';
  }

  @override
  String placeDeleted(String name) {
    return '$name supprimé';
  }

  @override
  String get theTraveler => 'Le voyageur';

  @override
  String deleteReceivedPendingBody(String traveler) {
    return 'Elle est retirée de vos demandes et refusée. $traveler verra qu’elle a été refusée.';
  }

  @override
  String get declineAndDelete => 'Refuser et supprimer';

  @override
  String requestUpdateFailed(String error) {
    return 'Impossible de mettre à jour la demande : $error';
  }

  @override
  String get myPlaces => 'Mon lieu';

  @override
  String get yourWaterPlaces => 'Votre point d’eau';

  @override
  String get yourWaterPlacesIntro =>
      'Gérez le lieu où les voyageurs peuvent faire le plein.';

  @override
  String get noPlacesYet =>
      'Pas encore de point d’eau. Ajoutez le vôtre ci-dessous.';

  @override
  String get chooseOnePlace => 'Choisissez votre point d’eau';

  @override
  String get chooseOnePlaceBody =>
      'Les lieux marqués « Non affiché » sont masqués. Touchez « Garder celui-ci » sur le lieu à proposer ; les autres sont supprimés.';

  @override
  String get notListed => 'Non affiché';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get deletePlace => 'Supprimer le lieu';

  @override
  String get demoOffersNote =>
      'Démo uniquement. Votre offre n’est pas partagée avec les voyageurs.';

  @override
  String get activeOffersNote =>
      'Votre point d’eau est visible dans « Trouver de l’eau ».';

  @override
  String get alreadyOffer => 'Vous proposez déjà un lieu';

  @override
  String get alreadyOfferBody =>
      'Chaque compte peut proposer un seul point d’eau, pour des annonces fiables. Supprimez votre lieu dans « Mon lieu » pour en proposer un autre.';

  @override
  String get goToMyPlaces => 'Aller à « Mon lieu »';

  @override
  String get incomingRequests => 'Demandes reçues';

  @override
  String get incomingRequestsEmpty =>
      'Les nouvelles demandes des voyageurs apparaîtront ici.';

  @override
  String litersCount(int liters) {
    return '$liters litres';
  }

  @override
  String statusLine(String status) {
    return 'Statut : $status';
  }

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get paymentsNote =>
      'Les paiements se règlent directement avec les voyageurs. L’app n’encaisse aucun paiement et n’enregistre aucun revenu.';

  @override
  String get editPlace => 'Modifier le point d’eau';

  @override
  String get editPlaceTitle => 'Modifier votre\npoint d’eau';

  @override
  String get editPlaceSubtitle =>
      'Modifiez ce que vous voulez et enregistrez. Les voyageurs voient la mise à jour immédiatement.';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get changesSaved => 'Modifications enregistrées';

  @override
  String get bannerOfferTitle => 'Proposez de l’eau.\nGagnez de l’argent.';

  @override
  String get bannerOfferSubtitle =>
      'Fixez votre prix pour un plein, ajoutez votre lieu et choisissez vos horaires.';

  @override
  String get placeName => 'Nom du lieu';

  @override
  String get placeNameHint => 'De l’eau à notre ferme';

  @override
  String get addressPlace => 'Adresse / lieu';

  @override
  String get addressPlaceHint => 'Rue, numéro, code postal, ville, pays';

  @override
  String get googleSearchFailed =>
      'Impossible d’ouvrir la recherche d’adresse Google.';

  @override
  String get chooseAddressGoogle => 'Choisir l’adresse avec Google';

  @override
  String get chooseAddressList => 'Choisir l’adresse dans la liste';

  @override
  String get choosePlaceOnMap => 'Choisir le lieu sur la carte';

  @override
  String get changeMapLocation => 'Modifier le lieu sur la carte';

  @override
  String pinAt(String latitude, String longitude) {
    return 'Épingle : $latitude, $longitude';
  }

  @override
  String get chooseOnMapError => 'Choisissez votre lieu sur la carte.';

  @override
  String get openingTimes => 'Horaires';

  @override
  String get openingTimesHint =>
      'Lun–ven : 08:00–18:00\nSam : 09:00–12:00\nDim : fermé';

  @override
  String get openingTimesHelper =>
      'Indiquez les jours, les heures et si un rendez-vous est nécessaire.';

  @override
  String get pricePerFillUp => 'Prix par plein';

  @override
  String get priceHelper =>
      'Un prix par plein. Saisissez 0 pour offrir l’eau gratuitement.';

  @override
  String get priceError =>
      'Saisissez un prix de 0 ou plus, avec au plus 2 décimales';

  @override
  String get paymentNoteForm =>
      'Le paiement se règle directement avec le voyageur. L’app n’encaisse ni ne verse aucun paiement.';

  @override
  String get whichVehicles => 'Quels véhicules peuvent accéder à l’eau ?';

  @override
  String get chooseVehicle => 'Choisissez au moins un type de véhicule.';

  @override
  String get placePhoto => 'Photo du point d’eau (facultatif)';

  @override
  String get promoteBusiness => 'Faites connaître votre activité (facultatif)';

  @override
  String get promoteBusinessIntro =>
      'Les voyageurs qui s’arrêtent pour l’eau voient ce que vous proposez d’autre.';

  @override
  String get aboutBusiness => 'À propos de votre activité';

  @override
  String get aboutBusinessHint =>
      'Vente à la ferme bio : œufs, fromage et pain. Sam 08:00–12:00.';

  @override
  String get website => 'Site web';

  @override
  String get websiteError =>
      'Saisissez une adresse complète commençant par https://';

  @override
  String get localHost => 'Hôte local';

  @override
  String get contactConfirm =>
      'Le contact et la qualité de l’eau doivent être confirmés avant la visite.';

  @override
  String saveOfferFailedWith(String error) {
    return 'Impossible d’enregistrer l’offre : $error';
  }

  @override
  String get saveOfferFailed =>
      'Impossible d’enregistrer l’offre. Veuillez réessayer.';

  @override
  String get saveOffer => 'Enregistrer l’offre';

  @override
  String get previewOfferNote =>
      'Aperçu uniquement : votre offre reste dans cette session et n’est pas partagée.';

  @override
  String get liveOfferNote =>
      'Votre lieu apparaîtra dans « Trouver de l’eau » pour que les voyageurs puissent vous envoyer des demandes.';
}
