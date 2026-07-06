import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

interface CreateFactoryInput {
  email?: string;
  password?: string;
  name?: string;
  factoryName?: string;
  factoryPhone?: string;
  factoryAddress?: string;
}

interface CreateFactoryResult {
  factoryId: string;
  uid: string;
}

function requireText(value: unknown, field: string, minLength = 1): string {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  const trimmed = value.trim();
  if (trimmed.length < minLength) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return trimmed;
}

function optionalText(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function normalizeEmail(value: string): string {
  const email = value.trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }
  return email;
}

/**
 * Atomically creates Auth user, factories/{id}, and users/{uid} as owner.
 * Idempotent when retried after partial failure for the same email.
 */
export const createFactoryAndOwner = onCall(
  { region: 'us-central1' },
  async (request): Promise<CreateFactoryResult> => {
    const data = (request.data ?? {}) as CreateFactoryInput;

    const email = normalizeEmail(requireText(data.email, 'Email'));
    const password = requireText(data.password, 'Password', 6);
    if (password.length < 6) {
      throw new HttpsError(
        'invalid-argument',
        'Password must be at least 6 characters.',
      );
    }

    const name = requireText(data.name, 'Name');
    const factoryName = requireText(data.factoryName, 'Factory name');
    const factoryPhone = optionalText(data.factoryPhone);
    const factoryAddress = optionalText(data.factoryAddress);

    const auth = getAuth();
    const db = getFirestore();

    let uid: string;
    let createdAuthUser = false;

    try {
      const existing = await auth.getUserByEmail(email);
      uid = existing.uid;
    } catch (error: unknown) {
      const code = (error as { code?: string }).code;
      if (code !== 'auth/user-not-found') {
        throw new HttpsError('internal', 'Could not verify email availability.');
      }

      const created = await auth.createUser({
        email,
        password,
        displayName: name,
      });
      uid = created.uid;
      createdAuthUser = true;
    }

    const userRef = db.collection('users').doc(uid);
    const existingUser = await userRef.get();

    if (existingUser.exists) {
      const existingData = existingUser.data();
      const existingFactoryId = existingData?.factoryId as string | undefined;

      if (existingFactoryId && existingFactoryId.length > 0) {
        if (existingData?.role === 'owner') {
          return { factoryId: existingFactoryId, uid };
        }

        throw new HttpsError(
          'already-exists',
          'An account already exists for this email.',
        );
      }
    } else if (!createdAuthUser) {
      throw new HttpsError(
        'already-exists',
        'An account already exists for this email.',
      );
    }

    const factoryRef = db.collection('factories').doc();
    const factoryId = factoryRef.id;
    const batch = db.batch();

    batch.set(factoryRef, {
      name: factoryName,
      ownerName: name,
      ownerUserId: uid,
      status: 'active',
      ...(factoryPhone ? { phone: factoryPhone } : {}),
      ...(factoryAddress ? { address: factoryAddress } : {}),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    batch.set(
      userRef,
      {
        email,
        name,
        role: 'owner',
        factoryId,
        status: 'active',
        onboardingComplete: true,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    try {
      await batch.commit();
    } catch (error) {
      if (createdAuthUser) {
        try {
          await auth.deleteUser(uid);
        } catch {
          // Best-effort rollback; operator can reconcile orphaned auth users.
        }
      }
      throw new HttpsError(
        'internal',
        'Could not finish factory registration. Please try again.',
      );
    }

    return { factoryId, uid };
  },
);
