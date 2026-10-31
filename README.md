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

The default Firestore database still needs to be created in the Firebase project. Device logs on 2026-10-31 confirm that the default database does not exist. Enable the Cloud Firestore API if prompted, then create the default Firestore database. (It was created in the `eur3` multi-region.)

Deploy the repository's Firestore security rules after the database is ready:

```sh
firebase deploy --only firestore:rules --project i-fillup
```

Enable **Email/Password** under Firebase Console → i-fillup → Authentication → Sign-in method. The app requires login, with account creation and password reset on the login screen. The **Account** button shows the current email and provides **Sign out**. Firebase restores the session on restart.

When an existing anonymous user creates a new account, credentials are linked to that UID, preserving ownership of their offers and requests. Logging into an already existing account uses that account's UID; it does not merge data from a different anonymous identity. Existing anonymous identities are retained until registration or login.

Offers are stored in `waterPlaces` and requests in `refillRequests`. Water takers have a private profile in `profiles/{uid}` (name, vehicle, optional phone and about me), edited under **Account → Edit profile** and required before their first request. Hosts choose which vehicles can reach their water (campervan up to 6 m, motorhome 6–8 m, large motorhome over 8 m, caravan or trailer). Under **Promote your business (optional)** hosts can list what else they offer (farm shop, shop, café or restaurant, fuel, campsite or overnight parking, waste water disposal, electricity, workshop), a short pitch (500 characters) and a website; travelers see this as **Also here** on the place. Places and profiles can each have one optional photo, shrunk on the phone to about 800 px and stored base64 in the Firestore document (no Cloud Storage needed on the Spark plan; rules cap it at 300,000 characters). Each request carries a copy of the profile so only the hosts a traveler contacts can see it; incoming requests show it with a call button. Each account can offer one water place: its document ID is the owner's UID, which the rules require on create. Places created before this rule have other IDs: Find water still lists an owner's only place, hides owners' extra places, and My places shows extras as **Not listed** with **Keep this one**, which copies the chosen place to the owner's UID and deletes the rest in one batch. Owners can manage their offers; requests are visible to their requester and host. Hosts can accept or decline pending requests. Hosts can also delete a request from their list (`hostHidden`); a pending one is declined at the same time so the traveler sees the outcome, and the traveler keeps their copy. Travelers can likewise delete requests from their own list (`requesterHidden`); a pending one is cancelled so the host sees it was withdrawn.

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

## Request notifications

Hosts get a push notification as soon as a traveler sends a refill request. When an account has a water place, the app asks for notification permission and stores the device's FCM token in `devices/{uid}` (owner-only by the rules; up to 10 devices). The `notifyHostOfRequest` Cloud Function in `functions/index.js` runs when a `refillRequests` document is created and sends "New refill request: <name> would like <liters> l at <place>" to the host's devices, removing tokens that are no longer valid. Tapping the notification opens Offer water → Requests; while the app is open a banner with **View** appears instead. Signing out removes the device's token.

Cloud Functions require the Blaze plan. The function's region must lie within the Firestore database location, which is the `eur3` multi-region, so it runs in `europe-west1` (set in `functions/index.js`). Deploy with Node.js 22 and the Firebase CLI:

```sh
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules --project i-fillup
```

iOS also needs the Push Notifications capability in Xcode and an APNs key uploaded in Firebase console → Project settings → Cloud Messaging; this has not been set up yet.

## Distance filters

Take water has three tabs above the list: **All**, **Near me** and **On my route**. Each tab keeps its own distance (**1 / 2 / 5 / 10 / 25 km**) and results while you switch.

- **Near me** locates the device and lists places within that driving distance, nearest first. The location button refreshes your position.
- **On my route** asks for a destination (Google picker on Android, Photon list elsewhere) and plans a driving route from the device location. It lists places within that distance of the route by road, in the order you reach them, with the distance from your start and how far each is off the route (half the extra driving there and back). **Map** draws the route.

Routing uses the [OSRM public demo server](https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server), which is free, has no availability guarantee and is intended for light use. Your location, any destination and the coordinates of nearby places are sent to it. For production, host OSRM or a compatible service and set `--dart-define=ROUTING_URL=https://your-server/`.

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

The local refill-request rule now checks that the referenced place is active and the request's host UID matches its owner. The requester no longer has to own the host's place. The local rules passed 15 emulator checks on 2026-10-31 (later rules for one place per account and deleting requests add six more checks, not yet run) covering offer ownership, request creation, forged host rejection, request privacy and host-only status transitions. Deployment and a live request round trip remain pending until the database exists.

## Local rules verification

Start the Firestore emulator with project ID `demo-i-fillup`, port `8787` and `firestore.rules`, then run `python3 test/firestore_rules_test.py`. This test only contacts the local emulator and does not write production data.
