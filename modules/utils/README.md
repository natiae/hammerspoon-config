# Shared Utilities

## mac_window_geometry

화면별 좌표 계산과 화면 변경 알림을 제공합니다. 색상이나 공유 여백 상태는 보관하지 않습니다.

```lua
local geometry = require('modules.utils.mac_window_geometry')
local info = geometry.get(screen, {
  top = 'auto', left = 6, right = 6, bottom = 6,
})
```

- `get(screen, margins)`: `fullFrame`, `workFrame`, `menuBarHeight`, `insets`, `placementFrame`, `borders`를 반환합니다.
- `all(margins)`: 연결된 화면 ID별 계산 결과를 반환합니다.
- `normalizeMargins(options)`: 여백을 검증하고 복사합니다. 생략한 방향은 0입니다.
- `top = 'auto'`: 전체 화면과 작업 영역의 상단 차이를 사용합니다. 차이가 0이면 `autoTopFallback`을 사용하며 기본값은 28pt입니다.
- `top`에 숫자를 넣으면 고정 두께를 사용합니다. 다른 방향은 0 이상의 숫자입니다.
- `placementFrame`은 테두리 안쪽과 시스템 작업 영역의 교집합이므로 메뉴바/Dock 공간을 중복 차감하지 않습니다.
- 단위는 macOS 화면 좌표의 point입니다.

```lua
local unsubscribe = geometry.subscribe(function(phase)
  -- 'changing': 즉시 숨김/무효화
  -- 'settled': 마지막 변경 이벤트에서 1초 후 재생성
end)
-- 종료 시 unsubscribe()
```

모든 구독자가 화면 감지기와 타이머 하나를 공유합니다. 마지막 구독 해제 시 감지를 중지합니다. 한 콜백의 오류는 다른 콜백의 실행을 막지 않습니다.

## window_theme

Window Grid와 Window Picker의 폰트·모서리·색상 설정입니다.

- `background`: 창 선택기와 안내 배경, 불투명도 97%
- `overlay`: 배치 Grid 배경, 불투명도 42%
- `surface`, `emptySurface`: 창 선택기의 카드
- `text`, `muted`, `disabled`, `accent`, `gridLine`: 텍스트와 격자
- `selected`: 선택한 시작 칸
- `target`, `targetFill`: 배치할 창 강조

배치 Grid는 대상 창이 보이도록 투명도를 달리합니다. Aurora의 색상은 이 테마와 독립적입니다.

## status_overlay

설정 로드 성공·오류 및 실행 오류를 마우스가 있는 화면의 작업 영역 왼쪽 아래에 표시합니다. `show(message, failed)`로 호출하며 기존 알림을 교체합니다. 테마 파일 오류에도 표시할 수 있도록 다른 사용자 모듈에 의존하지 않습니다.
