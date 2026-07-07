import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * NOTE (S34): Invite acceptance is handled entirely client-side + Firestore
 * rules (no Cloud Functions / Blaze). The invitee signs up, reads their invite
 * by code, then a client batch creates their user doc and marks the invite
 * accepted, guarded by the `inviteAcceptBootstrap` rule.
 * This callable is retained only as a stub for a possible future Blaze upgrade.
 */
export const acceptTeamInvite = onCall(async () => {
  throw new HttpsError(
    'unimplemented',
    'Invite acceptance is handled client-side; this Function is not deployed.',
  );
});
