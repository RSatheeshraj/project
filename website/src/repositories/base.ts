/**
 * Centralised repository helpers & error types.
 * All repositories import from here.
 */

import auth from '@/lib/firebase/auth';

export class RepositoryError extends Error {
  constructor(
    message: string,
    public readonly cause?: unknown
  ) {
    super(message);
    this.name = 'RepositoryError';
  }
}

export function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

export function firestoreData(doc: { data(): unknown }): Record<string, unknown> {
  return doc.data() as Record<string, unknown>;
}
