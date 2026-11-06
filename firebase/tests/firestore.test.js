// GH-93 Firestore 보안 규칙 (TC-1 ~ TC-6). 에뮬레이터에서 돈다: firebase emulators:exec (firebase/README.md)
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc, writeBatch } from 'firebase/firestore';

const COLLECTIONS = ['wishes', 'wishSteps', 'wishSavings', 'wishNotifications', 'wishJournals'];

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-seep',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

function syncedDoc(uid, extra = {}) {
  return {
    ownerUid: uid,
    memberUids: [uid],
    updatedAt: 1_762_000_000,
    deletedAt: null,
    serverUpdatedAt: serverTimestamp(),
    schemaVersion: 'v7',
    ...extra,
  };
}

/// 규칙을 거치지 않고 A의 문서를 미리 넣어 둔다
async function seedOwnedBy(uid, collection, id) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), collection, id), syncedDoc(uid, { title: '파스타' }));
  });
}

describe('TC-1 로그인하지 않으면 읽기·쓰기 불가', () => {
  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC1_${collection}_비로그인_거부`, async () => {
      await seedOwnedBy('alice', collection, 'w1');
      const db = env.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(db, collection, 'w1')));
      await assertFails(setDoc(doc(db, collection, 'w2'), syncedDoc('alice')));
    });
  }

  test('test_GH93_TC1_users_비로그인_거부', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'users', 'alice')));
  });
});

describe('TC-2 본인 문서는 만들고 읽고 고칠 수 있다', () => {
  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC2_${collection}_본인_생성읽기수정_성공`, async () => {
      const db = env.authenticatedContext('alice').firestore();
      const ref = doc(db, collection, 'w1');
      await assertSucceeds(setDoc(ref, syncedDoc('alice')));
      await assertSucceeds(getDoc(ref));
      await assertSucceeds(updateDoc(ref, { updatedAt: 1_762_000_100, serverUpdatedAt: serverTimestamp() }));
    });
  }

  test('test_GH93_TC2_users_본인_읽기쓰기_성공', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertSucceeds(setDoc(doc(db, 'users', 'alice'), { createdAt: 1 }));
    await assertSucceeds(getDoc(doc(db, 'users', 'alice')));
  });
});

describe('TC-3 남의 문서는 읽거나 고칠 수 없다', () => {
  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC3_${collection}_타인_읽기수정_거부`, async () => {
      await seedOwnedBy('alice', collection, 'w1');
      const db = env.authenticatedContext('bob').firestore();
      const ref = doc(db, collection, 'w1');
      await assertFails(getDoc(ref));
      await assertFails(updateDoc(ref, { title: '바꿈' }));
    });
  }

  test('test_GH93_TC3_users_타인_거부', async () => {
    const db = env.authenticatedContext('bob').firestore();
    await assertFails(getDoc(doc(db, 'users', 'alice')));
    await assertFails(setDoc(doc(db, 'users', 'alice'), { createdAt: 1 }));
  });
});

describe('TC-4 주인·멤버를 속인 문서는 만들 수 없다', () => {
  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC4_${collection}_남의ownerUid_거부`, async () => {
      const db = env.authenticatedContext('bob').firestore();
      await assertFails(setDoc(doc(db, collection, 'w1'), syncedDoc('alice')));
    });

    test(`test_GH93_TC4_${collection}_남을memberUids에_거부`, async () => {
      const db = env.authenticatedContext('alice').firestore();
      await assertFails(setDoc(doc(db, collection, 'w1'), syncedDoc('alice', { memberUids: ['alice', 'bob'] })));
    });
  }
});

describe('TC-5 ownerUid·memberUids는 바꿀 수 없다', () => {
  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC5_${collection}_주인멤버변경_거부`, async () => {
      await seedOwnedBy('alice', collection, 'w1');
      const db = env.authenticatedContext('alice').firestore();
      const ref = doc(db, collection, 'w1');
      await assertFails(updateDoc(ref, { ownerUid: 'bob' }));
      await assertFails(updateDoc(ref, { memberUids: ['alice', 'bob'] }));
    });
  }
});

describe('TC-6 문서 삭제는 주인도 못 한다', () => {
  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC6_${collection}_삭제_거부`, async () => {
      await seedOwnedBy('alice', collection, 'w1');
      const db = env.authenticatedContext('alice').firestore();
      await assertFails(deleteDoc(doc(db, collection, 'w1')));
      // 삭제는 deletedAt 표시로만
      await assertSucceeds(updateDoc(doc(db, collection, 'w1'), { deletedAt: 1_762_000_200 }));
    });
  }
});

describe('정해 둔 컬렉션 밖은 모두 거부', () => {
  test('test_GH93_TC1_모르는컬렉션_거부', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'publicWishes', 'w1'), syncedDoc('alice')));
    await assertFails(getDoc(doc(db, 'publicWishes', 'w1')));
  });
});

describe('TC-42 탈퇴 표시가 있으면 쓰기를 막는다', () => {
  async function markDeleted(uid) {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'deletedUsers', uid), { deletedAt: serverTimestamp() });
    });
  }

  for (const collection of COLLECTIONS) {
    test(`test_GH93_TC42_${collection}_탈퇴표시후_쓰기거부`, async () => {
      await seedOwnedBy('alice', collection, 'w1');
      await markDeleted('alice');
      const db = env.authenticatedContext('alice').firestore();
      await assertFails(setDoc(doc(db, collection, 'w2'), syncedDoc('alice')));
      await assertFails(updateDoc(doc(db, collection, 'w1'), { title: '라멘' }));
    });
  }

  test('test_GH93_TC42_users_탈퇴표시후_쓰기거부', async () => {
    await markDeleted('alice');
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'users', 'alice'), { createdAt: 1 }));
  });

  test('test_GH93_TC42_다른사용자는_영향없음', async () => {
    await markDeleted('alice');
    const db = env.authenticatedContext('bob').firestore();
    await assertSucceeds(setDoc(doc(db, 'wishes', 'b1'), syncedDoc('bob')));
  });

  test('test_GH93_TC42_앱은_탈퇴표시를_읽고쓸수없다', async () => {
    await markDeleted('alice');
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(getDoc(doc(db, 'deletedUsers', 'alice')));
    await assertFails(deleteDoc(doc(db, 'deletedUsers', 'alice')));
    await assertFails(setDoc(doc(db, 'deletedUsers', 'bob'), { deletedAt: 1 }));
  });

  // 앱은 한 번에 450개씩 올린다(FirestoreRemoteWishStore). 문서마다 exists()를 불러도 한도에 걸리지 않아야 한다
  test('test_GH93_TC42_450개_묶음쓰기_통과', async () => {
    const db = env.authenticatedContext('alice').firestore();
    const batch = writeBatch(db);
    for (let i = 0; i < 450; i += 1) {
      batch.set(doc(db, 'wishes', `w${i}`), syncedDoc('alice'));
    }
    await assertSucceeds(batch.commit());
  });
});
