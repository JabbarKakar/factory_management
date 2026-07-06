import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * Sprint S34: owner revokes a pending team invite.
 */
export const revokeTeamInvite = onCall(async () => {
  throw new HttpsError(
    'unimplemented',
    'revokeTeamInvite will be implemented in Sprint S34.',
  );
});
