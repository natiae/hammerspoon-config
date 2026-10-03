# Input Source Aurora

ABC 영문 입력이 아닐 때 화면 가장자리에 색상 테두리를 표시합니다.

## 설정


두 모듈은 독립적인 설정을 받습니다. Aurora의 `border`를 바꿔도 Grid의 `margins`는 바뀌지 않습니다. 같은 여백이 필요하면 각각 같은 값을 지정합니다. Geometry 모듈은 화면 정보 계산과 변경 알림만 공유합니다.

```lua
require('modules.inputsource_aurora'):start({
    color = { 12, 79, 135 }, -- RGB: 0..255
    alpha = 0.4,            -- 불투명도: 0..1
    border = { top = 'auto', left = 6, right = 6, bottom = 6 },
})
```

- `top = 'auto'`: 화면 작업 영역의 상단 차이로 메뉴바 높이를 계산합니다. 숨김 상태처럼 차이가 0이면 28pt를 사용합니다. `autoTopFallback = 0` 등으로 대체 높이를 지정할 수 있습니다.
- `top = 24`: 상단을 고정 24pt로 지정합니다. 다른 방향도 0 이상의 숫자로 지정합니다.
- `border`/`margins`에서 생략한 방향은 0입니다. Grid는 메뉴바와 Dock이 제외된 작업 영역과 교집합을 사용하므로 시스템 여백은 유지합니다.
- 두께는 macOS 화면 좌표의 point 단위입니다.

## 동작과 의존성

`utils/mac_window_geometry`에서 테두리 좌표를 계산하고 화면 변경을 구독합니다. 화면 변경 즉시 테두리를 숨기고, 마지막 이벤트 1초 뒤 다시 그립니다.

`:configure(options)`로 설정을 바꾸고 `:start()` / `:stop()`으로 실행 상태를 제어할 수 있습니다. 입력 소스 변경 콜백은 Hammerspoon의 단일 콜백을 사용합니다.

## 참고 출처

- John Grib, [해머스푼으로 한/영 전환 오로라를 만들자](https://johngrib.github.io/wiki/hammerspoon-inputsource-aurora/)

입력 소스를 화면 가장자리의 반투명 색상으로 표시하는 아이디어와 초기 구현의 참고 출처입니다. 현재 모듈은 이를 바탕으로 네 방향 테두리, 색상·불투명도·두께 설정, 화면 변경 대응 및 독립적인 geometry 설정을 추가해 정리했습니다.
