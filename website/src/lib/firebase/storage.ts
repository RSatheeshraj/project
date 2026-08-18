import { getStorage } from 'firebase/storage';
import app from './client';

const storage = getStorage(app);
export default storage;
