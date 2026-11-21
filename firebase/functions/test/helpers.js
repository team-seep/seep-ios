// 에뮬레이터용 admin 앱. firebase emulators:exec가 *_EMULATOR_HOST 환경 변수를 넣어 준다
import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

export const PROJECT_ID = 'demo-seep';
export const BUCKET = `${PROJECT_ID}.appspot.com`;

for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  if (!process.env[name]) throw new Error(`${name}가 없다. firebase emulators:exec 안에서 돌린다 (firebase/README.md)`);
}

const app = getApps()[0] ?? initializeApp({ projectId: PROJECT_ID, storageBucket: BUCKET });
export const db = getFirestore(app);
export const bucket = getStorage(app).bucket(BUCKET);
export const auth = getAuth(app);

export async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
  await bucket.deleteFiles({ force: true }).catch(() => {});
}

export function syncedDoc(ownerUid, memberUids = [ownerUid], extra = {}) {
  return { ownerUid, memberUids, updatedAt: 1_762_000_000, deletedAt: null, ...extra };
}

export async function seed(collection, id, data) {
  await db.collection(collection).doc(id).set(data);
}

export async function uploadPhoto(uid, fileName) {
  await bucket.file(`wishPhotos/${uid}/${fileName}`).save(Buffer.from('jpeg'), { contentType: 'image/jpeg' });
}

export async function photoNames(uid) {
  const [files] = await bucket.getFiles({ prefix: `wishPhotos/${uid}/` });
  return files.map((file) => file.name);
}
