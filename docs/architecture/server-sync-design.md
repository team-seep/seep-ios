# 서버(Firebase) 도입 설계

> 상태: **확정** (GH-93, 2026-11-04 열린 결정 6개를 닫음). §11의 0~4단계를 GH-93 한 이슈에서 단계별 PR로 진행한다.
> 화면 흐름: `docs/design/GH-93/flow.png` (모바일용 `flow-mobile-1~3.png`)
> 출발점: GH-79에서 만든 동기화 대비 스키마(UUID PK·`updatedAt`·`deletedAt`·UNIQUE 금지·하위 테이블은 `wishId`만 참조).

## 1. 목표와 원칙

**목표 (GH-79 배경 그대로)**
1. 내 위시를 서버와 동기화한다 (기기 여러 대, 기기 교체·재설치 복원).
2. 다른 사람과 같이 이룬다 (위시 단위 공유).
3. 다른 사람 위시를 본다 (공개 위시).

**원칙**
- **로컬 GRDB가 기준 데이터다.** 화면·위젯·앱 인텐트는 지금처럼 로컬 DB만 읽고 쓴다. 서버는 그 뒤에서 따라온다. 네트워크가 없어도 모든 기능이 그대로 동작한다.
- **ViewModel은 서버를 모른다.** Firebase 접근은 `Repository/Sync/`와 `Services/Account/`에서만 한다(§10 R11).
- **기본은 비회원이고, 지금과 똑같다.** 앱을 깔고 바로 쓰며 데이터는 이 기기 로컬에만 있다. 로그인을 권하는 팝업·온보딩은 넣지 않는다.
- **로그인 = 동기화 켜기.** 마이 페이지에서 원할 때 로그인(처음이면 그대로 회원가입)하고, 로그인한 순간부터 서버와 동기화된다. 따로 "동기화 켜기" 스위치는 두지 않는다. 다른 기기에서 같은 계정으로 로그인하면 같은 위시가 보인다.
- **서버 데이터 구조는 목표 3까지 내다보고 처음부터 정한다.** GH-79처럼 나중에 서버 데이터를 다시 옮기지 않기 위해서다.

## 2. 사용자 시나리오

### 2.1 상태

| 상태 | 데이터 | 동기화 | 비고 |
|---|---|---|---|
| **비회원** (기본) | 이 기기 로컬만 | 없음 | 지금 앱과 동일. 네트워크 요청 없음(Analytics·Remote Config 제외) |
| **회원** | 로컬 + 서버 | 자동 | 로컬이 기준, 서버는 뒤따라온다. 오프라인이면 쌓아 뒀다가 연결되면 보낸다 |

### 2.2 마이 페이지

**결정: 세 번째 탭(`MainTab.settings`, "설정")을 "마이" 탭으로 바꾼다.** 맨 위에 계정 영역을 두고, 그 아래에는 기존 설정 그룹(잠금·알림 / 보기 / 빠르게 적기 / 정보)을 그대로 둔다.

- 바뀌는 것: 탭 이름(`main_tab.settings`)과 화면 제목(`settings.title`)을 "마이"로 바꾼다. 탭 아이콘도 사람 모양으로 바꾼다(디자인 시스템 갱신 대상).
- 그대로 두는 것: 코드 이름(`MainTab.settings`, `SettingsTabRootView`, `SettingsViewModel`)과 로그 값(`ScreenName.settings`, `tab_settings`). 로그 값을 바꾸면 GA에서 이전 기간과 이어서 볼 수 없다.
- `sync_enabled`가 꺼져 있어도 탭 이름은 "마이"를 유지하고, 계정 영역만 숨긴다.

```
┌ 마이 ─────────────────────────────┐
│ [비회원]                           │
│  로그인하면 다른 기기에서도         │
│  내 싶을 볼 수 있어요               │
│  [ Apple로 계속하기 ]              │
├───────────────────────────────────┤
│ 잠금·알림 / 보기 / 빠르게 적기 / 정보 │  ← 기존 그대로
└───────────────────────────────────┘

┌ 마이 ─────────────────────────────┐
│ [회원] abc@privaterelay…  >        │  → 계정 화면
│  마지막 동기화 방금 전              │
├───────────────────────────────────┤
│ 기존 설정 그룹                      │
└───────────────────────────────────┘

계정 화면: 이메일 · 마지막 동기화 시각 · [지금 동기화] · [로그아웃] · [계정 삭제]
```

