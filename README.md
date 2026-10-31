# i fillup — Take & Give

Two Flutter app entry points share models, styling, maps and location services.

- **Take:** `lib/main_taker.dart` — discover refill places, filter and search, inspect details and prepare demo refill requests.
- **Give:** `lib/main_giver.dart` — create water offers with an address, map pin, opening times and CHF price; review your places and the incoming-request placeholder.
- `lib/main.dart` remains the default taker entry point.

## Run on Android

```sh
flutter pub get
flutter run --flavor taker -t lib/main_taker.dart
flutter run --flavor giver -t lib/main_giver.dart
```

Android flavors have distinct application IDs (`com.example.i_fillup.taker` and `com.example.i_fillup.giver`) and launcher names, so both apps can be installed together. VS Code launch configurations are included; select an Android device.

## Web previews

Run each command in a separate terminal:

```sh
flutter run -d chrome -t lib/main_taker.dart --web-port 8080
flutter run -d chrome -t lib/main_giver.dart --web-port 8081
```

Other Flutter platforms can run either Dart entry point without `--flavor`. Separate iOS/macOS app identities and schemes have not yet been configured.

## Firebase setup

The apps use Firebase project `i-fillup`, anonymous Firebase Authentication, and Cloud Firestore. Firebase app registrations and FlutterFire options are checked in for the two Android flavors and the Web app.

The default Firestore database still needs to be created in the Firebase project. The project currently reports the Cloud Firestore API as disabled. Enable the Cloud Firestore API in Google Cloud, then create the default Firestore database in `europe-west6` (Zurich), the region selected for the Swiss-first MVP.

Deploy the repository's Firestore security rules after the database is ready:

```sh
firebase deploy --only firestore:rules --project i-fillup
```

Enable the **Anonymous** sign-in provider under Firebase Authentication before running either app. The apps sign users in anonymously and store offers in `waterPlaces` and refill requests in `refillRequests`. Active places are public to signed-in users; an offer is editable by its creator, and a request is visible only to its requester and the host. Hosts can accept or decline pending requests.

Anonymous IDs are local to each app installation. The Give app owns its offers, while the Take app creates requests addressed to the offer's host. Until account linking is added, clearing app data or uninstalling can lose the anonymous identity that owns an offer.

## Connection status

Take and Give share live offers and refill requests through Firestore once the database and rules above are deployed. The sample Swiss places remain demo data in widget previews only. There are no payments, payouts, or in-app messaging; travelers and hosts arrange payment directly.

The offer picker requests foreground location permission and starts at the current device position. My location recenters it; manual selection works if GPS or permission is unavailable. Existing pins are preserved on reopening. Browser geolocation requires HTTPS or localhost; map tiles need internet. Live GPS still needs device verification.

## Validate

```sh
flutter analyze
flutter test
flutter build web -t lib/main_taker.dart
flutter build web -t lib/main_giver.dart
```

## Switch apps on Android

Use **Give water** in the taker app's top bar and **Take water** in the giver app's top bar. Both Android flavors must be installed. Each flavor handles its own link (`ifillup-taker://home` or `ifillup-giver://home`). Switching opens the companion app; it does not synchronize demo data. Web and desktop previews currently show an explanatory message instead.

## Address selection

In Offer water, choose **Choose address from list**, enter a street and town, and press **Search addresses**. Selecting a match fills the address and map coordinates. You can adjust the pin afterward. Editing the address manually clears the previous pin so you can confirm its new position.

Search uses the [Photon public demo API](https://github.com/komoot/photon), triggered only by an explicit search, with a small session cache. The search text is sent to Photon. Internet is required; manual address entry and map selection remain available. The public demo service has no availability guarantee and is intended for reasonable request volumes. Configure a private/hosted Photon endpoint for production with `--dart-define=ADDRESS_SEARCH_URL=https://your-server/api/`.

## Google Places address picker (Android giver)

Android now uses Google's native Places Autocomplete (New) picker through the `i_fillup/google_places` channel. It fetches the selected address and coordinates with the same session token. Cancelling keeps the existing address. Web/desktop retain the Photon picker.

Enable Places API (New) and billing in Google Cloud. Restrict the Android key to the giver package and the certificate used to sign your build. Save it locally in `android/secrets.properties`:

```properties
PLACES_API_KEY=YOUR_ANDROID_RESTRICTED_KEY
```

This file is ignored by Git. Do not put the key in chat or commit it. The key is embedded in the Android build, so keep its Google Cloud app/API restrictions enabled. Rebuild after changing the key:

```sh
flutter run --flavor giver -t lib/main_giver.dart
```

Without a configured key the button displays a configuration message; it does not silently fall back to a different address provider. Live Google results must be verified after adding a valid key.

## Current recovery behavior

If Firebase sign-in fails (including CONFIGURATION_NOT_FOUND), startup explains the missing Anonymous provider, offers a retry, and provides an explicit preview without cloud. Preview offers are labeled as session-only. Saving an offer disables repeat submission until completion; failed saves preserve all entered values for retry.

The local refill-request rule now checks that the referenced place is active and the request's host UID matches its owner. The requester no longer has to own the host's place. This rules change still needs emulator verification and deployment before claiming live request delivery.
