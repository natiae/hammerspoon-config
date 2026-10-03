# Escape Convert to English

Escape 입력 및 창 포커스 변경 시 입력 소스를 ABC 영문으로 전환합니다.

```lua
require('modules.esc_convert_to_eng'):start()
```

- 비영문 상태에서 Escape를 누르면 오른쪽 방향키를 보낸 뒤 ABC로 전환하고 Escape를 전달합니다.
- 창 포커스 변경 시 영문으로 전환합니다.
- `inputEnglish`: 전환할 입력 소스 ID. 기본값 `com.apple.keylayout.ABC`
- `onChangeOfScreenOnly`: `true`면 같은 화면 내 포커스 변경을 건너뜁니다. 기본값 `false`
- `:stop()`으로 단축키와 창 이벤트 구독을 해제합니다.

다른 사용자 모듈에 의존하지 않습니다. 마우스 이동은 외부 MouseFollowsFocus Spoon이 담당합니다.

## 참고 출처

- humblEgo, [[Hammerspoon] esc 키로 편하게 한영 변환하기 for vim](https://humblego.tistory.com/10)

글에 포함된 [원본 Gist의 `esc_convert_to_eng.lua`](https://gist.github.com/humblEgo/dc2fe3eb10137e38fedb8d0a72739682)를 참고 구현으로 기록합니다. 원본과 현재 코드의 핵심 동작은 같습니다. 현재 입력 소스 확인 → 비영문이면 오른쪽 방향키 입력 후 ABC 전환 → Escape 바인딩 비활성화 → Escape 전달 → 바인딩 재활성화 순서가 일치합니다.

현재 구현은 변수·함수를 객체 메서드로 정리하고 입력 소스 전환을 `changeToEng()`로 추출했습니다. `start()` / `stop()` 생명주기와 창 포커스 변경 시 영문 전환은 원본에 없는 추가 기능입니다.
