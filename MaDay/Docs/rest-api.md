# REST API (Record 기능 연동)

Record 화면(타이머/태스크 추가/새 태스크 생성)과 연동하기 위한 Spring Boot REST API 제안입니다. 인증은 JWT 가정, iPhone이 세션 Source of Truth입니다.

## Task 관리
- `GET /tasks`
  - Query: `date`(optional, `yyyy-MM-dd`) — 특정 날짜 태스크 필터용
  - Response: `[{ taskId, title, detail, categoryId, categoryName, color, trackedSec, isCompleted, updatedAt }]`
- `POST /tasks`
  - Body: `{ title, detail, categoryId?, categoryName?, color?, clientCreatedAt }`
  - Response: `{ taskId, title, detail, categoryId, categoryName, color, trackedSec, isCompleted, updatedAt }`
- `PATCH /tasks/{taskId}`
  - Body: 부분 수정 `{ title?, detail?, categoryId?, categoryName?, color?, isCompleted? }`
- `DELETE /tasks/{taskId}`
- **정렬 순서 저장(옵션)**: My Tasks에서 순서를 바꿀 경우 서버/DB에도 반영하려면
  - `PATCH /tasks/reorder`
    - Body: `{ order: [taskId1, taskId2, ...] }` (상단→하단 순서)
    - 서버: 사용자별 순서 값을 저장하고, `GET /tasks` 응답에 정렬 적용

## 타이머 세션/이벤트 동기화 (핵심)
모델:
```
TimerSession { sessionId(UUID), taskId, startAt, endAt?, durationSec, sourceDevice, synced, version, lastModifiedAt }
TimerEvent { sessionId, type(start|pause|resume|stop), timestamp }
```

- `POST /sessions/sync`
  - Body: `{ phoneNow, sessions: [TimerSession], events: [TimerEvent] }`
  - 서버: `sessionId` 기준 idempotent upsert, `version/lastModifiedAt`로 충돌 해결. 성공 시 `synced=true` 상태 반환.
  - Response: `{ syncedSessions: [...], syncedEvents: [...] }`
- `GET /sessions?date=yyyy-MM-dd`
  - Response: 해당 날짜 세션 목록(리포트/요약용)

동작 원칙:
- iPhone이 세션의 Source of Truth. Watch는 WCSession 이벤트(start/pause/resume/stop)만 교환하고 per-second tick은 없음.
- iPhone 로컬(CoreData) → `/sessions/sync` 업로드. 서버는 idempotent upsert.
- Clock drift: iPhone이 `phoneNow` 전송, Watch는 offset을 저장해 경과 계산.

## 카테고리/태그 (선택)
- 기본 카테고리/색상 제공이 필요할 때:
  - `GET /categories` → `{ id, name, color }[]`
  - `POST /categories` → 커스텀 추가
  - `DELETE /categories/{id}` → 커스텀 삭제 (기본 카테고리는 삭제 불가)
- Task 생성/수정 시 `categoryId`를 참조하면 색상/이름 일관성 유지.

## 요약/리포트 (주간/일간)
- `GET /reports/daily?date=yyyy-MM-dd`
  - Response: `{ totalSec, tasks: [{ taskId, title, durationSec }], categories: [{ name, color, durationSec }] }`
- `GET /reports/weekly?start=yyyy-MM-dd`
  - Response: 일별/카테고리별 합계 등 그래프 데이터

## 인증/헤더
- 모든 요청: `Authorization: Bearer <JWT>`
- 기기 정보 필요 시: `X-Device-Id`, `X-Device-Type`(phone/watch) 헤더 추가 고려
