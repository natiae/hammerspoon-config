# Window Picker

일반 창과 최소화된 창을 같은 화면에서 키로 선택합니다.

```lua
require('modules.window_picker'):start({
  hotkey = {{ 'cmd', 'ctrl' }, 'up'},
})
```

위 예시의 실행 키는 Command + Control + ↑입니다. `hotkey`는 필수 설정이며, 새 설정으로 `start(options)`를 호출하면 기존 단축키를 교체합니다. `:stop()`으로 입력 감지와 화면을 정리할 수 있습니다.

## 사용법


- 일반 창 12개: `qwer / asdf / zxcv`
- 최소화 창 9개: `uio / jkl / n,.`
- 좌우 방향키: 페이지 이동
- `/`: 같은 그리드에서 앱 이름/창 제목 필터 입력
- 검색 중 Enter: 필터 유지 후 라벨 선택 모드
- 검색 중 Escape: 이전 필터로 복귀
- 선택 모드 Escape: 닫기

Mission Control에 라벨을 붙이는 방식이 아닌 독립 선택기입니다. 다른 Spaces 및 전체 화면 창의 조회는 macOS 접근성 API 제한을 받습니다. 검색의 한글 IME 조합 입력은 검증되지 않았습니다.

## 의존성

`utils/window_theme`로 색상과 폰트를 공유합니다. Window Grid 및 Aurora에는 의존하지 않습니다.
