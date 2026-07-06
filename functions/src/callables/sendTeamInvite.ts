import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * Sprint S34: owner sends team invite (email + role).
 */
export const sendTeamInvite = onCall(async () => {
  throw new HttpsError(
    'unimplemented',
    'sendTeamInvite will be implemented in Sprint S34.',
  );
});
