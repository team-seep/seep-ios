// GH-93 TC-45: Auth 사용자를 지우면 eraseDeletedUser 함수가 돌아 서버 데이터가 지워진다 (auth·functions 에뮬레이터)
import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';
import { setTimeout as sleep } from 'node:timers/promises';

import { DELETED_USERS } from '../eraseUserData.js';
import { auth, clearAll, db, photoNames, seed, syncedDoc, uploadPhoto } from './helpers.js';

beforeEach(clearAll);

test('test_GH93_TC45_Auth사용자_삭제시_함수가_데이터를_지운다', { skip: !process.env.FIREBASE_AUTH_EMULATOR_HOST && 'auth 에뮬레이터 없음' }, async () => {
  const user = await auth.createUser({ email: 'alice@example.com' });
  await seed('wishes', 'a1', syncedDoc(user.uid));
  await seed('wishSteps', 'a1-s1', syncedDoc(user.uid, [user.uid], { wishId: 'a1' }));
  await uploadPhoto(user.uid, 'p1.jpg');

  await auth.deleteUser(user.uid);

  // 트리거는 비동기로 돈다. 에뮬레이터 첫 실행은 함수 로딩이 느려 넉넉히 기다린다
  let erased = false;
  for (let i = 0; i < 120 && !erased; i += 1) {
    await sleep(500);
    erased = (await db.collection(DELETED_USERS).doc(user.uid).get()).exists
      && (await db.collection('wishes').doc('a1').get()).exists === false;
  }
  assert.ok(erased, '60초 안에 함수가 돌지 않았다');
  assert.equal((await db.collection('wishSteps').doc('a1-s1').get()).exists, false);
  assert.deepEqual(await photoNames(user.uid), []);
});