- 로그인 수단은 1차에 **Apple 하나**다. Sign in with Apple은 처음 쓰는 Apple ID면 가입, 이미 가입했으면 로그인이라 **로그인과 회원가입을 한 버튼으로** 처리한다(별도 가입 폼·약관 화면 없음, 처리방침 링크만 버튼 아래에 둔다).
- Remote Config `sync_enabled`가 꺼져 있으면 계정 영역 전체를 숨긴다. 이미 로그인한 사용자도 동기화를 멈추고 로컬로만 동작한다(킬 스위치).

### 2.3 흐름

| # | 상황 | 결과 |
|---|---|---|
| S1 | 앱을 처음 깔고 쓴다 | 비회원. 지금과 동일 |
| S2 | 비회원으로 쓰다가 마이 페이지에서 로그인(신규 가입) | 이 기기의 위시 전체(단계·저금·알림·사진 포함)가 서버에 올라간다. 진행 중 표시 → "동기화했어요" 토스트. 로컬 데이터는 그대로 |
| S3 | 다른 기기(새 기기 또는 재설치)에서 같은 계정으로 로그인 | 서버의 위시를 받아 보여 준다. 그 기기에 비회원으로 적어 둔 위시가 있으면 **합쳐서** 같이 올린다(UUID라 겹치지 않음) |
| S4 | 회원 상태에서 한 기기에서 적기·수정·완료·삭제, 위젯에서 단계 체크 | 다른 기기는 앱을 열거나(포그라운드) 켜져 있으면 바로 반영된다. D-day 알림도 다른 기기에 다시 예약된다 |
| S5 | 비행기 모드에서 수정 | 로컬에 바로 저장. 연결되면 자동으로 올라간다 |
| S6 | 로그아웃 | 확인 시트: "이 기기에 위시 남기기 / 이 기기에서 지우기". 남기면 비회원 상태로 로컬만 쓴다(서버에는 영향 없음) |
| S7 | 로그아웃 후 위시를 남긴 채 **다른 계정**으로 로그인 | 이전 계정 위시가 섞이지 않게 막는다: "이 기기 위시를 지우고 새 계정 위시 받기 / 취소" |
| S7' | 로그아웃 후 위시를 남긴 채 **같은 계정**으로 다시 로그인 | 그대로 합친다(S3과 같음) |
| S8 | 계정 삭제 | 서버 데이터·사진·계정을 지우고 비회원으로 돌아간다. 이 기기의 위시는 남길지 묻는다 |

## 3. 구성

| 쓰는 것 | 용도 | 비고 |
|---|---|---|
| Firebase Auth | 계정 | Sign in with Apple만 지원(1차). 익명 로그인은 쓰지 않는다 |
| Cloud Firestore | 위시·단계·저금·알림 동기화 | **오프라인 캐시는 끈다**(메모리 캐시). 로컬 기준 데이터는 GRDB이고, 오프라인 쓰기 재시도는 아웃박스(§5)가 맡는다. 같은 데이터를 두 번 저장하지 않는다 |
| Cloud Storage | 위시 사진 | **Blaze 요금제가 필요하다**(Spark에서는 버킷 접근 불가). 무료 사용량은 Blaze에서도 그대로 있다 |
| App Check (App Attest) | 정식 앱에서 온 요청만 받기 | 패키지(`FirebaseAppCheck`)는 이미 들어와 있다 |
| Remote Config | `sync_enabled` 킬 스위치, 점진 출시 | 이미 `RemoteConfigRepository`가 있다 |
| Cloud Functions | 계정 삭제 정리(`eraseDeletedUser`), (3단계) 공개 피드·신고 | 1·2단계는 계정 삭제 정리 하나 |

Firebase 프로젝트는 **dev / prod 두 개**로 나눈다. Debug 번들(`macgongmon.seep-ios.dev`)은 dev 프로젝트, Release 번들은 prod 프로젝트에 붙는다. 보안 규칙·인덱스는 레포의 `firebase/`(`firestore.rules`, `firestore.indexes.json`, `storage.rules`)에 두고 CI에서 `firebase deploy --only firestore,storage`로 반영한다.

## 4. 서버 데이터 모델 (Firestore)

로컬 테이블 하나 = 최상위 컬렉션 하나, 로컬 줄 하나 = 문서 하나 (문서 ID = 로컬 UUID).

