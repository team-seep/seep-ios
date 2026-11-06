// GH-93 계정 삭제 때 서버 데이터 지우기 (TC-43·TC-44). firebase/README.md의 함수 테스트 명령으로 돈다
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { DELETED_USERS, eraseUserData, SYNCED_COLLECTIONS } from '../eraseUserData.js';
import { bucket, clearAll, db, photoNames, seed, syncedDoc, uploadPhoto } from './helpers.js';

beforeEach(clearAll);

describe('TC-43 탈퇴한 사용자의 서버 데이터를 지운다', () => {
  test('test_GH93_TC43_내문서_사진_users_지우고_탈퇴표시를_남긴다', async () => {
    for (const collection of SYNCED_COLLECTIONS) {
      await seed(collection, `a-${collection}`, syncedDoc('alice'));
      // 삭제 표시가 있는 문서도 지운다
      await seed(collection, `a-del-${collection}`, syncedDoc('alice', ['alice'], { deletedAt: 1_762_000_100 }));
    }
    await seed('users', 'alice', { createdAt: 1 });
    await uploadPhoto('alice', 'p1.jpg');
    await uploadPhoto('alice', 'p2.jpg');

    const result = await eraseUserData({ db, bucket, uid: 'alice' });

    assert.equal(result.deleted, SYNCED_COLLECTIONS.length * 2);
    for (const collection of SYNCED_COLLECTIONS) {
      const left = await db.collection(collection).where('ownerUid', '==', 'alice').get();
      assert.equal(left.size, 0, `${collection}에 alice 문서가 남았다`);
    }
    assert.equal((await db.collection('users').doc('alice').get()).exists, false);
    assert.deepEqual(await photoNames('alice'), []);
    assert.equal((await db.collection(DELETED_USERS).doc('alice').get()).exists, true);
  });

  test('test_GH93_TC43_다른사용자_데이터는_그대로', async () => {
    await seed('wishes', 'a1', syncedDoc('alice'));
    await seed('wishes', 'b1', syncedDoc('bob'));
    await seed('wishSteps', 'b1-s1', syncedDoc('bob', ['bob'], { wishId: 'b1' }));
    await seed('users', 'bob', { createdAt: 1 });
    await uploadPhoto('alice', 'p1.jpg');
    await uploadPhoto('bob', 'p1.jpg');
    // 경로 접두사가 겹치는 uid
    await uploadPhoto('alice2', 'p1.jpg');

    await eraseUserData({ db, bucket, uid: 'alice' });

    assert.equal((await db.collection('wishes').doc('b1').get()).exists, true);
    assert.equal((await db.collection('wishSteps').doc('b1-s1').get()).exists, true);
    assert.equal((await db.collection('users').doc('bob').get()).exists, true);
    assert.deepEqual(await photoNames('bob'), ['wishPhotos/bob/p1.jpg']);
    assert.deepEqual(await photoNames('alice2'), ['wishPhotos/alice2/p1.jpg']);
    assert.equal((await db.collection(DELETED_USERS).doc('bob').get()).exists, false);
  });

  // 같이 이루기(5단계) 대비: 남이 주인인 공유 위시는 지우지 않고 멤버에서만 뺀다
  test('test_GH93_TC43_남의_공유위시에서는_멤버에서만_빠진다', async () => {
    await seed('wishes', 'shared', syncedDoc('bob', ['bob', 'alice']));

    const result = await eraseUserData({ db, bucket, uid: 'alice' });

    const shared = await db.collection('wishes').doc('shared').get();
    assert.equal(shared.exists, true);
    assert.deepEqual(shared.get('memberUids'), ['bob']);
    assert.equal(result.detached, 1);
  });
});

describe('TC-44 여러 번·많이 불려도 안전하다', () => {
  test('test_GH93_TC44_두번_불러도_결과가_같다', async () => {
    await seed('wishes', 'a1', syncedDoc('alice'));
    await uploadPhoto('alice', 'p1.jpg');

    await eraseUserData({ db, bucket, uid: 'alice' });
    const second = await eraseUserData({ db, bucket, uid: 'alice' });

    assert.deepEqual(second, { deleted: 0, detached: 0 });
    assert.equal((await db.collection(DELETED_USERS).doc('alice').get()).exists, true);
  });

  test('test_GH93_TC44_한페이지보다_많은_문서도_모두_지운다', async () => {
    const writer = db.bulkWriter();
    for (let i = 0; i < 950; i += 1) {
      writer.set(db.collection('wishSteps').doc(`s${i}`), syncedDoc('alice', ['alice'], { wishId: 'a1' }));
    }
    await writer.close();

    const result = await eraseUserData({ db, bucket, uid: 'alice' });

    assert.equal(result.deleted, 950);
    assert.equal((await db.collection('wishSteps').count().get()).data().count, 0);
  });

  test('test_GH93_TC44_uid가_없으면_아무것도_지우지_않는다', async () => {
    await seed('wishes', 'a1', syncedDoc('alice'));
    await assert.rejects(eraseUserData({ db, bucket, uid: '' }));
    assert.equal((await db.collection('wishes').doc('a1').get()).exists, true);
  });
});
