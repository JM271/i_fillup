const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
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

// Notifications in the language of the receiver's app.
const messages = {
  en: {
    title: 'New refill request',
    traveler: 'A traveler',
    body: (traveler, liters, place) =>
      `${traveler} would like ${liters} l at ${place}`,
    accepted: {
      title: 'Request accepted',
      body: (place) => `${place} accepted your refill request.`,
    },
    declined: {
      title: 'Request declined',
      body: (place) => `${place} declined your refill request.`,
    },
  },
  de: {
    title: 'Neue Wasseranfrage',
    traveler: 'Eine reisende Person',
    body: (traveler, liters, place) =>
      `${traveler} möchte ${liters} l bei ${place}`,
    accepted: {
      title: 'Anfrage angenommen',
      body: (place) => `${place} hat deine Wasseranfrage angenommen.`,
    },
    declined: {
      title: 'Anfrage abgelehnt',
      body: (place) => `${place} hat deine Wasseranfrage abgelehnt.`,
    },
  },
  fr: {
    title: 'Nouvelle demande d’eau',
    traveler: 'Un voyageur',
    body: (traveler, liters, place) =>
      `${traveler} souhaite ${liters} l à ${place}`,
    accepted: {
      title: 'Demande acceptée',
      body: (place) => `${place} a accepté votre demande d’eau.`,
    },
    declined: {
      title: 'Demande refusée',
      body: (place) => `${place} a refusé votre demande d’eau.`,
    },
  },
};

// Sends a notification to every device the user registered, written by
// [notification] in the language stored with those devices.
async function notifyUser(uid, notification, data) {
  const devices = getFirestore().doc(`devices/${uid}`);
  const snapshot = await devices.get();
  const tokens = snapshot.get('tokens') ?? [];
  if (tokens.length === 0) return;

  const text = messages[snapshot.get('language')] ?? messages.en;
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: notification(text),
    data,
    // The channel is created by the app (MainActivity.kt) with sound on.
    android: {
      priority: 'high',
      notification: {channelId: 'refill_requests', defaultSound: true},
    },
    apns: {payload: {aps: {sound: 'default'}}},
  });

  const stale = tokens.filter((_, index) =>
    staleTokenErrors.has(response.responses[index].error?.code));
  if (stale.length > 0) {
    await devices.update({tokens: FieldValue.arrayRemove(...stale)});
  }
}

// Tells the host about a new refill request.
exports.notifyHostOfRequest = onDocumentCreated(
  {document: 'refillRequests/{requestId}', region},
  async (event) => {
    const request = event.data?.data();
    if (!request?.hostUid) return;

    await notifyUser(
      request.hostUid,
      (text) => ({
        title: text.title,
        body: text.body(
          request.requester?.name || text.traveler,
          request.liters,
          request.placeName,
        ),
      }),
      {type: 'refillRequest', requestId: event.params.requestId},
    );
  },
);

// Tells the traveler when the host accepts or declines their request.
exports.notifyTravelerOfAnswer = onDocumentUpdated(
  {document: 'refillRequests/{requestId}', region},
  async (event) => {
    const before = event.data?.before.data();
    const request = event.data?.after.data();
    if (!request?.requesterUid || before?.status !== 'pending') return;
    const status = request.status;
    if (status !== 'accepted' && status !== 'declined') return;

    await notifyUser(
      request.requesterUid,
      (text) => ({
        title: text[status].title,
        body: text[status].body(request.placeName),
      }),
      {type: 'requestAnswer', requestId: event.params.requestId, status},
    );
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