```
wishes/{wishId}                 // WishRecord 필드 전부
wishSteps/{stepId}              // WishStepRecord
wishSavings/{savingId}          // WishSavingRecord
wishNotifications/{notifId}     // WishNotificationRecord
wishJournals/{journalId}        // WishJournalRecord (GH-95 일지)
```

모든 문서에 공통 필드:

| 필드 | 뜻 |
|---|---|
| `ownerUid` | 만든 사람 |
| `memberUids: [String]` | 읽고 쓸 수 있는 사람. 1단계에서는 `[ownerUid]` 하나뿐. 하위 문서도 부모 위시의 값을 그대로 복사해 둔다(규칙에서 부모 `get()`을 하지 않으려고, 읽기 비용 절약) |
| `updatedAt` | 클라이언트가 고친 시각 (로컬 값 그대로). **충돌 판정용** |
| `deletedAt` | 삭제 표시 (로컬 값 그대로) |
| `serverUpdatedAt` | `FieldValue.serverTimestamp()`. **받아오기 커서용** (기기 시계와 무관) |
| `schemaVersion` | 이 문서를 쓴 앱의 로컬 마이그레이션 버전 (예: `"v7"`). 구버전 앱이 모르는 필드를 지우지 않게 하는 데 쓴다(§6.4) |

**`users/{uid}/...` 아래에 두지 않는 이유**: 같이 이루기(목표 2)에서 위시 하나를 여러 사용자가 같이 가진다. 사용자 경로 아래에 두면 공유할 때 문서를 옮겨야 한다. 최상위 컬렉션 + `memberUids`로 두면 1단계부터 3단계까지 구조가 같다.

사용자 메타 문서는 따로 둔다:
```
users/{uid}                     // 표시 이름, 가입 시각, 마지막 동기화한 앱 버전
```

**인덱스**: 컬렉션마다 `memberUids (array-contains) + serverUpdatedAt (asc)` 복합 인덱스.

**보안 규칙 뼈대**
```
match /wishes/{id} {
  allow read: if request.auth.uid in resource.data.memberUids;
  allow create: if request.auth.uid == request.resource.data.ownerUid
                && request.resource.data.memberUids == [request.auth.uid];
  allow update: if request.auth.uid in resource.data.memberUids
                && request.resource.data.ownerUid == resource.data.ownerUid
                && request.resource.data.memberUids == resource.data.memberUids; // 멤버 변경은 2단계에서 별도 경로
  allow delete: if false;   // 삭제는 deletedAt 표시로만
}
// wishSteps / wishSavings / wishNotifications / wishJournals 도 같은 모양
```

**사진**: `wishPhotos/{ownerUid}/{photoFileName}`. 로컬 파일 이름(`{위시id}-{uuid}.jpg`)을 그대로 쓴다. 규칙은 1단계에서 `ownerUid == auth.uid`만 허용, 2단계에서 위시 멤버까지 넓힌다.

## 5. 로컬 쪽: 아웃박스

**왜 필요한가** — 로컬 쓰기는 앱(`WishRepositoryImpl`)만이 아니라 위젯(`WidgetCheckRepository`: 단계 체크·완료)과 앱 인텐트에서도 일어난다. 다른 프로세스의 쓰기를 앱이 놓치지 않아야 하고, 오프라인에서 한 쓰기는 앱이 꺼졌다 켜져도 남아 있어야 한다.

**마이그레이션 `v7`** (현재 마지막은 `v6`)
```sql
CREATE TABLE syncOutbox (
  seq        INTEGER PRIMARY KEY AUTOINCREMENT,  -- 이 기기 전용 큐라 정수 키를 쓴다
  tableName  TEXT NOT NULL,
  rowId      TEXT NOT NULL,
  enqueuedAt DOUBLE NOT NULL
);
CREATE INDEX syncOutbox_on_row ON syncOutbox(tableName, rowId);

CREATE TABLE syncState (       -- 커서·로그인한 uid 등. 이 기기에만 있는 값
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- wish / wishStep / wishSaving / wishNotification / wishJournal 마다 INSERT·UPDATE 트리거
CREATE TRIGGER wish_after_insert_outbox AFTER INSERT ON wish
BEGIN INSERT INTO syncOutbox (tableName, rowId, enqueuedAt) VALUES ('wish', NEW.id, NEW.updatedAt); END;
CREATE TRIGGER wish_after_update_outbox AFTER UPDATE ON wish
BEGIN INSERT INTO syncOutbox (tableName, rowId, enqueuedAt) VALUES ('wish', NEW.id, NEW.updatedAt); END;
```

