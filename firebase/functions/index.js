import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import * as functions from 'firebase-functions/v1';
import { logger } from 'firebase-functions';

import { eraseUserData } from './eraseUserData.js';

initializeApp();

// Auth 사용자 삭제 트리거는 1세대(v1)에만 있다. 앱이 계정 삭제(Auth deleteUser)를 하면 불린다 (GH-93 R-29)
// 리전은 Storage 버킷과 같은 us-central1 (R-5)
export const eraseDeletedUser = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 300, memory: '256MB', failurePolicy: true })
  .auth.user()
  .onDelete(async (user) => {
    const result = await eraseUserData({
      db: getFirestore(),
      bucket: getStorage().bucket(),
      uid: user.uid,
    });
    logger.info('탈퇴 사용자 데이터 삭제', { uid: user.uid, ...result });
  });
