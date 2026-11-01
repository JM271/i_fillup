// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'i fillup';

  @override
  String get view => 'View';

  @override
  String get welcome => 'Welcome to i fillup';

  @override
  String get tagline => 'Fresh water. Shared journeys.';

  @override
  String get takeWater => 'Take water';

  @override
  String get takeWaterDescription =>
      'Find a refill place, check the details and arrange your next fill-up.';

  @override
  String get offerWater => 'Offer water';

  @override
  String get offerWaterDescription =>
      'Share your water point, set your price and manage traveler requests.';

  @override
  String get homeFooter =>
      'One app. Take water or offer water whenever you need.';

  @override
  String get home => 'Home';

  @override
  String get language => 'Language';

  @override
  String get languageAuto => 'Device language';

  @override
  String get newRefillRequest => 'You have a new refill request.';

  @override
  String get account => 'Account';

  @override
  String get yourAccount => 'Your account';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get close => 'Close';

  @override
  String get signOutFailed => 'Could not sign out. Please try again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get passwordIncorrect => 'The password is incorrect.';

  @override
  String get deleteAccountFailed =>
      'Could not delete your account. Please try again.';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account, your water place, your profile and your refill requests. It cannot be undone.';

  @override
  String get password => 'Password';

  @override
  String get keepAccount => 'Keep account';

  @override
  String get deleting => 'Deleting…';

  @override
  String get enterEmailFirst => 'Enter your email address first.';

  @override
  String get resetSent =>
      'If an account exists for this email, a password reset link has been sent.';

  @override
  String get emailInUse => 'This email already has an account. Log in instead.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get weakPassword =>
      'Choose a stronger password with at least 6 characters.';

  @override
  String get wrongCredentials => 'Email or password is incorrect.';

  @override
  String get tooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String get checkConnection => 'Check your internet connection and try again.';

  @override
  String get signInDisabled =>
      'Email/password sign-in must be enabled in Firebase Authentication.';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get couldNotConnect => 'Could not connect. Please try again.';

  @override
  String get loginTagline => 'Fresh water for life on the road.';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get logIn => 'Log in';

  @override
  String get email => 'Email';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get passwordTooShort => 'Use at least 6 characters.';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'Already have an account? Log in';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get photoOpenFailed => 'Could not open the photo.';

  @override
  String get photoTooLarge => 'This photo is too large. Choose another one.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get remove => 'Remove';

  @override
  String get fillInField => 'Please fill in this field';

  @override
  String get profileSaveFailed =>
      'Could not save your profile. Please try again.';

  @override
  String get yourProfile => 'Your profile';

  @override
  String get profileIntro =>
      'Hosts see your profile on the refill requests you send them.';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'First name or nickname';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get vehicleHint => 'Campervan, 6 m';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get phoneHelper => 'Only shared with hosts you send a request to.';

  @override
  String get aboutMe => 'About me (optional)';

  @override
  String get aboutMeHint => 'Travelling with two kids and a dog, own hose';

  @override
  String get vehiclePhoto => 'Photo of your vehicle (optional)';

  @override
  String get saving => 'Saving…';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileLoadFailed => 'Could not load your profile.';

  @override
  String get noTravelerProfile =>
      'No traveler profile (sent before profiles existed)';

  @override
  String callPhone(String phone) {
    return 'Call $phone';
  }

  @override
  String get locationServicesOff =>
      'Turn on device location services, or choose a place manually.';

  @override
  String get locationBlocked =>
      'Location access is blocked. Enable it in device or browser settings, or tap the map manually.';

  @override
  String get locationDenied =>
      'Location permission was denied. You can still tap the map to choose a place.';

  @override
  String get locationTimeout =>
      'Finding your location took too long. Retry or tap the map manually.';

  @override
  String get locationFailed =>
      'Could not access your location. Retry or tap the map manually.';

  @override
  String get chooseYourPlace => 'Choose your place';

  @override
  String get locationPickerIntro =>
      'Start at your current location, then tap to adjust the refill pin. The address is entered separately.';

  @override
  String get myLocation => 'My location';

  @override
  String get useThisLocation => 'Use this location';

  @override
  String get addressSearchUnavailable =>
      'Address search is unavailable. Please try again.';

  @override
  String get addressTooShort =>
      'Enter at least 3 characters, including a town.';

  @override
  String get addressSearchFailed =>
      'Could not search addresses. Check your internet connection and try again, or enter the address and choose its map pin manually.';

  @override
  String get chooseAnAddress => 'Choose an address';

  @override
  String get addressFieldLabel => 'Street, house number and town';

  @override
  String get searchAddresses => 'Search addresses';

  @override
  String get addressSearchIntro =>
      'Search, then choose a match below. Check the pin before saving your offer.';

  @override
  String get noAddressesFound => 'No addresses found';

  @override
  String get noAddressesHint => 'Try adding a postcode, town or country.';

  @override
  String get googleIncompleteAddress =>
      'Google returned an incomplete address. Choose another result.';

  @override
  String get routeUnavailable =>
      'Route planning is unavailable. Please try again.';

  @override
  String get noRouteFound => 'No driving route found to this destination.';

  @override
  String get cloudUnavailable => 'Cloud connection unavailable';

  @override
  String get firebaseAuthNotConfigured =>
      'Firebase sign-in is not configured for this project. In Firebase Console → i-fillup → Authentication, complete setup and enable the Email/Password sign-in provider.';

  @override
  String get firebaseConnectFailed =>
      'Could not connect to Firebase. Check your connection and Firebase setup, then retry.';

  @override
  String get connecting => 'Connecting…';

  @override
  String get retryCloud => 'Retry cloud connection';

  @override
  String get openPreview => 'Open preview without cloud';

  @override
  String get previewNote =>
      'Preview data stays on this screen session. Offers and requests are not shared with other users.';

  @override
  String get waterPlaces => 'Water places';

  @override
  String get tapDrop => 'Tap a water drop for details.';

  @override
  String viewPlace(String name) {
    return 'View $name';
  }

  @override
  String get mapLegend =>
      'Teal: private host · Dark: refill stop\nDrag to explore · Pinch to zoom · Map requires internet';

  @override
  String get vehicleCampervan => 'Campervan up to 6 m';

  @override
  String get vehicleMotorhome => 'Motorhome 6–8 m';

  @override
  String get vehicleLarge => 'Large motorhome over 8 m';

  @override
  String get vehicleTrailer => 'Caravan or trailer';

  @override
  String get serviceFarmShop => 'Farm shop';

  @override
  String get serviceShop => 'Shop';

  @override
  String get serviceFood => 'Café or restaurant';

  @override
  String get serviceFuel => 'Fuel';

  @override
  String get serviceCampsite => 'Campsite or overnight parking';

  @override
  String get serviceDump => 'Waste water disposal';

  @override
  String get serviceElectricity => 'Electricity';

  @override
  String get serviceRepairs => 'Workshop or repairs';

  @override
  String get free => 'Free';

  @override
  String pricePerFill(String amount) {
    return 'CHF $amount / fill';
  }

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get atYourLocation => 'At your location';

  @override
  String get atYourStart => 'At your start';

  @override
  String afterDistance(String distance) {
    return 'After $distance';
  }

  @override
  String get onRoute => 'on route';

  @override
  String offRoute(String distance) {
    return '$distance off route';
  }

  @override
  String areaPrice(String area, String price) {
    return '$area · $price';
  }

  @override
  String openingTimesValue(String times) {
    return 'Opening times: $times';
  }

  @override
  String suitableFor(String vehicles) {
    return 'Suitable for: $vehicles';
  }

  @override
  String get alsoHere => 'Also here';

  @override
  String alsoHereList(String services) {
    return 'Also here: $services';
  }

  @override
  String get demoListingNote =>
      'Demo listing. Water quality, availability and prices have not been verified. Confirm drinking-water suitability with the host.';

  @override
  String get confirmWithHost =>
      'Confirm water suitability, access and availability with the host before arriving.';

  @override
  String arrangeFillUp(String host) {
    return 'Arrange a fill-up with $host';
  }

  @override
  String get profileLoadRetry =>
      'Could not load your profile. Please try again.';

  @override
  String get firstRequestIntro =>
      'Before your first request, tell hosts who is coming. They see this profile on the requests you send them.';

  @override
  String get planFillUp => 'Plan a fill-up';

  @override
  String toHost(String host) {
    return 'To $host';
  }

  @override
  String fromRequester(String name, String vehicle) {
    return 'From $name · $vehicle';
  }

  @override
  String get asap => 'ASAP';

  @override
  String get asapTooltip => 'Request a fill-up as soon as possible';

  @override
  String get chooseDateTime => 'Choose date & time';

  @override
  String get arrivalInFuture => 'Choose an arrival time in the future.';

  @override
  String dateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get litersNeeded => 'Water needed (liters)';

  @override
  String get positiveNumber => 'Enter a positive number';

  @override
  String get arrivalMessage => 'Arrival time & message';

  @override
  String get arrivalMessageHint => 'Tomorrow at 10:00, with a 6 m campervan…';

  @override
  String get arrivalMessageMissing => 'Add your arrival time and a message';

  @override
  String get demoNoMessage => 'Demo only. No message is sent to a host.';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveDemoRequest => 'Save demo request';

  @override
  String get sendRequest => 'Send refill request';

  @override
  String litersAndMessage(int liters, String message) {
    return '$liters liters · $message';
  }

  @override
  String sendRequestFailed(String error) {
    return 'Could not send request: $error';
  }

  @override
  String get deleteRequest => 'Delete request';

  @override
  String get deleteRequestTitle => 'Delete request?';

  @override
  String get deleteSentPendingBody =>
      'It is removed from your requests and cancelled. The host will see that you cancelled it.';

  @override
  String get deleteRequestBody => 'It is removed from your requests.';

  @override
  String get keep => 'Keep';

  @override
  String get cancelAndDelete => 'Cancel and delete';

  @override
  String get delete => 'Delete';

  @override
  String deleteRequestFailed(String error) {
    return 'Could not delete request: $error';
  }

  @override
  String get requestDeleted => 'Request deleted';

  @override
  String get locating => 'Locating…';

  @override
  String get planning => 'Planning…';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get chooseDestination => 'Choose a destination';

  @override
  String get nearYourLocation => 'Near your location';

  @override
  String toDestination(String destination) {
    return 'To $destination';
  }

  @override
  String get drivingFromYou => 'Driving distance from where you are';

  @override
  String driveFromYou(String distance) {
    return '$distance drive from your location';
  }

  @override
  String get updateMyLocation => 'Update my location';

  @override
  String get changeDestination => 'Change destination';

  @override
  String get clearRoute => 'Clear route';

  @override
  String get within => 'Within';

  @override
  String get findWater => 'Find water';

  @override
  String get requests => 'Requests';

  @override
  String get bannerTakeTitle => 'Fresh water.\nOpen roads.';

  @override
  String get bannerTakeSubtitle =>
      'Refill stops and private hosts for your campervan.';

  @override
  String get searchPlaceHint => 'Search a town or place';

  @override
  String get allPlaces => 'All places';

  @override
  String get privateHosts => 'Private hosts';

  @override
  String get refillStops => 'Refill stops';

  @override
  String get all => 'All';

  @override
  String get nearMe => 'Near me';

  @override
  String get onMyRoute => 'On my route';

  @override
  String get discoverRefill => 'Discover a refill';

  @override
  String placesWithinYou(int count, int km) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places within $km km of you',
      one: '1 place within $km km of you',
    );
    return '$_temp0';
  }

  @override
  String placesWithinRoute(int count, int km) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places within $km km of your route',
      one: '1 place within $km km of your route',
    );
    return '$_temp0';
  }

  @override
  String demoPlacesCount(int count) {
    return '$count demo places · Sample places in Switzerland';
  }

  @override
  String livePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places · Live community listings',
      one: '1 place · Live community listings',
    );
    return '$_temp0';
  }

  @override
  String get map => 'Map';

  @override
  String get edit => 'Edit';

  @override
  String placesLoadFailed(String error) {
    return 'Could not load places: $error';
  }

  @override
  String noPlacesNearYou(int km) {
    return 'No places within $km km of you. Try a wider distance.';
  }

  @override
  String noPlacesNearRoute(int km) {
    return 'No places within $km km of your route. Try a wider distance.';
  }

  @override
  String get noPlacesMatch =>
      'No places match. Try a different town or filter.';

  @override
  String get privateHost => 'Private host';

  @override
  String get refillStop => 'Refill stop';

  @override
  String get listFooter => 'A small stop. A big help for your next adventure.';

  @override
  String get yourRequests => 'Your requests';

  @override
  String get demoRequestsNote =>
      'Demo previews only. Nothing is sent, and previews clear when the app restarts.';

  @override
  String get requestsIntro =>
      'Your refill requests and their status appear here.';

  @override
  String get nextStopTitle => 'Your next stop starts here';

  @override
  String get nextStopHint => 'Choose a place and arrange a fill-up.';

  @override
  String requestsLoadFailed(String error) {
    return 'Could not load requests: $error';
  }

  @override
  String requestSummary(int liters, String message, String status) {
    return '$liters liters · $message\nStatus: $status';
  }

  @override
  String demoPrefix(String text) {
    return 'Demo · $text';
  }

  @override
  String get statusPending => 'pending';

  @override
  String get statusAccepted => 'accepted';

  @override
  String get statusDeclined => 'declined';

  @override
  String get statusCancelled => 'cancelled';

  @override
  String get onePlaceRule =>
      'Each account can offer one water place, to keep listings trustworthy.';

  @override
  String keepPlaceTitle(String name) {
    return 'Keep $name?';
  }

  @override
  String get keepPlaceOnly =>
      'It becomes your one water place and is listed for travelers again.';

  @override
  String keepPlaceOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'It becomes your one water place. Your other $count places will be deleted. Requests you already received stay in Requests.',
      one: 'It becomes your one water place. Your other place will be deleted. Requests you already received stay in Requests.',
    );
    return '$_temp0';
  }

  @override
  String get keepThisOne => 'Keep this one';

  @override
  String placesUpdateFailed(String error) {
    return 'Could not update places: $error';
  }

  @override
  String isYourPlace(String name) {
    return '$name is your water place';
  }

  @override
  String deletePlaceTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deletePlaceBody =>
      'Travelers will no longer see this place. Requests you already received stay in Requests.';

  @override
  String placeDeleteFailed(String error) {
    return 'Could not delete place: $error';
  }

  @override
  String placeDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get theTraveler => 'The traveler';

  @override
  String deleteReceivedPendingBody(String traveler) {
    return 'It is removed from your requests and declined. $traveler will see that it was declined.';
  }

  @override
  String get declineAndDelete => 'Decline and delete';

  @override
  String requestUpdateFailed(String error) {
    return 'Could not update request: $error';
  }

  @override
  String get myPlaces => 'My place';

  @override
  String get yourWaterPlaces => 'Your water place';

  @override
  String get yourWaterPlacesIntro =>
      'Manage the place where travelers can refill.';

  @override
  String get noPlacesYet => 'No water place yet. Add yours below.';

  @override
  String get chooseOnePlace => 'Choose your one water place';

  @override
  String get chooseOnePlaceBody =>
      'Places marked \"Not listed\" are hidden from travelers. Tap \"Keep this one\" on the place you want to offer; the others are deleted.';

  @override
  String get notListed => 'Not listed';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get deletePlace => 'Delete place';

  @override
  String get demoOffersNote =>
      'Demo only. Your offer is not shared with travelers.';

  @override
  String get activeOffersNote => 'Your water place is visible in Find water.';

  @override
  String get alreadyOffer => 'You already offer a place';

  @override
  String get alreadyOfferBody =>
      'Each account can offer one water place, to keep listings trustworthy. Delete your place in My place to offer a different one.';

  @override
  String get goToMyPlaces => 'Go to My place';

  @override
  String get incomingRequests => 'Incoming requests';

  @override
  String get incomingRequestsEmpty => 'New traveler requests will appear here.';

  @override
  String litersCount(int liters) {
    return '$liters liters';
  }

  @override
  String statusLine(String status) {
    return 'Status: $status';
  }

  @override
  String get announceArrival => 'I’ve arrived';

  @override
  String get announceArrivalTitle => 'Announce your arrival?';

  @override
  String announceArrivalBody(String place) {
    return '$place gets a notification that you are there.';
  }

  @override
  String get announce => 'Announce';

  @override
  String get arrivalAnnounced => 'Arrival announced';

  @override
  String announceArrivalFailed(String error) {
    return 'Could not announce your arrival: $error';
  }

  @override
  String arrivedAt(String time) {
    return 'Arrived · $time';
  }

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get paymentsNote =>
      'Payments are arranged directly with travelers. The app does not collect payments or record earnings.';

  @override
  String get editPlace => 'Edit water place';

  @override
  String get editPlaceTitle => 'Edit your\nwater place';

  @override
  String get editPlaceSubtitle =>
      'Change any detail and save. Travelers see the update right away.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get bannerOfferTitle => 'Offer water.\nEarn cash.';

  @override
  String get bannerOfferSubtitle =>
      'Set your price for a campervan refill, add your place and choose your opening times.';

  @override
  String get placeName => 'Place name';

  @override
  String get placeNameHint => 'Water at our farm';

  @override
  String get addressPlace => 'Address / place';

  @override
  String get addressPlaceHint =>
      'Street, house number, postcode, town, country';

  @override
  String get googleSearchFailed => 'Could not open Google address search.';

  @override
  String get chooseAddressGoogle => 'Choose address with Google';

  @override
  String get chooseAddressList => 'Choose address from list';

  @override
  String get choosePlaceOnMap => 'Choose place on map';

  @override
  String get changeMapLocation => 'Change map location';

  @override
  String pinAt(String latitude, String longitude) {
    return 'Pin: $latitude, $longitude';
  }

  @override
  String get chooseOnMapError => 'Choose your place on the map.';

  @override
  String get openingTimes => 'Opening times';

  @override
  String get openingOnRequest => 'On request';

  @override
  String get openingOnRequestHelp =>
      'Travelers agree on a time with you in their request.';

  @override
  String get segmentOnRequest => 'On request';

  @override
  String get segmentHours => 'Hours';

  @override
  String get openingAlwaysShort => '24/7';

  @override
  String get openingAlways => 'Open 24 hours, every day';

  @override
  String get mondayToFriday => 'Monday–Friday';

  @override
  String get saturdaySunday => 'Saturday–Sunday';

  @override
  String get weekdaysShort => 'Mon–Fri';

  @override
  String get weekendShort => 'Sat–Sun';

  @override
  String get closed => 'closed';

  @override
  String get opens => 'Opens';

  @override
  String get closes => 'Closes';

  @override
  String get openingNeedOne =>
      'Open on weekdays or weekends, or choose On request.';

  @override
  String get openingOrder => 'The closing time must be after the opening time.';

  @override
  String previously(String text) {
    return 'Previously: $text';
  }

  @override
  String get pricePerFillUp => 'Price per fill-up';

  @override
  String get priceHelper =>
      'One price per refill. Enter 0 to offer water for free.';

  @override
  String get priceError => 'Enter a price of 0 or more, with up to 2 decimals';

  @override
  String get paymentNoteForm =>
      'Payment is arranged directly with the traveler. The app does not collect payments or pay out earnings.';

  @override
  String get whichVehicles => 'Which vehicles can reach the water?';

  @override
  String get chooseVehicle => 'Choose at least one vehicle type.';

  @override
  String get atTheTap => 'At the tap';

  @override
  String get hoseAvailable => 'Hose available';

  @override
  String get hoseAvailableHelp => 'Travelers can use your hose to fill up.';

  @override
  String get bringOwnHose => 'Bring your own hose';

  @override
  String get selfService => 'Self-service';

  @override
  String get selfServiceHelp =>
      'Travelers can fill up without you being there.';

  @override
  String get hostPresent => 'Host lets you fill up';

  @override
  String get placePhoto => 'Photo of the water place (optional)';

  @override
  String get promoteBusiness => 'Promote your business (optional)';

  @override
  String get promoteBusinessIntro =>
      'Travelers who stop for water see what else you offer.';

  @override
  String get aboutBusiness => 'About your business';

  @override
  String get aboutBusinessHint =>
      'Organic farm shop: eggs, cheese and bread. Sat 08:00–12:00.';

  @override
  String get website => 'Website';

  @override
  String get websiteError => 'Enter a full address starting with https://';

  @override
  String get localHost => 'Local host';

  @override
  String get contactConfirm =>
      'Contact and water suitability must be confirmed before visiting.';

  @override
  String saveOfferFailedWith(String error) {
    return 'Could not save offer: $error';
  }

  @override
  String get saveOfferFailed => 'Could not save offer. Please try again.';

  @override
  String get saveOffer => 'Save offer';

  @override
  String get previewOfferNote =>
      'Preview only: your offer stays in this session and is not shared with travelers.';

  @override
  String get liveOfferNote =>
      'Your place will appear in Find water so travelers can send you refill requests.';
}
