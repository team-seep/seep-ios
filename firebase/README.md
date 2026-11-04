# firebase/

Firestore·Storage 보안 규칙과 인덱스 (GH-93, 설계 `docs/architecture/server-sync-design.md` §4).
콘솔에서 직접 고치지 않고 여기서 고친 뒤 CI로 배포한다.

| 파일 | 내용 |
|---|---|
| `firestore.rules` | `wishes`·`wishSteps`·`wishSavings`·`wishNotifications`·`wishJournals`(멤버만), `users/{uid}`(본인만), 문서 삭제 금지 |
| `firestore.indexes.json` | 컬렉션마다 `memberUids`(array-contains) + `serverUpdatedAt` |
| `storage.rules` | `wishPhotos/{uid}/…` 본인만, 이미지·5MB 이하 |
| `.firebaserc` | `dev` = `seep-dev`, `prod` = `seep-ios` |
| `tests/` | 규칙 테스트 (`@firebase/rules-unit-testing`, `node --test`) |

## 규칙 테스트

에뮬레이터에 JDK 21 이상이 필요하다.

```bash
cd firebase/tests && npm ci && cd ..
firebase emulators:exec --only firestore,storage --project demo-seep "cd tests && npm test"
```

## 배포

- `develop`에 머지되면 `.github/workflows/firebase-rules.yml`이 `dev`에 배포한다.
- `prod`는 같은 워크플로를 수동 실행(`workflow_dispatch`, target `prod`)한다.
- 인증은 GitHub Secrets `FIREBASE_SERVICE_ACCOUNT_DEV`·`FIREBASE_SERVICE_ACCOUNT_PROD`(서비스 계정 키 JSON, 역할: Firebase Rules Admin + Cloud Datastore Index Admin).