- 트리거로 하는 이유: `WishRecordStore`·`updateAll`·위젯·앱 인텐트·1회 이전 등 **어느 경로로 쓰든 빠짐없이** 잡힌다. 쓰는 코드를 하나하나 고치지 않아도 된다.
- `syncOutbox`·`syncState`는 `appMetadata`처럼 **동기화 대상이 아닌 이 기기 전용 테이블**이다. R4의 `updatedAt`·`deletedAt` 규칙에서 뺀다. 둘 다 `model/dto/`에 레코드로 두지 않고 Repository 안에서만 다루므로 `check-db-schema.sh`를 고칠 필요는 없다. RULES R4 예외 문구에만 추가한다.
- 로그인 전에도 트리거는 쌓인다. 처음 로그인할 때 큐를 비우고 전체 업로드(§6.3)를 하면 되므로, 로그인 전 큐는 `syncState.uid`가 없으면 주기적으로 비운다.

## 6. 동기화 엔진

```
seep-ios/Repository/Sync/
├── SyncEngine.swift            // protocol SyncEngineProtocol + SyncEngine (push → pull 한 사이클, 직렬 실행)
├── SyncOutbox.swift            // 아웃박스·syncState 읽기/쓰기 (GRDB)
├── RemoteWishStore.swift       // protocol RemoteWishStore + FirestoreRemoteWishStore (Firestore 접근은 여기서만)
├── SyncRecordMapper.swift      // WishRecord ⇄ [String: Any] (Date ↔ Timestamp)
└── RemotePhotoStore.swift      // protocol + FirebaseStorage 구현
seep-ios/Services/Account/
└── AccountManager.swift        // protocol AccountManagerProtocol: Sign in with Apple → Firebase Auth, 로그아웃, 계정 삭제
```

테스트는 `RemoteWishStore`를 메모리 목(`MockRemoteWishStore`)으로 바꾸고, 로컬은 `AppDatabase.makeInMemory()`로 실제 구현을 돌린다. "기기 두 대"는 메모리 DB 두 개 + 목 서버 하나로 만든다.

### 6.1 한 사이클

1. **Push**: `syncOutbox`를 `seq` 순서로 최대 N줄 읽어 `(tableName, rowId)`로 중복을 없앤다 → 각 줄의 **현재 로컬 값**을 읽는다 → Firestore `WriteBatch`(최대 500건)로 `setData(merge: true)` + `serverUpdatedAt` → 성공하면 읽은 `seq`까지 큐에서 지운다. 실패하면 큐를 그대로 두고 지수 백오프로 다시 한다.
2. **Pull**: 컬렉션마다 `memberUids array-contains uid AND serverUpdatedAt > 커서` 조회 → 한 트랜잭션에서 적용(§6.2) → 커서를 받은 것 중 가장 큰 `serverUpdatedAt`으로 올린다.
3. **후처리**: 바뀐 위시가 있으면
   - **로컬 알림을 다시 예약한다.** 다른 기기에서 고친 D-day 알림이 이 기기에도 울려야 한다. `wishNotification.id`가 알림 identifier이므로 그대로 쓰면 된다. 삭제·완료된 위시는 취소한다.
   - 위젯 타임라인을 새로 그린다 (`WidgetCenter.reloadAllTimelines()`).
   - 사진 이름이 바뀐 위시는 사진 다운로드 큐에 넣는다(§7).

**언제 도는가**: 앱 실행·포그라운드 진입(올리기+받기), 로컬 쓰기 후 2초 디바운스(올리기만, 받기는 읽기 비용), 계정 화면 "지금 동기화"(`AppShell/SyncScheduler`). 앱이 켜져 있는 동안의 스냅샷 리스너는 1차에서 넣지 않았다 — 켜 둔 두 기기 사이는 포그라운드 전환·지금 동기화로 맞춘다. 같이 이루기(5단계)에서 리스너를 붙인다. 백그라운드 새로고침(`BGAppRefreshTask`)도 2차로 미룬다.

### 6.2 받아온 줄 적용과 충돌

줄(문서) 단위 **마지막 쓰기 승리(LWW)**, 기준은 `updatedAt`.

