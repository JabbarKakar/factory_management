import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * NOTE (S34): Team invites are handled entirely client-side + Firestore rules
 * because the project runs on the Spark plan (no Cloud Functions / Blaze).
 * The owner creates an `invites/{code}` doc and shares the code out-of-band;
 * the invitee accepts via a client batch (see AuthRepository.acceptInvite).
 * This callable is retained only as a stub for a possible future Blaze upgrade.
 */
export const sendTeamInvite = onCall(async () => {
  throw new HttpsError(
    'unimplemented',
    'Team invites are handled client-side; this Function is not deployed.',
  );
});
