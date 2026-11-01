import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'i fillup'**
  String get appName;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to i fillup'**
  String get welcome;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Fresh water. Shared journeys.'**
  String get tagline;

  /// No description provided for @takeWater.
  ///
  /// In en, this message translates to:
  /// **'Take water'**
  String get takeWater;

  /// No description provided for @takeWaterDescription.
  ///
  /// In en, this message translates to:
  /// **'Find a refill place, check the details and arrange your next fill-up.'**
  String get takeWaterDescription;

  /// No description provided for @offerWater.
  ///
  /// In en, this message translates to:
  /// **'Offer water'**
  String get offerWater;

  /// No description provided for @offerWaterDescription.
  ///
  /// In en, this message translates to:
  /// **'Share your water point, set your price and manage traveler requests.'**
  String get offerWaterDescription;

  /// No description provided for @switchToTake.
  ///
  /// In en, this message translates to:
  /// **'Take water'**
  String get switchToTake;

  /// No description provided for @switchToOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer water'**
  String get switchToOffer;

  /// No description provided for @homeFooter.
  ///
  /// In en, this message translates to:
  /// **'One app. Take water or offer water whenever you need.'**
  String get homeFooter;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageAuto;

  /// No description provided for @newRefillRequest.
  ///
  /// In en, this message translates to:
  /// **'You have a new refill request.'**
  String get newRefillRequest;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Please try again.'**
  String get signOutFailed;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @passwordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect.'**
  String get passwordIncorrect;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, your water place, your profile and your refill requests. It cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @keepAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get keepAccount;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleting;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address first.'**
  String get enterEmailFirst;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a password reset link has been sent.'**
  String get resetSent;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Log in instead.'**
  String get emailInUse;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password with at least 6 characters.'**
  String get weakPassword;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get wrongCredentials;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get checkConnection;

  /// No description provided for @signInDisabled.
  ///
  /// In en, this message translates to:
  /// **'Email/password sign-in must be enabled in Firebase Authentication.'**
  String get signInDisabled;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailed;

  /// No description provided for @couldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Please try again.'**
  String get couldNotConnect;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Fresh water for life on the road.'**
  String get loginTagline;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccount;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @photoOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo.'**
  String get photoOpenFailed;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This photo is too large. Choose another one.'**
  String get photoTooLarge;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @fillInField.
  ///
  /// In en, this message translates to:
  /// **'Please fill in this field'**
  String get fillInField;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @profileIntro.
  ///
  /// In en, this message translates to:
  /// **'Hosts see your profile on the refill requests you send them.'**
  String get profileIntro;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'First name or nickname'**
  String get nameHint;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @vehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Campervan, 6 m'**
  String get vehicleHint;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Only shared with hosts you send a request to.'**
  String get phoneHelper;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me (optional)'**
  String get aboutMe;

  /// No description provided for @aboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'Travelling with two kids and a dog, own hose'**
  String get aboutMeHint;

  /// No description provided for @vehiclePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of your vehicle (optional)'**
  String get vehiclePhoto;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get profileLoadFailed;

  /// No description provided for @noTravelerProfile.
  ///
  /// In en, this message translates to:
  /// **'No traveler profile (sent before profiles existed)'**
  String get noTravelerProfile;

  /// No description provided for @callPhone.
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String callPhone(String phone);

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on device location services, or choose a place manually.'**
  String get locationServicesOff;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Enable it in device or browser settings, or tap the map manually.'**
  String get locationBlocked;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. You can still tap the map to choose a place.'**
  String get locationDenied;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Finding your location took too long. Retry or tap the map manually.'**
  String get locationTimeout;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not access your location. Retry or tap the map manually.'**
  String get locationFailed;

  /// No description provided for @chooseYourPlace.
  ///
  /// In en, this message translates to:
  /// **'Choose your place'**
  String get chooseYourPlace;

  /// No description provided for @locationPickerIntro.
  ///
  /// In en, this message translates to:
  /// **'Start at your current location, then tap to adjust the refill pin. The address is entered separately.'**
  String get locationPickerIntro;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLocation;

  /// No description provided for @addressSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address search is unavailable. Please try again.'**
  String get addressSearchUnavailable;

  /// No description provided for @addressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters, including a town.'**
  String get addressTooShort;

  /// No description provided for @addressSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not search addresses. Check your internet connection and try again, or enter the address and choose its map pin manually.'**
  String get addressSearchFailed;

  /// No description provided for @chooseAnAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose an address'**
  String get chooseAnAddress;

  /// No description provided for @addressFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Street, house number and town'**
  String get addressFieldLabel;

  /// No description provided for @searchAddresses.
  ///
  /// In en, this message translates to:
  /// **'Search addresses'**
  String get searchAddresses;

  /// No description provided for @addressSearchIntro.
  ///
  /// In en, this message translates to:
  /// **'Search, then choose a match below. Check the pin before saving your offer.'**
  String get addressSearchIntro;

  /// No description provided for @noAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get noAddressesFound;

  /// No description provided for @noAddressesHint.
  ///
  /// In en, this message translates to:
  /// **'Try adding a postcode, town or country.'**
  String get noAddressesHint;

  /// No description provided for @googleIncompleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Google returned an incomplete address. Choose another result.'**
  String get googleIncompleteAddress;

  /// No description provided for @routeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route planning is unavailable. Please try again.'**
  String get routeUnavailable;

  /// No description provided for @noRouteFound.
  ///
  /// In en, this message translates to:
  /// **'No driving route found to this destination.'**
  String get noRouteFound;

  /// No description provided for @cloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud connection unavailable'**
  String get cloudUnavailable;

  /// No description provided for @firebaseAuthNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase sign-in is not configured for this project. In Firebase Console → i-fillup → Authentication, complete setup and enable the Email/Password sign-in provider.'**
  String get firebaseAuthNotConfigured;

  /// No description provided for @firebaseConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Firebase. Check your connection and Firebase setup, then retry.'**
  String get firebaseConnectFailed;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @retryCloud.
  ///
  /// In en, this message translates to:
  /// **'Retry cloud connection'**
  String get retryCloud;

  /// No description provided for @openPreview.
  ///
  /// In en, this message translates to:
  /// **'Open preview without cloud'**
  String get openPreview;

  /// No description provided for @previewNote.
  ///
  /// In en, this message translates to:
  /// **'Preview data stays on this screen session. Offers and requests are not shared with other users.'**
  String get previewNote;

  /// No description provided for @waterPlaces.
  ///
  /// In en, this message translates to:
  /// **'Water places'**
  String get waterPlaces;

  /// No description provided for @tapDrop.
  ///
  /// In en, this message translates to:
  /// **'Tap a water drop for details.'**
  String get tapDrop;

  /// No description provided for @viewPlace.
  ///
  /// In en, this message translates to:
  /// **'View {name}'**
  String viewPlace(String name);

  /// No description provided for @mapLegend.
  ///
  /// In en, this message translates to:
  /// **'Teal: private host · Dark: refill stop\nDrag to explore · Pinch to zoom · Map requires internet'**
  String get mapLegend;

  /// No description provided for @vehicleCampervan.
  ///
  /// In en, this message translates to:
  /// **'Campervan up to 6 m'**
  String get vehicleCampervan;

  /// No description provided for @vehicleMotorhome.
  ///
  /// In en, this message translates to:
  /// **'Motorhome 6–8 m'**
  String get vehicleMotorhome;

  /// No description provided for @vehicleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large motorhome over 8 m'**
  String get vehicleLarge;

  /// No description provided for @vehicleTrailer.
  ///
  /// In en, this message translates to:
  /// **'Caravan or trailer'**
  String get vehicleTrailer;

  /// No description provided for @serviceFarmShop.
  ///
  /// In en, this message translates to:
  /// **'Farm shop'**
  String get serviceFarmShop;

  /// No description provided for @serviceShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get serviceShop;

  /// No description provided for @serviceFood.
  ///
  /// In en, this message translates to:
  /// **'Café or restaurant'**
  String get serviceFood;

  /// No description provided for @serviceFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get serviceFuel;

  /// No description provided for @serviceCampsite.
  ///
  /// In en, this message translates to:
  /// **'Campsite or overnight parking'**
  String get serviceCampsite;

  /// No description provided for @serviceDump.
  ///
  /// In en, this message translates to:
  /// **'Waste water disposal'**
  String get serviceDump;

  /// No description provided for @serviceElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get serviceElectricity;

  /// No description provided for @serviceRepairs.
  ///
  /// In en, this message translates to:
  /// **'Workshop or repairs'**
  String get serviceRepairs;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @pricePerFill.
  ///
  /// In en, this message translates to:
  /// **'CHF {amount} / fill'**
  String pricePerFill(String amount);

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @atYourLocation.
  ///
  /// In en, this message translates to:
  /// **'At your location'**
  String get atYourLocation;

  /// No description provided for @atYourStart.
  ///
  /// In en, this message translates to:
  /// **'At your start'**
  String get atYourStart;

  /// No description provided for @afterDistance.
  ///
  /// In en, this message translates to:
  /// **'After {distance}'**
  String afterDistance(String distance);

  /// No description provided for @onRoute.
  ///
  /// In en, this message translates to:
  /// **'on route'**
  String get onRoute;

  /// No description provided for @offRoute.
  ///
  /// In en, this message translates to:
  /// **'{distance} off route'**
  String offRoute(String distance);

  /// No description provided for @areaPrice.
  ///
  /// In en, this message translates to:
  /// **'{area} · {price}'**
  String areaPrice(String area, String price);

  /// No description provided for @openingTimesValue.
  ///
  /// In en, this message translates to:
  /// **'Opening times: {times}'**
  String openingTimesValue(String times);

  /// No description provided for @suitableFor.
  ///
  /// In en, this message translates to:
  /// **'Suitable for: {vehicles}'**
  String suitableFor(String vehicles);

  /// No description provided for @alsoHere.
  ///
  /// In en, this message translates to:
  /// **'Also here'**
  String get alsoHere;

  /// No description provided for @alsoHereList.
  ///
  /// In en, this message translates to:
  /// **'Also here: {services}'**
  String alsoHereList(String services);

  /// No description provided for @demoListingNote.
  ///
  /// In en, this message translates to:
  /// **'Demo listing. Water quality, availability and prices have not been verified. Confirm drinking-water suitability with the host.'**
  String get demoListingNote;

  /// No description provided for @confirmWithHost.
  ///
  /// In en, this message translates to:
  /// **'Confirm water suitability, access and availability with the host before arriving.'**
  String get confirmWithHost;

  /// No description provided for @arrangeFillUp.
  ///
  /// In en, this message translates to:
  /// **'Arrange a fill-up with {host}'**
  String arrangeFillUp(String host);

  /// No description provided for @profileLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get profileLoadRetry;

  /// No description provided for @firstRequestIntro.
  ///
  /// In en, this message translates to:
  /// **'Before your first request, tell hosts who is coming. They see this profile on the requests you send them.'**
  String get firstRequestIntro;

  /// No description provided for @planFillUp.
  ///
  /// In en, this message translates to:
  /// **'Plan a fill-up'**
  String get planFillUp;

  /// No description provided for @toHost.
  ///
  /// In en, this message translates to:
  /// **'To {host}'**
  String toHost(String host);

  /// No description provided for @fromRequester.
  ///
  /// In en, this message translates to:
  /// **'From {name} · {vehicle}'**
  String fromRequester(String name, String vehicle);

  /// No description provided for @asap.
  ///
  /// In en, this message translates to:
  /// **'ASAP'**
  String get asap;

  /// No description provided for @asapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Request a fill-up as soon as possible'**
  String get asapTooltip;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @chooseDateTime.
  ///
  /// In en, this message translates to:
  /// **'Choose date & time'**
  String get chooseDateTime;

  /// No description provided for @arrivalInFuture.
  ///
  /// In en, this message translates to:
  /// **'Choose an arrival time in the future.'**
  String get arrivalInFuture;

  /// No description provided for @dateAtTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String dateAtTime(String date, String time);

  /// No description provided for @litersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Water needed (liters)'**
  String get litersNeeded;

  /// No description provided for @positiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number'**
  String get positiveNumber;

  /// No description provided for @arrivalMessage.
  ///
  /// In en, this message translates to:
  /// **'Arrival time & message'**
  String get arrivalMessage;

  /// No description provided for @arrivalMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at 10:00, with a 6 m campervan…'**
  String get arrivalMessageHint;

  /// No description provided for @arrivalMessageMissing.
  ///
  /// In en, this message translates to:
  /// **'Add your arrival time and a message'**
  String get arrivalMessageMissing;

  /// No description provided for @demoNoMessage.
  ///
  /// In en, this message translates to:
  /// **'Demo only. No message is sent to a host.'**
  String get demoNoMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveDemoRequest.
  ///
  /// In en, this message translates to:
  /// **'Save demo request'**
  String get saveDemoRequest;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send refill request'**
  String get sendRequest;

  /// No description provided for @litersAndMessage.
  ///
  /// In en, this message translates to:
  /// **'{liters} liters · {message}'**
  String litersAndMessage(int liters, String message);

  /// No description provided for @sendRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send request: {error}'**
  String sendRequestFailed(String error);

  /// No description provided for @deleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete request'**
  String get deleteRequest;

  /// No description provided for @deleteRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete request?'**
  String get deleteRequestTitle;

  /// No description provided for @deleteSentPendingBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from your requests and cancelled. The host will see that you cancelled it.'**
  String get deleteSentPendingBody;

  /// No description provided for @deleteRequestBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from your requests.'**
  String get deleteRequestBody;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @cancelAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Cancel and delete'**
  String get cancelAndDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete request: {error}'**
  String deleteRequestFailed(String error);

  /// No description provided for @requestDeleted.
  ///
  /// In en, this message translates to:
  /// **'Request deleted'**
  String get requestDeleted;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locating;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning…'**
  String get planning;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @chooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose a destination'**
  String get chooseDestination;

  /// No description provided for @nearYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Near your location'**
  String get nearYourLocation;

  /// No description provided for @toDestination.
  ///
  /// In en, this message translates to:
  /// **'To {destination}'**
  String toDestination(String destination);

  /// No description provided for @drivingFromYou.
  ///
  /// In en, this message translates to:
  /// **'Driving distance from where you are'**
  String get drivingFromYou;

  /// No description provided for @driveFromYou.
  ///
  /// In en, this message translates to:
  /// **'{distance} drive from your location'**
  String driveFromYou(String distance);

  /// No description provided for @updateMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Update my location'**
  String get updateMyLocation;

  /// No description provided for @changeDestination.
  ///
  /// In en, this message translates to:
  /// **'Change destination'**
  String get changeDestination;

  /// No description provided for @clearRoute.
  ///
  /// In en, this message translates to:
  /// **'Clear route'**
  String get clearRoute;

  /// No description provided for @within.
  ///
  /// In en, this message translates to:
  /// **'Within'**
  String get within;

  /// No description provided for @findWater.
  ///
  /// In en, this message translates to:
  /// **'Find water'**
  String get findWater;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @bannerTakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh water.\nOpen roads.'**
  String get bannerTakeTitle;

  /// No description provided for @bannerTakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Refill stops and private hosts for your campervan.'**
  String get bannerTakeSubtitle;

  /// No description provided for @searchPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Search a town or place'**
  String get searchPlaceHint;

  /// No description provided for @allPlaces.
  ///
  /// In en, this message translates to:
  /// **'All places'**
  String get allPlaces;

  /// No description provided for @privateHosts.
  ///
  /// In en, this message translates to:
  /// **'Private hosts'**
  String get privateHosts;

  /// No description provided for @refillStops.
  ///
  /// In en, this message translates to:
  /// **'Refill stops'**
  String get refillStops;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearMe;

  /// No description provided for @onMyRoute.
  ///
  /// In en, this message translates to:
  /// **'On my route'**
  String get onMyRoute;

  /// No description provided for @discoverRefill.
  ///
  /// In en, this message translates to:
  /// **'Discover a refill'**
  String get discoverRefill;

  /// No description provided for @placesWithinYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place within {km} km of you} other{{count} places within {km} km of you}}'**
  String placesWithinYou(int count, int km);

  /// No description provided for @placesWithinRoute.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place within {km} km of your route} other{{count} places within {km} km of your route}}'**
  String placesWithinRoute(int count, int km);

  /// No description provided for @demoPlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} demo places · Sample places in Switzerland'**
  String demoPlacesCount(int count);

  /// No description provided for @livePlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place · Live community listings} other{{count} places · Live community listings}}'**
  String livePlacesCount(int count);

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @placesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load places: {error}'**
  String placesLoadFailed(String error);

  /// No description provided for @noPlacesNearYou.
  ///
  /// In en, this message translates to:
  /// **'No places within {km} km of you. Try a wider distance.'**
  String noPlacesNearYou(int km);

  /// No description provided for @noPlacesNearRoute.
  ///
  /// In en, this message translates to:
  /// **'No places within {km} km of your route. Try a wider distance.'**
  String noPlacesNearRoute(int km);

  /// No description provided for @noPlacesMatch.
  ///
  /// In en, this message translates to:
  /// **'No places match. Try a different town or filter.'**
  String get noPlacesMatch;

  /// No description provided for @privateHost.
  ///
  /// In en, this message translates to:
  /// **'Private host'**
  String get privateHost;

  /// No description provided for @refillStop.
  ///
  /// In en, this message translates to:
  /// **'Refill stop'**
  String get refillStop;

  /// No description provided for @listFooter.
  ///
  /// In en, this message translates to:
  /// **'A small stop. A big help for your next adventure.'**
  String get listFooter;

  /// No description provided for @yourRequests.
  ///
  /// In en, this message translates to:
  /// **'Your requests'**
  String get yourRequests;

  /// No description provided for @demoRequestsNote.
  ///
  /// In en, this message translates to:
  /// **'Demo previews only. Nothing is sent, and previews clear when the app restarts.'**
  String get demoRequestsNote;

  /// No description provided for @requestsIntro.
  ///
  /// In en, this message translates to:
  /// **'Your refill requests and their status appear here.'**
  String get requestsIntro;

  /// No description provided for @nextStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next stop starts here'**
  String get nextStopTitle;

  /// No description provided for @nextStopHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a place and arrange a fill-up.'**
  String get nextStopHint;

  /// No description provided for @requestsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests: {error}'**
  String requestsLoadFailed(String error);

  /// No description provided for @requestSummary.
  ///
  /// In en, this message translates to:
  /// **'{liters} liters · {message}\nStatus: {status}'**
  String requestSummary(int liters, String message, String status);

  /// No description provided for @demoPrefix.
  ///
  /// In en, this message translates to:
  /// **'Demo · {text}'**
  String demoPrefix(String text);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get statusAccepted;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'declined'**
  String get statusDeclined;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get statusCancelled;

  /// No description provided for @onePlaceRule.
  ///
  /// In en, this message translates to:
  /// **'Each account can offer one water place, to keep listings trustworthy.'**
  String get onePlaceRule;

  /// No description provided for @keepPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep {name}?'**
  String keepPlaceTitle(String name);

  /// No description provided for @keepPlaceOnly.
  ///
  /// In en, this message translates to:
  /// **'It becomes your one water place and is listed for travelers again.'**
  String get keepPlaceOnly;

  /// No description provided for @keepPlaceOthers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{It becomes your one water place. Your other place will be deleted. Requests you already received stay in Requests.} other{It becomes your one water place. Your other {count} places will be deleted. Requests you already received stay in Requests.}}'**
  String keepPlaceOthers(int count);

  /// No description provided for @keepThisOne.
  ///
  /// In en, this message translates to:
  /// **'Keep this one'**
  String get keepThisOne;

  /// No description provided for @placesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update places: {error}'**
  String placesUpdateFailed(String error);

  /// No description provided for @isYourPlace.
  ///
  /// In en, this message translates to:
  /// **'{name} is your water place'**
  String isYourPlace(String name);

  /// No description provided for @deletePlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deletePlaceTitle(String name);

  /// No description provided for @deletePlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Travelers will no longer see this place. Requests you already received stay in Requests.'**
  String get deletePlaceBody;

  /// No description provided for @placeDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete place: {error}'**
  String placeDeleteFailed(String error);

  /// No description provided for @placeDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String placeDeleted(String name);

  /// No description provided for @theTraveler.
  ///
  /// In en, this message translates to:
  /// **'The traveler'**
  String get theTraveler;

  /// No description provided for @deleteReceivedPendingBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from your requests and declined. {traveler} will see that it was declined.'**
  String deleteReceivedPendingBody(String traveler);

  /// No description provided for @declineAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Decline and delete'**
  String get declineAndDelete;

  /// No description provided for @requestUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update request: {error}'**
  String requestUpdateFailed(String error);

  /// No description provided for @myPlaces.
  ///
  /// In en, this message translates to:
  /// **'My places'**
  String get myPlaces;

  /// No description provided for @yourWaterPlaces.
  ///
  /// In en, this message translates to:
  /// **'Your water places'**
  String get yourWaterPlaces;

  /// No description provided for @yourWaterPlacesIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage the places where travelers can refill.'**
  String get yourWaterPlacesIntro;

  /// No description provided for @noPlacesYet.
  ///
  /// In en, this message translates to:
  /// **'No places yet. Add your first water offer below.'**
  String get noPlacesYet;

  /// No description provided for @chooseOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Choose your one water place'**
  String get chooseOnePlace;

  /// No description provided for @chooseOnePlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Places marked \"Not listed\" are hidden from travelers. Tap \"Keep this one\" on the place you want to offer; the others are deleted.'**
  String get chooseOnePlaceBody;

  /// No description provided for @notListed.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get notListed;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMap;

  /// No description provided for @deletePlace.
  ///
  /// In en, this message translates to:
  /// **'Delete place'**
  String get deletePlace;

  /// No description provided for @demoOffersNote.
  ///
  /// In en, this message translates to:
  /// **'Demo only. Offers are not shared with the water taker app.'**
  String get demoOffersNote;

  /// No description provided for @activeOffersNote.
  ///
  /// In en, this message translates to:
  /// **'Your active offers are visible in Find water.'**
  String get activeOffersNote;

  /// No description provided for @alreadyOffer.
  ///
  /// In en, this message translates to:
  /// **'You already offer a place'**
  String get alreadyOffer;

  /// No description provided for @alreadyOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Each account can offer one water place, to keep listings trustworthy. Delete your place in My places to offer a different one.'**
  String get alreadyOfferBody;

  /// No description provided for @goToMyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Go to My places'**
  String get goToMyPlaces;

  /// No description provided for @incomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Incoming requests'**
  String get incomingRequests;

  /// No description provided for @incomingRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'New traveler requests will appear here.'**
  String get incomingRequestsEmpty;

  /// No description provided for @litersCount.
  ///
  /// In en, this message translates to:
  /// **'{liters} liters'**
  String litersCount(int liters);

  /// No description provided for @statusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLine(String status);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @paymentsNote.
  ///
  /// In en, this message translates to:
  /// **'Payments are arranged directly with travelers. The app does not collect payments or record earnings.'**
  String get paymentsNote;

  /// No description provided for @bannerOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer water.\nEarn cash.'**
  String get bannerOfferTitle;

  /// No description provided for @bannerOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your price for a campervan refill, add your place and choose your opening times.'**
  String get bannerOfferSubtitle;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get placeName;

  /// No description provided for @placeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Water at our farm'**
  String get placeNameHint;

  /// No description provided for @addressPlace.
  ///
  /// In en, this message translates to:
  /// **'Address / place'**
  String get addressPlace;

  /// No description provided for @addressPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Street, house number, postcode, town, country'**
  String get addressPlaceHint;

  /// No description provided for @googleSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google address search.'**
  String get googleSearchFailed;

  /// No description provided for @chooseAddressGoogle.
  ///
  /// In en, this message translates to:
  /// **'Choose address with Google'**
  String get chooseAddressGoogle;

  /// No description provided for @chooseAddressList.
  ///
  /// In en, this message translates to:
  /// **'Choose address from list'**
  String get chooseAddressList;

  /// No description provided for @choosePlaceOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose place on map'**
  String get choosePlaceOnMap;

  /// No description provided for @changeMapLocation.
  ///
  /// In en, this message translates to:
  /// **'Change map location'**
  String get changeMapLocation;

  /// No description provided for @pinAt.
  ///
  /// In en, this message translates to:
  /// **'Pin: {latitude}, {longitude}'**
  String pinAt(String latitude, String longitude);

  /// No description provided for @chooseOnMapError.
  ///
  /// In en, this message translates to:
  /// **'Choose your place on the map.'**
  String get chooseOnMapError;

  /// No description provided for @openingTimes.
  ///
  /// In en, this message translates to:
  /// **'Opening times'**
  String get openingTimes;

  /// No description provided for @openingTimesHint.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri: 08:00–18:00\nSat: 09:00–12:00\nSun: closed'**
  String get openingTimesHint;

  /// No description provided for @openingTimesHelper.
  ///
  /// In en, this message translates to:
  /// **'Include days, local times and any appointment requirements.'**
  String get openingTimesHelper;

  /// No description provided for @pricePerFillUp.
  ///
  /// In en, this message translates to:
  /// **'Price per fill-up'**
  String get pricePerFillUp;

  /// No description provided for @priceHelper.
  ///
  /// In en, this message translates to:
  /// **'One price per refill. Enter 0 to offer water for free.'**
  String get priceHelper;

  /// No description provided for @priceError.
  ///
  /// In en, this message translates to:
  /// **'Enter a price of 0 or more, with up to 2 decimals'**
  String get priceError;

  /// No description provided for @paymentNoteForm.
  ///
  /// In en, this message translates to:
  /// **'Payment is arranged directly with the traveler. The app does not collect payments or pay out earnings.'**
  String get paymentNoteForm;

  /// No description provided for @whichVehicles.
  ///
  /// In en, this message translates to:
  /// **'Which vehicles can reach the water?'**
  String get whichVehicles;

  /// No description provided for @chooseVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one vehicle type.'**
  String get chooseVehicle;

  /// No description provided for @placePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the water place (optional)'**
  String get placePhoto;

  /// No description provided for @promoteBusiness.
  ///
  /// In en, this message translates to:
  /// **'Promote your business (optional)'**
  String get promoteBusiness;

  /// No description provided for @promoteBusinessIntro.
  ///
  /// In en, this message translates to:
  /// **'Travelers who stop for water see what else you offer.'**
  String get promoteBusinessIntro;

  /// No description provided for @aboutBusiness.
  ///
  /// In en, this message translates to:
  /// **'About your business'**
  String get aboutBusiness;

  /// No description provided for @aboutBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'Organic farm shop: eggs, cheese and bread. Sat 08:00–12:00.'**
  String get aboutBusinessHint;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @websiteError.
  ///
  /// In en, this message translates to:
  /// **'Enter a full address starting with https://'**
  String get websiteError;

  /// No description provided for @localHost.
  ///
  /// In en, this message translates to:
  /// **'Local host'**
  String get localHost;

  /// No description provided for @contactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Contact and water suitability must be confirmed before visiting.'**
  String get contactConfirm;

  /// No description provided for @saveOfferFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Could not save offer: {error}'**
  String saveOfferFailedWith(String error);

  /// No description provided for @saveOfferFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save offer. Please try again.'**
  String get saveOfferFailed;

  /// No description provided for @saveOffer.
  ///
  /// In en, this message translates to:
  /// **'Save offer'**
  String get saveOffer;

  /// No description provided for @previewOfferNote.
  ///
  /// In en, this message translates to:
  /// **'Preview only: offers stay in this session and are not shared with travelers.'**
  String get previewOfferNote;

  /// No description provided for @liveOfferNote.
  ///
  /// In en, this message translates to:
  /// **'Your place will appear in Find water so travelers can send you refill requests.'**
  String get liveOfferNote;
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
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
