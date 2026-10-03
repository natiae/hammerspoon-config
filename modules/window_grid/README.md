# Window Grid

두 단계 키 선택으로 창을 배치합니다. 기본 실행 키는 Control + Option + Shift + G입니다.


`config.lua`에서 키 행렬과 실행 단축키를 지정합니다.

```lua
require('modules.window_grid'):start({
    keys = {
        { 'q', 'w', 'e' },
        { 'a', 's', 'd' },
        { 'z', 'x', 'c' },
    },
    hotkey = {{ 'ctrl', 'option', 'shift' }, 'g'},
    margins = { top = 'auto', left = 6, right = 6, bottom = 6 },
})
```

행렬은 모든 행의 길이가 같아야 하며, 중복 키와 Escape/Delete/방향키는 사용할 수 없습니다. R행×C열이면 두 단계 선택으로 최종 R²행×C²열을 배치합니다. 예를 들어 2행×3열은 4행×9열입니다. 설정은 `:configure(options):start()`로도 적용할 수 있고 `:stop()`으로 감지기·단축키·화면을 정리할 수 있습니다.

`qwe / asd / zxc`의 3×3 영역을 두 번 선택하여 9×9의 시작 칸을 정하고, 다시 두 번 선택하여 끝 칸을 정합니다. 예를 들어 `qqxx`는 `(0,0)`부터 `(4,8)`까지 포함합니다.

- Escape: 취소
- Delete: 한 단계 뒤로
- 방향키: 대상 모니터 선택
- 배치할 창은 금색 테두리와 제목으로 강조됩니다.

## 여백과 의존성

`margins`는 이 모듈만의 설정입니다. Aurora의 테두리와 맞추려면 각각 같은 값을 지정합니다. 상단 `'auto'` 및 여백 계산은 [공통 geometry 설명](../utils/README.md)을 참고하세요.

- `utils/mac_window_geometry`: 배치 영역 계산, 화면 변경 구독
- `utils/window_theme`: 화면 스타일

화면 변경 시 그리드를 닫고, 마지막 이벤트 1초 뒤 캔버스를 미리 생성합니다.

## 참고 출처

- Diego Zamboni, [WindowGrid Spoon](https://www.hammerspoon.org/Spoons/WindowGrid.html) · [소스](https://github.com/Hammerspoon/Spoons/blob/master/Source/WindowGrid.spoon/init.lua)
- Hammerspoon, [hs.grid](https://www.hammerspoon.org/docs/hs.grid.html) · [소스](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/grid/grid.lua)

기존에 사용하던 WindowGrid Spoon의 격자 기반 창 배치 경험에서 출발했습니다. Spoon은 `hs.grid`를 연결하는 역할이며, 배치 대상 창 강조 같은 동작은 `hs.grid` 구현을 참고했습니다. 현재의 두 단계 키 선택, 행렬 설정, 캔버스 렌더링과 화면 변경 처리는 별도 모듈로 구현했으며, WindowGrid Spoon을 직접 사용하거나 해당 소스 전체를 옮긴 것은 아닙니다.
