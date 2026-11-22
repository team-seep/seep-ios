// GH-93 Storage 보안 규칙 (TC-7, TC-8). 에뮬레이터에서 돈다: firebase emulators:exec (firebase/README.md)
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

const JPEG = { contentType: 'image/jpeg' };

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-seep',
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearStorage();
});

function bytes(size) {
  return new Uint8Array(size);
}

describe('TC-7 본인 폴더만 올리고 읽는다', () => {
  test('test_GH93_TC7_본인폴더_올리기읽기지우기_성공', async () => {
    const storage = env.authenticatedContext('alice').storage();
    const photo = ref(storage, 'wishPhotos/alice/w1-a.jpg');
    await assertSucceeds(uploadBytes(photo, bytes(1024), JPEG));
    await assertSucceeds(getBytes(photo));
    await assertSucceeds(deleteObject(photo));
  });

  test('test_GH93_TC7_남의폴더_거부', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), 'wishPhotos/bob/w1-b.jpg'), bytes(1024), JPEG);
    });
    const storage = env.authenticatedContext('alice').storage();
    await assertFails(getBytes(ref(storage, 'wishPhotos/bob/w1-b.jpg')));
    await assertFails(uploadBytes(ref(storage, 'wishPhotos/bob/w2-b.jpg'), bytes(1024), JPEG));
    await assertFails(deleteObject(ref(storage, 'wishPhotos/bob/w1-b.jpg')));
  });

  test('test_GH93_TC7_비로그인_거부', async () => {
    const storage = env.unauthenticatedContext().storage();
    await assertFails(uploadBytes(ref(storage, 'wishPhotos/alice/w1-a.jpg'), bytes(1024), JPEG));
  });

  test('test_GH93_TC7_사진폴더밖_거부', async () => {
    const storage = env.authenticatedContext('alice').storage();
    await assertFails(uploadBytes(ref(storage, 'other/alice/a.jpg'), bytes(1024), JPEG));
  });
});

describe('TC-8 이미지·5MB 이하만', () => {
  test('test_GH93_TC8_이미지아님_거부', async () => {
    const storage = env.authenticatedContext('alice').storage();
    await assertFails(uploadBytes(ref(storage, 'wishPhotos/alice/a.txt'), bytes(10), { contentType: 'text/plain' }));
  });

  test('test_GH93_TC8_5MB초과_거부', async () => {
    const storage = env.authenticatedContext('alice').storage();
    await assertFails(uploadBytes(ref(storage, 'wishPhotos/alice/big.jpg'), bytes(5 * 1024 * 1024 + 1), JPEG));
  });

  test('test_GH93_TC8_5MB정확히_성공', async () => {
    const storage = env.authenticatedContext('alice').storage();
    await assertSucceeds(uploadBytes(ref(storage, 'wishPhotos/alice/max.jpg'), bytes(5 * 1024 * 1024), JPEG));
  });
});
