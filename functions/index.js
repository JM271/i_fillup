const {onDocumentCreated} = require('firebase-functions/v2/firestore');
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

// Tells the host about a new refill request on every device they registered.
exports.notifyHostOfRequest = onDocumentCreated(
  {document: 'refillRequests/{requestId}', region},
  async (event) => {
    const request = event.data?.data();
    if (!request?.hostUid) return;

    const devices = getFirestore().doc(`devices/${request.hostUid}`);
    const tokens = (await devices.get()).get('tokens') ?? [];
    if (tokens.length === 0) return;

    const traveler = request.requester?.name || 'A traveler';
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: 'New refill request',
        body: `${traveler} would like ${request.liters} l at ${request.placeName}`,
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
