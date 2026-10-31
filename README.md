# i fillup — Take water & Offer water

i fillup opens on a shared home page with **Take water** and **Offer water**. Both sections run inside the same app and use the same account and repository. **Home** returns to the chooser without discarding an unfinished offer. The two existing Android entry points remain compatible and both open this home page.

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

The apps use Firebase project `i-fillup`, email/password Firebase Authentication, and Cloud Firestore. Firebase app registrations and FlutterFire options are checked in for the two Android flavors and the Web app.

The default Firestore database still needs to be created in the Firebase project. Device logs on 2026-10-31 confirm that the default database does not exist. Enable the Cloud Firestore API if prompted, then create the default Firestore database in `europe-west6` (Zurich), the region selected for the Swiss-first MVP.

Deploy the repository's Firestore security rules after the database is ready:

```sh
firebase deploy --only firestore:rules --project i-fillup
```

Enable **Email/Password** under Firebase Console → i-fillup → Authentication → Sign-in method. Both apps now require login, with account creation and password reset on the login screen. The **Account** button shows the current email and provides **Sign out**. Firebase restores the session on restart; use the same credentials in Take and Give to access the same account.

When an existing anonymous user creates a new account, credentials are linked to that UID, preserving ownership of their offers and requests. Logging into an already existing account uses that account's UID; it does not merge data from a different anonymous identity. Existing anonymous identities are retained until registration or login.

Offers are stored in `waterPlaces` and requests in `refillRequests`. Owners can manage their offers; requests are visible to their requester and host. Hosts can accept or decline pending requests.

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

The shared home page opens either section inside the current app. The **Offer water** and **Take water** section buttons also switch internally; a second installation is not needed. Existing Android flavor IDs and deep links remain available for compatibility.

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

The local refill-request rule now checks that the referenced place is active and the request's host UID matches its owner. The requester no longer has to own the host's place. The local rules passed 15 emulator checks on 2026-10-31 covering offer ownership, request creation, forged host rejection, request privacy and host-only status transitions. Deployment and a live request round trip remain pending until the database exists.

## Local rules verification

Start the Firestore emulator with project ID `demo-i-fillup`, port `8787` and `firestore.rules`, then run `python3 test/firestore_rules_test.py`. This test only contacts the local emulator and does not write production data.
