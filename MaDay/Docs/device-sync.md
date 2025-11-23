# Device Sync (iPhone ↔︎ Apple Watch)

WCSession 기반 실시간 동기화 요구사항과 동작 규칙 요약입니다. iPhone이 세션의 Source of Truth이며, Watch는 이벤트만 전달합니다.

## 핵심 원칙
- **이벤트 기반**: start/pause/resume/stop 이벤트만 왕복. per-second tick 메시지는 금지.
- **Source of Truth**: iPhone이 세션의 최종 상태를 관리하고 서버로 업로드. Watch는 로컬 미니 상태 보관 가능하지만 최종 확정은 iPhone.
- **Idempotent Session**: `sessionId(UUID)`로 동일 세션을 식별, 중복/재전송에 대비.
- **Clock Drift 보정**: iPhone이 `phoneNow`를 포함해 보내고, Watch는 offset을 저장해 경과 계산 시 사용.

## 데이터 모델
```
TimerSession { sessionId, taskId, startAt, endAt?, durationSec, sourceDevice, synced, version, lastModifiedAt }
TimerEvent { sessionId, type(start|pause|resume|stop), timestamp }
```

## 동작 흐름
1) **시작(Start)**  
   - Watch에서 start: `TimerEvent(start, timestamp, sessionId)` → iPhone.  
   - iPhone은 세션 생성/업데이트 후 로컬 저장(CoreData) → 필요 시 서버 `/sessions/sync` 호출.

2) **일시정지/재시작(Pause/Resume)**  
   - 이벤트 전달 동일. iPhone은 세션 duration 반영, 로컬 저장, 서버에 동기화.

3) **종료(Stop)**  
   - 이벤트 전달 후 iPhone이 세션 종료 처리(endAt, durationSec 확정), 저장, 서버 업로드.

4) **오프라인/지연 처리**  
   - WCSession 메시지 실패 시 iPhone 재시도.  
   - Watch는 큐에 이벤트를 저장했다가 reachable 시 전달(단, per-second tick 없음).

## WCSession 메시지 포맷(예시)
```json
{
  "sessionId": "<uuid>",
  "type": "start|pause|resume|stop",
  "timestamp": 1700000000,      // epoch seconds
  "phoneNow": 1700000005        // iPhone에서 보낼 때 포함 (drift 계산용)
}
```

## iPhone 측 처리
- WCSession 수신 → TimerEvent 생성 → CoreData 저장 → 세션 갱신(durationSec 누적) → SyncService(`/sessions/sync`) 호출.
- `phoneNow` 포함 전송으로 Watch는 offset 계산(`offset = phoneNow - watchNow`) 후 경과 시간 계산에 활용.

## Watch 측 처리
- start/pause/resume/stop 시 메시지 전송. per-second 전송 금지.
- `phoneNow` 수신 시 offset 보관. 로컬 UI는 offset을 적용해 경과 시간 표시.
- 오류/미전송 시 큐에 이벤트를 저장하고 reachable 시 전송.

## 서버 동기화와의 관계
- iPhone이 세션을 서버로 업로드하는 유일 주체(Watch → iPhone → 서버 단방향).
- `/sessions/sync`는 `sessionId` 기반 idempotent upsert, `version/lastModifiedAt`로 충돌 해결.

## 실패/충돌 처리
- 동일 `sessionId`로 도착한 이벤트는 순서대로 적용. 중복은 무시.
- iPhone 로컬 저장 실패 시 사용자에게 알림 또는 재시도 큐.
- 서버 업로드 실패 시 BackgroundTasks/재시도 스케줄러 활용.
