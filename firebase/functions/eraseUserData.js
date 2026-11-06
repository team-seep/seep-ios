import { FieldValue } from 'firebase-admin/firestore';

// 앱 동기화 대상 컬렉션 (firestore.rules·SyncCollection과 같다)
export const SYNCED_COLLECTIONS = ['wishes', 'wishSteps', 'wishSavings', 'wishNotifications', 'wishJournals'];
export const DELETED_USERS = 'deletedUsers';
const PAGE = 400;

/**
 * 탈퇴한 사용자의 서버 데이터를 지운다 (GH-93 R-29, 설계 §8).
 * - 먼저 deletedUsers/{uid} 표시를 남긴다. Auth 사용자를 지워도 다른 기기의 ID 토큰은 최대 1시간 살아 있어서,
 *   그사이 올라오는 쓰기를 규칙이 이 표시로 막는다(firestore.rules notDeleted). 그래야 지운 뒤에 문서가 다시 생기지 않는다.
 * - 내가 주인인 문서는 지운다. 남의 공유 위시(같이 이루기, 5단계)에서는 멤버에서만 뺀다.
 * - users/{uid}와 Storage wishPhotos/{uid}/ 아래 사진을 지운다.
 * 여러 번 불려도 결과가 같다(재시도 안전).
 */
export async function eraseUserData({ db, bucket, uid }) {
  if (!uid) throw new Error('uid가 없다');

  await db.collection(DELETED_USERS).doc(uid).set({ deletedAt: FieldValue.serverTimestamp() });

  let deleted = 0;
  let detached = 0;
  for (const name of SYNCED_COLLECTIONS) {
    const collection = db.collection(name);
    deleted += await deleteAll(db, collection.where('ownerUid', '==', uid));
    detached += await detachFromShared(db, collection.where('memberUids', 'array-contains', uid), uid);
  }

  await db.recursiveDelete(db.collection('users').doc(uid));
  await bucket.deleteFiles({ prefix: `wishPhotos/${uid}/` });

  return { deleted, detached };
}

async function deleteAll(db, query) {
  let count = 0;
  for (;;) {
    const snapshot = await query.limit(PAGE).get();
    if (snapshot.empty) return count;
    const writer = db.bulkWriter();
    snapshot.docs.forEach((doc) => writer.delete(doc.ref));
    await writer.close();
    count += snapshot.size;
  }
}

async function detachFromShared(db, query, uid) {
  // 내 문서는 이미 지웠으니 남은 건 남이 주인인 문서뿐이다
  const snapshot = await query.get();
  if (snapshot.empty) return 0;
  const writer = db.bulkWriter();
  let count = 0;
  for (const doc of snapshot.docs) {
    if (doc.get('ownerUid') === uid) continue;
    writer.update(doc.ref, {
      memberUids: FieldValue.arrayRemove(uid),
      serverUpdatedAt: FieldValue.serverTimestamp(),
    });
    count += 1;
  }
  await writer.close();
  return count;
}
