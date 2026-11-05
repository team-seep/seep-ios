import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import * as functions from 'firebase-functions/v1';
import { logger } from 'firebase-functions';

import { eraseUserData } from './eraseUserData.js';
import { cleanupWishPhoto } from './wishPhotoCleanup.js';

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

// 위시를 지우거나 사진을 바꾸면 Storage의 예전 사진을 지운다 (GH-93 R-42). 앱은 이 일을 하지 않는다:
// 오프라인 기기·옛 앱 버전과 상관없이 서버 한 곳에서 처리한다. TTL로 문서가 지워질 때(onDelete)는 사진이 이미 지워져 있다
export const cleanupWishPhotoOnUpdate = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 60, memory: '256MB', failurePolicy: true })
  .firestore.document('wishes/{wishId}')
  .onUpdate(async (change) => {
    const path = await cleanupWishPhoto({
      bucket: getStorage().bucket(),
      before: change.before.data(),
      after: change.after.data(),
    });
    if (path) logger.info('위시 사진 정리', { path });
  });
