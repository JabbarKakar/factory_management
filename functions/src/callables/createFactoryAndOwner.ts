import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * Sprint S32: atomically creates Auth user, factories/{id}, users/{uid} as owner.
 */
export const createFactoryAndOwner = onCall(async () => {
  throw new HttpsError(
    'unimplemented',
    'createFactoryAndOwner will be implemented in Sprint S32.',
  );
});
