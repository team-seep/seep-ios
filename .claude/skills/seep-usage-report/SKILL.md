---
name: seep-usage-report
description: seep(싶)에서 출시된 기획(idea 이슈)의 트래킹 이벤트를 출시 후 2주간 GA(Firebase Analytics)에서 조회해 사용 횟수·사용자 수를 이슈에 코멘트로 남긴다. "기획 사용량 확인", "출시 기능 잘 쓰나 봐줘", 주간 스케줄 실행에서 사용.
---

# 출시 기획 사용량 리포트

목적은 **"쓰나, 안 쓰나"** 확인 하나다. 판단(개선·제거)은 사람이 한다.

## 0. 대상 찾기

```bash
cd /Users/hyunsikyoo/Documents/Github/seep-ios
git fetch -q --tags origin
gh issue list -R team-seep/seep-ios --label idea --state closed --limit 100 --json number,title,labels,closedAt \
  --jq '[.[] | select([.labels[].name] | (index("tracked") | not) and (index("approved") != null))]'
```

각 이슈에 대해:
1. 이슈를 닫은 PR의 머지 커밋을 찾는다: `gh issue view {n} --json closedByPullRequestsReferences` → `gh pr view {pr} --json mergeCommit`
2. 그 커밋이 들어간 **첫 릴리즈 태그**를 찾는다: `git tag --contains {sha} --sort=creatordate | head -1` (태그 형식 `vX.Y.Z`)
3. 태그가 없으면 아직 출시 전 → 건너뛴다
4. 태그 날짜 + 14일이 오늘보다 뒤면 → 아직 2주가 안 됐으니 건너뛴다

## 1. GA 조회

- `analytics-mcp`(Google Analytics MCP)를 쓴다. 처음이면 `get_account_summaries`로 seep **Prod** 속성(번들 `macgongmon.seep-ios`)의 property id를 찾는다. Dev 속성(`.dev`)과 헷갈리지 않는다.
  - 찾은 property id는 `~/.config/seep/ga-property-id` 에 저장하고 다음부터 그 값을 쓴다 (레포 파일은 수정하지 않는다).
- 이슈 본문의 "트래킹 이벤트" 표의 각 행마다 `run_report`로 조회한다:
  - 기간: 태그 날짜 ~ +14일
  - 측정항목: `eventCount`, `totalUsers`
  - 필터: `eventName` = 표의 이벤트(`click`/`impression`/커스텀), 그리고 커스텀 파라미터 `object_id`(필요하면 `screen`)
  - 커스텀 파라미터가 GA 맞춤 측정기준으로 등록돼 있지 않으면 필터가 안 된다 → `get_custom_dimensions_and_metrics`로 확인하고, 없으면 리포트에 "⚠️ GA에 object_id 맞춤 측정기준 등록 필요"를 적는다
- 비교 기준으로 같은 기간 앱 전체 활성 사용자 수(`activeUsers`)를 하나 조회한다.

## 2. 코멘트

```markdown
📊 출시 2주 사용량 (v2.3.0, 2026-11-01 ~ 11-15)

| 이벤트 | screen / object_id | 횟수 | 사용자 | 활성 사용자 대비 |
|---|---|---|---|---|
| click | home / pin_wish | 132 | 41 | 18% |

활성 사용자 228명 기준.
```
- `gh issue comment {n} --body-file`로 남기고 `tracked` 라벨을 단다.
- 수치를 해석하거나 권고하지 않는다. 사실만 남긴다.

## 3. 결과

마지막 메시지: 리포트한 이슈 목록(번호·횟수 한 줄씩), 건너뛴 이슈와 사유. 대상이 없으면 "리포트할 기획 없음".
