// GH-93 TC-49: 위시를 지우거나 사진을 바꾸면 Storage의 예전 사진이 지워진다
import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';
import { setTimeout as sleep } from 'node:timers/promises';

import { cleanupWishPhoto, photoToDelete } from '../wishPhotoCleanup.js';
import { bucket, clearAll, db, photoNames, seed, syncedDoc, uploadPhoto } from './helpers.js';

const UID = 'alice';
const wish = (extra) => syncedDoc(UID, [UID], { photoFileName: 'w1-a.jpg', updatedAt: 100, ...extra });

beforeEach(clearAll);

test('test_GH93_TC49_삭제표시가_붙으면_그위시사진을지운다', async () => {
  await uploadPhoto(UID, 'w1-a.jpg');
  await uploadPhoto(UID, 'w2-b.jpg');

  const path = await cleanupWishPhoto({ bucket, before: wish(), after: wish({ deletedAt: 200, updatedAt: 200 }) });

  assert.equal(path, `wishPhotos/${UID}/w1-a.jpg`);
  assert.deepEqual(await photoNames(UID), [`wishPhotos/${UID}/w2-b.jpg`]);
});

test('test_GH93_TC49_사진을바꾸거나지우면_예전사진을지운다', async () => {
  assert.equal(photoToDelete(wish(), wish({ photoFileName: 'w1-b.jpg', updatedAt: 200 })), 'w1-a.jpg');
  assert.equal(photoToDelete(wish(), wish({ photoFileName: '', updatedAt: 200 })), 'w1-a.jpg');
});

test('test_GH93_TC49_늦게올라온옛값이나_사진이그대로면_지우지않는다', async () => {
  // 옛 값(updatedAt 이 더 작음)이 새 사진을 덮었다. 더 새 기기가 다시 올릴 때 새 사진 파일이 있어야 한다
  assert.equal(photoToDelete(wish({ photoFileName: 'w1-b.jpg', updatedAt: 200 }), wish({ updatedAt: 100 })), null);
  assert.equal(photoToDelete(wish(), wish({ title: '고침', updatedAt: 200 })), null);
  // 이미 지운 위시의 삭제 표시를 다시 올려도 다시 지우지 않는다
  assert.equal(photoToDelete(wish({ deletedAt: 150 }), wish({ deletedAt: 150, updatedAt: 200 })), null);
  assert.equal(photoToDelete(wish({ photoFileName: '' }), wish({ deletedAt: 200 })), null);
});

test('test_GH93_TC49_파일이이미없어도_실패하지않는다', async () => {
  const path = await cleanupWishPhoto({ bucket, before: wish(), after: wish({ deletedAt: 200 }) });
  assert.equal(path, `wishPhotos/${UID}/w1-a.jpg`);
});

test('test_GH93_TC49_위시문서를고치면_함수가돌아사진을지운다', { skip: !process.env.FUNCTIONS_EMULATOR_HOST && !process.env.FIREBASE_AUTH_EMULATOR_HOST && 'functions 에뮬레이터 없음' }, async () => {
  await uploadPhoto(UID, 'w1-a.jpg');
  await seed('wishes', 'w1', wish());

  await db.collection('wishes').doc('w1').set({ deletedAt: 200, updatedAt: 200 }, { merge: true });

  let removed = false;
  for (let i = 0; i < 120 && !removed; i += 1) {
    await sleep(500);
    removed = (await photoNames(UID)).length === 0;
  }
  assert.ok(removed, '60초 안에 함수가 돌지 않았다');
});
