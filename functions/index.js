const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const functionsV1 = require('firebase-functions/v1');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

// Must lie within the Firestore database location, the eur3 multi-region.
const region = 'europe-west1';

const staleTokenErrors = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

// The request notification in the language of the host's app.
const messages = {
  en: {
    title: 'New refill request',
    traveler: 'A traveler',
    body: (traveler, liters, place) =>
      `${traveler} would like ${liters} l at ${place}`,
  },
  de: {
    title: 'Neue Wasseranfrage',
    traveler: 'Eine reisende Person',
    body: (traveler, liters, place) =>
      `${traveler} möchte ${liters} l bei ${place}`,
  },
  fr: {
    title: 'Nouvelle demande d’eau',
    traveler: 'Un voyageur',
    body: (traveler, liters, place) =>
      `${traveler} souhaite ${liters} l à ${place}`,
  },
};

// Tells the host about a new refill request on every device they registered.
exports.notifyHostOfRequest = onDocumentCreated(
  {document: 'refillRequests/{requestId}', region},
  async (event) => {
    const request = event.data?.data();
    if (!request?.hostUid) return;

    const devices = getFirestore().doc(`devices/${request.hostUid}`);
    const snapshot = await devices.get();
    const tokens = snapshot.get('tokens') ?? [];
    if (tokens.length === 0) return;

    const text = messages[snapshot.get('language')] ?? messages.en;
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: text.title,
        body: text.body(
          request.requester?.name || text.traveler,
          request.liters,
          request.placeName,
        ),
      },
      data: {type: 'refillRequest', requestId: event.params.requestId},
      android: {priority: 'high'},
      apns: {payload: {aps: {sound: 'default'}}},
    });

    const stale = tokens.filter((_, index) =>
      staleTokenErrors.has(response.responses[index].error?.code));
    if (stale.length > 0) {
      await devices.update({tokens: FieldValue.arrayRemove(...stale)});
    }
  },
);

// Removes everything that belongs to a deleted account. Requests are deleted
// on both sides, as they hold the traveler's profile and the host's place.
exports.deleteUserData = functionsV1
  .region(region)
  .auth.user()
  .onDelete(async (user) => {
    const db = getFirestore();
    const [places, sent, received] = await Promise.all([
      db.collection('waterPlaces').where('ownerUid', '==', user.uid).get(),
      db.collection('refillRequests').where('requesterUid', '==', user.uid).get(),
      db.collection('refillRequests').where('hostUid', '==', user.uid).get(),
    ]);
    const writer = db.bulkWriter();
    for (const document of [...places.docs, ...sent.docs, ...received.docs]) {
      writer.delete(document.ref);
    }
    writer.delete(db.doc(`profiles/${user.uid}`));
    writer.delete(db.doc(`devices/${user.uid}`));
    await writer.close();
  });