```
트랜잭션 시작, startSeq = 현재 syncOutbox 최대 seq
for remote in 받아온 문서:
    local = 같은 id 로컬 줄
    if local == nil                       → INSERT
    else if remote.updatedAt > local.updatedAt → UPDATE (deletedAt 포함 그대로)
    else if remote.updatedAt < local.updatedAt → 로컬 줄을 아웃박스에 다시 넣는다 (다른 기기가 늦게 올린 옛 값이 서버를 덮었다)
    else                                  → 건너뜀
DELETE FROM syncOutbox WHERE seq > startSeq   -- 방금 적용하며 트리거가 쌓은 줄은 되돌려 보내지 않는다
트랜잭션 끝
```

- 쓰기는 한 커넥션에서 직렬로 일어나므로, 이 트랜잭션 안에서 생긴 아웃박스 줄은 전부 적용 때문에 생긴 것이다.
- **하위 줄이 부모보다 먼저 올 수 있다**(외래키 `ON DELETE CASCADE`가 걸려 있다). 적용 순서를 `wish` → 하위 테이블로 고정하고, 부모가 아직 없는 하위 줄은 다음 사이클로 미룬다(커서를 그 줄 앞에서 멈춘다).
- **삭제는 이긴다**: `deletedAt`이 있는 쪽과 없는 쪽이 부딪히면, `updatedAt`과 상관없이 삭제를 따른다. 지운 위시가 되살아나는 것이 더 나쁘기 때문이다. 로컬은 지웠는데 서버엔 살아 있으면 로컬 삭제를 다시 올린다.
- push 는 서버 값을 확인하지 않고 덮는다. 그래서 옛 값이 늦게 올라가면 서버가 잠깐 뒤로 갈 수 있고, 더 새 값을 가진 기기가 다음 받기에서 알아채고 다시 올려 맞춘다(구현: `SyncStore.apply`).
- 컬렉션 다섯 개를 모두 받은 뒤 한 트랜잭션에 적용하고, 알림 다시 예약은 위시마다 한 번만 한다.
- **알려진 한계**: 위시 문서 하나를 두 기기에서 오프라인으로 동시에 고치면 필드 단위로 합치지 않고 한쪽이 이긴다. 단계·저금·알림은 줄이 따로 있어서 서로 덮지 않는다. 같이 이루기(2단계)에서 문제가 보이면 그때 필드 단위 병합을 검토한다.
- `manualOrder`(내 순서)는 기기마다 다르게 두고 싶을 수 있다. `pinnedAt`과 함께 기기 간에 같이 동기화한다(§12 1번). 2단계 공유 위시에서 사용자별 값으로 분리할지는 그때 다시 본다.

### 6.3 처음 로그인·로그아웃·계정 바꾸기

시나리오 S2·S3·S6·S7(§2.3)의 구현이다. 로그인한 uid는 `syncState.uid`, 이 기기 로컬 데이터가 묶인 계정은 `syncState.boundUid`에 둔다.

