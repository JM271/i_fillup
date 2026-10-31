# i fillup — Take water & Offer water

i fillup opens on a shared home page with **Take water** and **Offer water**. Both sections run inside the same app and use the same account and repository. **Home** returns to the chooser without discarding an unfinished offer.

- **Take water** (`lib/take_water_home.dart`): discover refill places, filter and search, inspect details and send refill requests.
- **Offer water** (`lib/offer_water_home.dart`): create water offers with an address, map pin, opening times and CHF price; manage your places and incoming requests.
- `lib/main.dart` is the single entry point; `lib/fillup_home.dart` is the shared home page.

## Run

```sh
flutter pub get
flutter run                 # Android/iOS device or emulator
flutter run -d chrome       # Web
```

The Android application ID is `com.example.i_fillup`. A VS Code launch configuration is included.

## Firebase setup

The apps use Firebase project `i-fillup`, email/password Firebase Authentication, and Cloud Firestore. FlutterFire options are in `lib/firebase_options.dart`.

The Android app `com.example.i_fillup` is registered in Firebase; its config is in `android/app/google-services.json`. The old `.taker` and `.giver` registrations are obsolete and can be deleted in the Firebase console.

The default Firestore database still needs to be created in the Firebase project. Device logs on 2026-10-31 confirm that the default database does not exist. Enable the Cloud Firestore API if prompted, then create the default Firestore database in `europe-west6` (Zurich), the region selected for the Swiss-first MVP.

Deploy the repository's Firestore security rules after the database is ready:

```sh
firebase deploy --only firestore:rules --project i-fillup
```

Enable **Email/Password** under Firebase Console → i-fillup → Authentication → Sign-in method. The app requires login, with account creation and password reset on the login screen. The **Account** button shows the current email and provides **Sign out**. Firebase restores the session on restart.

When an existing anonymous user creates a new account, credentials are linked to that UID, preserving ownership of their offers and requests. Logging into an already existing account uses that account's UID; it does not merge data from a different anonymous identity. Existing anonymous identities are retained until registration or login.

Offers are stored in `waterPlaces` and requests in `refillRequests`. Owners can manage their offers; requests are visible to their requester and host. Hosts can accept or decline pending requests.

## Connection status

Take water and Offer water share live offers and refill requests through Firestore once the database and rules above are deployed. The sample Swiss places remain demo data in widget previews only. There are no payments, payouts, or in-app messaging; travelers and hosts arrange payment directly.

The offer picker requests foreground location permission and starts at the current device position. My location recenters it; manual selection works if GPS or permission is unavailable. Existing pins are preserved on reopening. Browser geolocation requires HTTPS or localhost; map tiles need internet. Live GPS still needs device verification.

## Validate

```sh
flutter analyze
flutter test
flutter build web
```

## Address selection

In Offer water, choose **Choose address from list**, enter a street and town, and press **Search addresses**. Selecting a match fills the address and map coordinates. You can adjust the pin afterward. Editing the address manually clears the previous pin so you can confirm its new position.

Search uses the [Photon public demo API](https://github.com/komoot/photon), triggered only by an explicit search, with a small session cache. The search text is sent to Photon. Internet is required; manual address entry and map selection remain available. The public demo service has no availability guarantee and is intended for reasonable request volumes. Configure a private/hosted Photon endpoint for production with `--dart-define=ADDRESS_SEARCH_URL=https://your-server/api/`.

## Google Places address picker (Android)

Android now uses Google's native Places Autocomplete (New) picker through the `i_fillup/google_places` channel. It fetches the selected address and coordinates with the same session token. Cancelling keeps the existing address. Web/desktop retain the Photon picker.

Enable Places API (New) and billing in Google Cloud. Restrict the Android key to the package `com.example.i_fillup` and the certificate used to sign your build. Save it locally in `android/secrets.properties`:

```properties
PLACES_API_KEY=YOUR_ANDROID_RESTRICTED_KEY
```

This file is ignored by Git. Do not put the key in chat or commit it. The key is embedded in the Android build, so keep its Google Cloud app/API restrictions enabled. Rebuild after changing the key:

```sh
flutter run
```

Without a configured key the button displays a configuration message; it does not silently fall back to a different address provider. Live Google results must be verified after adding a valid key.

## Current recovery behavior

If Firebase sign-in fails (including CONFIGURATION_NOT_FOUND), startup explains the missing Anonymous provider, offers a retry, and provides an explicit preview without cloud. Preview offers are labeled as session-only. Saving an offer disables repeat submission until completion; failed saves preserve all entered values for retry.

The local refill-request rule now checks that the referenced place is active and the request's host UID matches its owner. The requester no longer has to own the host's place. The local rules passed 15 emulator checks on 2026-10-31 covering offer ownership, request creation, forged host rejection, request privacy and host-only status transitions. Deployment and a live request round trip remain pending until the database exists.

## Local rules verification

Start the Firestore emulator with project ID `demo-i-fillup`, port `8787` and `firestore.rules`, then run `python3 test/firestore_rules_test.py`. This test only contacts the local emulator and does not write production data.
