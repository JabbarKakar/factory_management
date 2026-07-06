import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * Sprint S34: invitee accepts invite and joins factory with assigned role.
 */
export const acceptTeamInvite = onCall(async () => {
  throw new HttpsError(
    'unimplemented',
    'acceptTeamInvite will be implemented in Sprint S34.',
  );
});
