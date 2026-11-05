# firebase/

Firestore·Storage 보안 규칙·인덱스와 Cloud Functions (GH-93, 설계 `docs/architecture/server-sync-design.md` §4).
콘솔에서 직접 고치지 않고 여기서 고친 뒤 CI로 배포한다.

| 파일 | 내용 |
|---|---|
| `firestore.rules` | `wishes`·`wishSteps`·`wishSavings`·`wishNotifications`·`wishJournals`(멤버만), `users/{uid}`(본인만), 문서 삭제 금지, 탈퇴 표시(`deletedUsers/{uid}`)가 있으면 쓰기 금지 |
| `firestore.indexes.json` | 컬렉션마다 `memberUids`(array-contains) + `serverUpdatedAt` |
| `storage.rules` | `wishPhotos/{uid}/…` 본인만, 이미지·5MB 이하 |
| `.firebaserc` | `dev` = `seep-dev`, `prod` = `seep-ios` |
| `tests/` | 규칙 테스트 (`@firebase/rules-unit-testing`, `node --test`) |
| `functions/` | `eraseDeletedUser`: Auth 사용자가 지워지면(앱의 계정 삭제) 그 사용자의 문서·`users/{uid}`·사진을 지우고 탈퇴 표시를 남긴다. 1세대 Auth 트리거, `us-central1` |

## 규칙 테스트

에뮬레이터에 JDK 21 이상이 필요하다.

```bash
cd firebase/tests && npm ci && cd ..
firebase emulators:exec --only firestore,storage --project demo-seep "cd tests && npm test"
```

## 함수 테스트

```bash
cd firebase/functions && npm ci && cd ..
firebase emulators:exec --only auth,firestore,storage,functions --project demo-seep "cd functions && npm test"
```

- `eraseUserData.test.js`: 지우는 로직을 에뮬레이터 Firestore·Storage에 직접 돌린다 (TC-43·44)
- `trigger.test.js`: Auth 에뮬레이터에서 사용자를 지우면 함수가 돌아 데이터가 지워진다 (TC-45)
- `wishPhotoCleanup.test.js`: 위시를 지우거나 사진을 바꾸면 예전 사진이 지워지고, 늦게 올라온 옛 값이면 지우지 않는다 (TC-49)

### 삭제 표시 TTL

`firestore.indexes.json`의 `fieldOverrides`가 5개 컬렉션의 `purgeAt`에 TTL 정책을 켠다(색인은 끈다). 앱이 삭제 표시를 올릴 때 `purgeAt` = 올린 시각 + 90일을 쓴다.
TTL 삭제는 시각이 지난 뒤 보통 24시간 안에 일어나고, 지운 문서는 읽기 비용 없이 삭제 1건으로 센다. 정책을 처음 켜면 적용까지 시간이 걸린다(콘솔 Firestore → TTL에서 확인).

### 왜 탈퇴 표시를 남기나

Auth 사용자를 지워도 다른 기기에 있던 ID 토큰은 최대 1시간 동안 유효하다. 함수가 지운 뒤에 그 기기가 올리면 문서가 다시 생긴다.
함수는 지우기 전에 `deletedUsers/{uid}`를 먼저 쓰고, 규칙은 이 표시가 있는 uid의 만들기·고치기를 거부한다(TC-42).
같은 Apple ID로 다시 가입하면 Firebase가 새 uid를 주므로 표시가 다시 가입을 막지 않는다.
쓰기마다 `exists()` 읽기가 1건 더 든다(450개 묶음 쓰기도 한도 안에서 통과한다).

## 배포

- `develop`에 머지되면 `.github/workflows/firebase-rules.yml`이 `dev`에 배포한다.
- `prod`는 같은 워크플로를 수동 실행(`workflow_dispatch`, target `prod`)한다.
- 인증은 GitHub Secrets `FIREBASE_SERVICE_ACCOUNT_DEV`·`FIREBASE_SERVICE_ACCOUNT_PROD`(서비스 계정 키 JSON).
  - 역할: Firebase Rules Admin, Cloud Datastore Index Admin, Cloud Functions Admin, Service Account User, Artifact Registry Administrator.
- 함수는 Blaze 요금제에서만 배포된다. 처음 한 번은 로컬에서 `firebase deploy --only functions --project dev`로 배포해 필요한 API(Cloud Functions·Cloud Build·Artifact Registry)를 켜 두면 CI 배포가 막히지 않는다.
