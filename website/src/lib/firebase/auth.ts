/**
 * Firebase Auth singleton.
 * Initialized from the shared Firebase app instance.
 */

import { getAuth } from 'firebase/auth';
import firebaseApp from './client';

const auth = getAuth(firebaseApp);

export default auth;
