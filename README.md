# Personal Hammerspoon configuration

개인 macOS 창 배치, 창 선택, 입력 소스 표시 설정입니다. 배포용 Spoon이 아닌 Lua 모듈로 관리합니다.

## 설치

1. Hammerspoon을 설치하고 macOS 손쉬운 사용 권한을 허용합니다.
2. 이 저장소를 원하는 위치에 clone합니다.
3. 기존 `~/.hammerspoon`이 있다면 먼저 백업하고, 저장소 폴더를 가리키는 심볼릭 링크로 연결합니다.

```sh
ln -s /absolute/path/to/hammerspoon-config ~/.hammerspoon
```

4. [공식 SpoonInstall ZIP](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/SpoonInstall.spoon.zip)을 받아 압축을 풀고 `SpoonInstall.spoon`을 열어 설치합니다. 또는 저장소의 `Spoons/`에 넣습니다.
5. Hammerspoon을 시작하거나 설정을 다시 로드합니다. AppLauncher와 MouseFollowsFocus가 없으면 SpoonInstall이 설치합니다.

`Spoons/`는 외부 의존성 설치 위치이며 Git에서 제외합니다. `andUse()`는 이미 설치된 Spoon을 자동 업데이트하지 않습니다.

## 모듈

설정 진입점은 `config.lua`입니다. 기능별 사용법·설정·의존성은 각 폴더에서 관리합니다.

| 모듈 | 역할 |
|---|---|
| [Window Grid](modules/window_grid/README.md) | 두 단계 키 선택으로 창 배치 |
| [Window Picker](modules/window_picker/README.md) | 일반·최소화 창 선택과 검색 |
| [Input Source Aurora](modules/inputsource_aurora/README.md) | 입력 소스 상태 테두리 |
| [Escape Convert to English](modules/esc_convert_to_eng/README.md) | Escape·창 포커스에 따른 영문 전환 |
| [공통 유틸리티](modules/utils/README.md) | 화면 geometry·변경 알림·테마 |

설정 다시 로드는 Control + Option + Shift + R입니다. 앱 실행 단축키는 `config.lua`의 AppLauncher 설정에서 관리합니다.

## 업데이트


저장소에서 `git pull` 후 Control + Option + Shift + R로 다시 로드합니다. 직접 수정한 내용은 먼저 커밋하거나 별도로 보관합니다.

외부 Spoon은 Hammerspoon Console에서 별도로 업데이트합니다.

```lua
if spoon.SpoonInstall:updateRepo() then
    for _, name in ipairs({ "AppLauncher", "MouseFollowsFocus", "SpoonInstall" }) do
        print(name, spoon.SpoonInstall:installSpoonFromRepo(name))
    end
end
```

## 현재 로컬 구성

이 맥의 `~/.hammerspoon`은 이 저장소를 가리킵니다. 이전 Mackup의 `.hammerspoon` 폴더는 이관 시점 백업으로 보존했으며, Mackup 사용자 지정 백업 목록에서 제외했습니다. 이후 변경은 이 저장소에서 관리합니다.

## 코드 스타일


Lua는 공백 2칸, 작은따옴표 우선, 줄 길이 100자를 기준으로 StyLua로 포맷합니다. `.editorconfig`와 `.stylua.toml`에 규칙을 정의하며 외부 `Spoons/`는 제외합니다.

```sh
mise trust
mise install
mise run fix:format
mise run check:format
```

`check:*`는 프로젝트 품질을 검사하고, `fix:*`는 자동 수정 가능한 항목을 수정합니다. `check:format`은 포맷 검사만 수행하고 `fix:format`은 파일에 포맷을 적용합니다.

StyLua 버전은 `mise.toml`에 고정합니다. 포맷 검사는 정적 분석 linter를 대체하지 않습니다.

## 로드 상태 알림

`init.lua`는 오류 처리를 먼저 준비하고 실제 설정인 `config.lua`를 로드합니다. 마우스가 있는 화면 왼쪽 아래에 성공은 1.5초, 오류는 6초 동안 표시합니다. 로드 오류 및 처리되지 않은 실행 오류의 상세 내용은 Console에 남깁니다. `init.lua` 자체 또는 알림 모듈의 로드 오류는 Hammerspoon 기본 오류 처리로 표시됩니다.

## 참고 출처와 감사

이 설정은 공개된 Hammerspoon 활용 글과 Spoon에서 아이디어와 구현 방식을 참고해 발전시켰습니다. 모듈별 출처와 적용 범위는 아래에 기록합니다.

- [Input Source Aurora의 참고 출처](modules/inputsource_aurora/README.md#참고-출처)
- [Escape Convert to English의 참고 출처](modules/esc_convert_to_eng/README.md#참고-출처)
- [Window Grid의 참고 출처](modules/window_grid/README.md#참고-출처)