| 상황 | 동작 |
|---|---|
| 비회원 → 로그인, `boundUid` 없음 (S2·S3) | 아웃박스를 비우고 로컬 전체(삭제 표시 포함)를 업로드한 뒤 서버 전체를 받는다. UUID라 겹치지 않으므로 **합집합**이 된다. 묻지 않고 바로 합친다. `boundUid = uid` |
| 로그인, `boundUid == uid` (S7') | 위와 같이 로컬 전체 업로드 + 서버 전체 받기. 로그아웃해 있는 동안 고친 것은 아웃박스에 남아 있지 않을 수 있어서 증분이 아니라 전체로 맞춘다. 겹치는 줄은 LWW(§6.2)로 정리된다 |
| 로그인, `boundUid != uid` (S7) | 로컬이 다른 계정 데이터이므로 **합치지 않는다.** "지우고 새 계정 위시 받기 / 취소" |
| 로그아웃 (S6) | 진행 중인 push를 한 번 끝까지 시도한 뒤 `uid`·커서를 지운다. "남기기"면 `boundUid`는 그대로 두고, "지우기"면 로컬 위시·사진·예약 알림을 지우고 `boundUid`도 지운다 |

### 6.4 앱 버전이 섞일 때

기기 A는 새 버전(v8 필드가 있음), 기기 B는 구버전일 수 있다. B가 모르는 필드를 지우지 않도록 **push는 항상 `merge: true`로 아는 필드만 쓴다.** 새 필드는 반드시 기본값이 있는 컬럼으로만 추가한다(이미 R4 마이그레이션 관례다). 받은 문서의 `schemaVersion`이 이 앱보다 높으면, 모르는 필드는 버리고 아는 필드만 적용한다. 다음에 B가 그 줄을 push해도 A가 쓴 새 필드는 서버에 남는다.

### 6.5 삭제 표시 정리 (GH-79에서 미뤄 둔 것)

- 서버: 삭제 표시가 있고 `serverUpdatedAt`이 90일 지난 문서는 Firestore **TTL 정책**으로 지운다.
- 로컬: 삭제 표시 후 push가 끝났고 90일 지난 줄은 물리 삭제한다(CASCADE로 하위 줄도 같이).
- 커서가 90일보다 오래된 기기(오래 안 켠 기기)는 증분 대신 **전체 다시 받기**를 한다. 그러지 않으면 그사이 지워진 위시가 그 기기에 남는다.

## 7. 사진

- 저장: 로컬 저장은 지금처럼 끝내고, 업로드 큐(`syncState`의 목록 또는 별도 `photoOutbox`)에 넣는다. Wi-Fi 여부와 상관없이 올린다(1080px JPEG라 작다).
- 받기: `WishPhotoStorage.photoURL(fileName:)`이 nil인데 `photoFileName`이 있으면, 이미 "파일 없음"으로 처리하는 길(GH-36 R-7)이 있다. 그 자리에서 다운로드를 요청하고 끝나면 다시 그린다.
- 삭제: 위시 삭제 표시가 서버에 반영되면 Storage 파일도 지운다(6.5 정리 때 같이).
- `WishPhotoStorage`는 프로토콜 그대로 두고, 동기화는 `RemotePhotoStore`가 맡는다.

## 8. 계정·정책 (심사)

- **Sign in with Apple** → `OAuthProvider.appleCredential` → Firebase Auth.
- **앱 안에서 계정 삭제** (App Store 심사 가이드라인 5.1.1(v)): 설정 → 계정 삭제
  1. Apple로 다시 인증한다.
  2. Apple 토큰을 해지한다(`Auth.auth().revokeToken(withAuthorizationCode:)`).
  3. Auth 사용자를 지운다.
  4. 서버의 내 문서·사진은 **Cloud Function `eraseDeletedUser`**(Auth 사용자 삭제 트리거, `firebase/functions`)가 지운다. 앱은 직접 지우지 않는다. 그래서 보안 규칙의 문서 삭제 금지(TC-6)를 그대로 둔다. 남의 공유 위시(5단계)에서는 멤버에서만 뺀다.
     - 함수는 먼저 `deletedUsers/{uid}` 표시를 남기고, 규칙은 표시가 있는 uid의 쓰기를 막는다. 다른 기기에 남은 ID 토큰(최대 1시간)으로 지운 뒤에 문서가 다시 생기지 않게 하기 위해서다.
     - 함수는 Blaze 요금제가 필요하다. 호출은 탈퇴 때 1번이라 비용은 사실상 0이다.
  5. 로컬 데이터는 남길지 묻는다.
- 개인정보 처리방침·App Store 개인정보 라벨 갱신. 수집 항목은 이메일(Apple 비공개 릴레이 가능), 사용자 콘텐츠(위시·메모·**위치(위도·경도)**·**사진**·편지), 식별자(uid)다.
- "미래의 나에게" 편지(`futureLetter`)는 봉인한 날까지 본인도 못 보는 기능이다. 서버에도 평문으로 올라간다는 점을 처리방침에 적는다. 클라이언트 측 암호화는 하지 않는다(§12 2번).
- 3단계(남의 위시 보기)는 **사용자 생성 콘텐츠 규칙(가이드라인 1.2)**: 신고·차단·이용약관 동의·운영자 대응이 필요하다.

## 9. 비용

> 2026-10 기준 추정이다. 단가는 미국 리전 공개 가격 범위이고(서울 리전 단가는 확인하지 못함), 실제 사용자 수와는 대조하지 않았다. 출시 1 이후 `sync_push`·`sync_pull` 이벤트의 실측치로 다시 계산한다.

**비회원은 비용에 잡히지 않는다.** 로그인한 사용자만 서버를 쓴다.

### 9.1 1인당 사용량 가정 (로그인 사용자, 하루)

| 항목 | 양 | 근거 |
|---|---|---|
| 읽기 | 약 30건 | 앱을 하루 5번 열 때마다 4개 컬렉션을 조회(바뀐 게 없어도 조회당 최소 1건 과금) + 다른 기기에서 바뀐 문서 |
| 쓰기 | 약 6건 | 하루 3번 수정 × (바꾼 줄 + 부모 위시 `updatedAt`) |
| 처음 한 번 | 쓰기·읽기 100~300건 | 가입 시 전체 업로드(§6.3), 새 기기에서 전체 받기 |
| 저장 | 1인 약 0.5MB(문서) + 약 1.25MB(사진 5장 × 250KB) | 위시 50개 안팎, 하위 문서 포함 약 200개 |

### 9.2 무료 한도와 먼저 닿는 지점

| 항목 | 무료 한도 | 먼저 닿는 시점 | 넘으면 |
|---|---|---|---|
| **Firestore 읽기** | 하루 5만 건 | **매일 쓰는 로그인 사용자 약 1,600명** | 10만 건당 $0.03~0.06 |
| Firestore 쓰기 | 하루 2만 건 | 매일 쓰는 로그인 사용자 약 3,300명 | 10만 건당 $0.09~0.18 |
| Firestore 저장 | 1GiB | 누적 가입자 약 2천 명 | GiB당 월 약 $0.18 |
| 사진 저장 (Storage) | 5GB | 누적 가입자 약 4천 명 | GB당 월 약 $0.026 |
| 사진 업로드 횟수 | 월 5천 건 | 금방 넘지만 금액은 미미 | 1만 건당 수 센트 |
| 사진 다운로드 | 월 100GB | 새 기기 로그인 약 8만 번 | GB당 과금 |
| 로그인 (Auth) | §9.4 참고 | | |

### 9.3 규모별 월 비용 (매일 쓰는 로그인 사용자 기준)

| 규모 | 월 비용 |
|---|---|
| 1,500명 이하 | 0원 |
| 1만 명 | 약 $3~7 (5천~1만 원) |
| 10만 명 | 약 $45~85, 저장·사진 포함 약 $60~100 |

가입 비율을 전체 사용자의 20~30%로 보면, **앱 전체 DAU 5천~7천 명쯤에서 처음 비용이 찍힌다.**

### 9.4 비용 위험과 대응

1. **사용자 수보다 버그가 비싸다.** 동기화 무한 반복이나 리스너를 계속 다시 붙이는 버그 하나가 사용자 1만 명분을 하루에 쓸 수 있다.
   - Blaze 예산 알림을 월 $5로 건다(§12 5번).
   - `sync_push`·`sync_pull` 이벤트로 1인당 읽기·쓰기 건수를 본다.
   - 이상하면 Remote Config `sync_enabled`로 바로 끈다(§2.2).
2. **Auth는 Identity Platform으로 업그레이드하지 않는다.** 순수 Firebase Auth의 Apple 로그인은 따로 과금되지 않는 것으로 알고 있다. 업그레이드하면 월 활성 5만 명부터 1인당 과금이 붙고, 10만 명 규모에서는 가장 큰 비용이 된다.
3. **사진 버킷은 미국 리전(us-central1 등)에 둔다.** Storage 무료 한도는 미국 리전 버킷에만 있다. 사진은 백그라운드로 주고받으니 체감 지연은 거의 없다. Firestore는 서울 리전에 둬도 이 규모에서는 금액 차이가 미미하다.
4. 같이 이루기(§11 5단계)에서 앱이 켜져 있는 동안 실시간 리스너를 붙이면 읽기가 늘지만, 1인당 수십 건 수준이라 위 계산이 크게 달라지지 않는다.

## 10. 레포 규칙 변경

| 대상 | 변경 |
|---|---|
| `docs/process/planning.md` 서버리스 조건 | "Firebase Auth·Firestore·Storage를 통한 **내 데이터 동기화·공유**는 허용. 자체 서버, 원격 푸시는 여전히 제외"로 바꾼다. 3단계 승인 전까지 공개·소셜 기획은 제외 |
| `seep-idea-scout` 스킬 | 위 조건을 같이 반영 |
| RULES **R11 신설** | `import FirebaseFirestore`·`FirebaseAuth`·`FirebaseStorage`는 `Repository/Sync/`·`Services/Account/`에서만. ViewModel은 `SyncEngineProtocol`·`AccountManagerProtocol`만 의존. SwiftLint custom rule로 강제 |
| RULES R3 | DB 접근 예외에 `Repository/Sync/`가 포함됨을 명시 (이미 `Repository/` 안이라 규칙 변경은 없음) |
| RULES R4 | 이 기기 전용 테이블 예외에 `syncOutbox`·`syncState` 추가. "새 컬럼은 기본값 필수"를 명시 (§6.4) |
| `verification-change.md` | `firebase/**`(보안 규칙·인덱스) 변경에 `schema-change` 라벨 |
| `e2e-and-manual-tests.md` | 동기화 영역 체크 추가: 시뮬레이터 두 대 동시 편집, 비행기 모드 편집 후 복귀, 위젯에서 체크 후 다른 기기 반영, 알림 재예약, 계정 삭제 |
| 로그 | `CustomEvent`: `sync_push`(건수·소요), `sync_pull`, `sync_error`(단계·코드), `account_sign_in`·`account_delete`. `ScreenName`·`LogObjectId`에 계정 화면 값 추가 |

## 11. 단계 (0~4는 GH-93 하나에서 단계별 PR)

| 순서 | 단계 | 내용 | 크기 |
|---|---|---|---|
| 0 | 결정·기반 | 이 문서 승인, Firebase dev/prod 프로젝트·Blaze·App Check, `firebase/` 규칙 레포화, §10 규칙 변경 | S |
| 1 | 계정·마이 페이지 | 설정 탭 → "마이" 탭, 비회원/회원 계정 영역(§2.2), Sign in with Apple(로그인=가입), 로그아웃, **계정 삭제**. Remote Config `sync_enabled` 뒤에 숨김 | M |
| 2 | 동기화 v1 | 마이그레이션 v7(아웃박스·트리거), `SyncEngine` push/pull·LWW, 처음 로그인 합치기, 알림 재예약·위젯 갱신, 로그 이벤트 | L |
| 3 | 사진 동기화 | Storage 업로드·지연 다운로드·삭제 | M |
| 4 | 삭제 표시 정리 | TTL 정책, 로컬 물리 삭제, 오래된 기기 전체 다시 받기 | S |
| — | **출시 1** | 1~4를 TestFlight → Remote Config로 10% → 100%. `sync_error` 비율을 보고 늘린다 | |
| 5 | 같이 이루기 | 초대 링크(유니버설 링크, AASA는 Firebase Hosting. Dynamic Links는 종료되어 쓰지 않음), `memberUids` 변경용 Cloud Function, 멤버 표시, 공유 위시 삭제·나가기 규칙 | L |
| 6 | 남의 위시 보기 | `publicWishes` 컬렉션(공개용 사본, 위치·편지 제외), 피드, 신고·차단, 운영 도구 | L |

1·2를 한 출시로 묶는 이유: 계정만 있고 동기화가 없으면 사용자에게 가치가 없다. 단, 계정 이슈를 먼저 머지해 두면 심사 대응(계정 삭제 등)을 따로 검증할 수 있다.

## 12. 결정 (GH-93에서 닫음, 2026-11-04)

1. `manualOrder`·`pinnedAt`은 **기기 간에 같이 동기화**한다.
2. "미래의 나에게" 편지는 **평문**으로 올리고 개인정보 처리방침에 적는다. 공유 위시에서는 편지를 뺀다.
3. 위시 문서 충돌은 **줄 단위 LWW(나중 수정이 이김) + 삭제 우선**. 필드 단위 병합은 하지 않는다.
4. 로그인 수단에 **Google은 넣지 않는다**(Apple 하나).
5. Blaze 예산 알림은 **월 $5**.
6. 로그아웃 시 기본 선택은 **"이 기기에 싶 남기기"**.

화면 흐름 원칙: 앱을 처음 열 때 로그인 화면을 보여 주지 않는다. 지금처럼 비회원으로 바로 쓰고, 로그인은 마이 탭 맨 위 카드에서 원할 때만 한다(§2.2, `docs/design/GH-93/flow.png`).

## 참고

- Firestore 요금·오프라인 리스너 과금: https://cloud.google.com/firestore/pricing
- Firestore 무료 한도: https://docs.cloud.google.com/firestore/quotas
- Firebase 요금(Storage 무료 한도·Auth): https://firebase.google.com/pricing
- Cloud Storage for Firebase 요금제 변경(Blaze 필요): https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
- 관련: GH-79(동기화 대비 스키마), RULES R3·R4, GH-36(사진), GH-48(App Group·알림 id)
