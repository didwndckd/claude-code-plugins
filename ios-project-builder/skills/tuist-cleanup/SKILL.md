---
name: tuist-cleanup
description: Tuist를 일회성으로 사용한 뒤 Tuist 관련 파일을 일괄 제거할 때 사용. `.xcodeproj` 가 이미 `tuist generate` 로 생성된 상태에서 호출되며, Tuist 진입점/매니페스트/헬퍼/버전 고정 항목을 제거하고 `.xcodeproj` / 소스 / 리소스 / `xcconfigs/` 는 보존한다. 단일 모듈 일회성 생성 흐름(`xcode-project-create-single`)이 마지막 단계로 본 스킬을 호출한다. 멀티 모듈 흐름(Tuist 지속 사용)에서는 호출하지 말 것 — 매니페스트가 사라지면 다음 `tuist generate` 가 깨진다.
inputs:
  optional:
    - skip_confirmation: "boolean, 기본 false. true면 제거 대상 목록 확인 절차를 생략하고 바로 삭제한다. 호출자(상위 스킬)가 이미 사용자 확인을 받았을 때 사용."
---

# Tuist 관련 파일 제거 스킬

`tuist generate` 로 만들어진 `.xcodeproj` 를 최종 산출물로 두고, Tuist 자체는 더 이상 사용하지 않을 때 호출한다. 본 스킬 종료 후 프로젝트 디렉터리는 **순수 Xcode 프로젝트** 형태로만 남는다.

## 사전 조건

다음이 충족되어 있어야 한다. 충족되지 않으면 사용자에게 안내하고 본 스킬을 즉시 종료한다 — 본 스킬이 generate를 직접 수행하지 않는다.

- `${CLAUDE_PROJECT_DIR}/<AppName>.xcodeproj` 가 존재 (`tuist generate` 가 이미 한 번 성공)
- 사용자가 Tuist 를 더 이상 사용하지 않을 의도임을 확인 (멀티 모듈 / 지속 사용이면 본 스킬을 호출하지 말 것)

## 1. 제거 대상 목록 작성 + 확인

`${CLAUDE_PROJECT_DIR}` 를 한 번 훑어 다음 후보가 실제로 존재하는지 확인하고, 존재하는 항목만 제거 대상에 넣는다 (없는 항목까지 사용자에게 보여주지 말 것).

### 제거 대상 (존재하는 것만)

| 경로 | 비고 |
|---|---|
| `${CLAUDE_PROJECT_DIR}/Tuist/` | 디렉터리 통째 (`ProjectDescriptionHelpers/`, 템플릿이 깐 `Package.swift` 등 모두 포함) |
| `${CLAUDE_PROJECT_DIR}/Tuist.swift` | Tuist 진입점 |
| `${CLAUDE_PROJECT_DIR}/Project.swift` | 매니페스트 (`.xcodeproj` 생성 후 불필요) |
| `${CLAUDE_PROJECT_DIR}/Package.swift` | 루트에 깔린 SPM 매니페스트 (있는 경우) |
| `${CLAUDE_PROJECT_DIR}/Package.resolved` | `tuist install` 흔적 (있는 경우) |
| `${CLAUDE_PROJECT_DIR}/Derived/` | `tuist generate` 가 만드는 임시 산출물 |
| `${CLAUDE_PROJECT_DIR}/.mise.toml` 또는 `.tool-versions` 의 `tuist` 항목 | 파일 자체가 아니라 **tuist 라인만** 다룬다. 아래 1-3 절차 참고. |

### 보존 대상 (절대 지우지 말 것)

- `${CLAUDE_PROJECT_DIR}/<AppName>.xcodeproj` — 본 흐름의 최종 산출물.
- `${CLAUDE_PROJECT_DIR}/Sources/`, `Resources/`, `Tests/` — 소스/리소스.
- `${CLAUDE_PROJECT_DIR}/xcconfigs/` — `.xcodeproj` 의 baseConfiguration 이 상대 경로로 참조한다. 지우면 빌드가 깨진다.
- `${CLAUDE_PROJECT_DIR}/.gitignore` — 사용자 추가 항목이 섞여 있을 수 있어 자동 편집하지 않는다 (3단계에서 사용자에게 정리 여부를 묻는다).
- 그 외 사용자 파일(README.md 등).

### 사용자 확인

`skip_confirmation` 이 `true` 가 아니면, 위에서 추린 **실재 항목 목록**을 사용자에게 한 번 보여주고 승인받는다. 사용자가 일부 항목을 보존하고 싶다고 하면 그 항목은 제거 목록에서 빼고 진행한다.

## 2. 제거 실행

### 2-1. 디렉터리/파일 일괄 제거

승인된 항목들에 대해 `rm -rf` 를 실행한다. 존재하지 않는 항목은 `rm -rf` 가 무해하게 통과하지만, 1단계에서 이미 존재 여부를 걸러두었으므로 명시한 것만 넘긴다:

```bash
cd "${CLAUDE_PROJECT_DIR}"
rm -rf Tuist Tuist.swift Project.swift Package.swift Package.resolved Derived
```

(승인된 항목만 인자로 넘긴다 — 위 줄은 모든 후보가 다 있는 최대 케이스 예시.)

### 2-2. 버전 고정 파일의 tuist 항목 정리

`.mise.toml` / `.tool-versions` 는 다른 도구 항목이 같이 들어 있을 수 있으므로 **파일 내용을 먼저 읽어 분기**한다.

**`.mise.toml`** 이 있는 경우:
- `[tools]` 아래 `tuist = "..."` 라인만 있으면 → 파일 통째로 삭제 (`rm .mise.toml`).
- 다른 도구 항목이 함께 있으면 → `Edit` 도구로 `tuist = "..."` 라인만 제거.

**`.tool-versions`** 가 있는 경우:
- `tuist <version>` 한 줄만 있으면 → 파일 통째로 삭제 (`rm .tool-versions`).
- 다른 도구 라인이 함께 있으면 → `Edit` 도구로 tuist 라인만 제거.

`.mise.toml` 과 `.tool-versions` 가 동시에 존재할 수도 있다 — 둘 다 같은 절차로 처리한다.

## 3. .gitignore 정리 안내 (자동 편집 금지)

`.gitignore` 에 Tuist 관련 무시 패턴(`Derived/`, `.build/`, `*.xcodeproj` 등)이 박혀 있을 수 있다. `mode=single` 흐름에서는 `*.xcodeproj` 무시는 처음부터 안 박혔지만, `Derived/` 같은 항목은 남아 있을 수 있다.

본 스킬은 `.gitignore` 를 **자동으로 편집하지 않는다** — 사용자 추가 항목과 섞여 있을 위험이 있다. 대신 사용자에게 다음을 안내한다:

- Tuist 흔적 패턴(`Derived/`, `.build/` 등)이 더 이상 필요 없다면 직접 정리 권장.
- 어떤 라인이 Tuist 와 무관한지(또는 사용자가 추가한 것인지) 본 스킬은 판단하지 않는다.

## 4. 검증

```bash
ls "${CLAUDE_PROJECT_DIR}"
```

기대 산출물:
- `<AppName>.xcodeproj`
- `Sources/`, `Resources/` (옵션 `Tests/`)
- `xcconfigs/`
- `.gitignore`, 사용자 파일

다음을 마지막으로 확인하고 사용자에게 한 줄로 보고한다:
- Tuist 관련 파일이 모두 사라졌는지 (`Tuist*`, `Project.swift`, `Package.swift*`, `Derived/` 부재).
- `.xcodeproj` 가 그대로 남아 있는지.
- `xcconfigs/` 가 그대로 남아 있는지.

빌드 검증은 본 스킬 범위가 아니다 — 호출자(상위 스킬) 또는 사용자가 Xcode에서 한 번 열어 빌드 성공을 확인한다. 빌드 실패의 흔한 원인은 `xcconfigs/` 경로 깨짐 — `.xcodeproj` 의 Project Settings → Configurations 에서 `xcconfigs/Debug.xcconfig` 등으로 경로를 다시 지정하면 해결된다.
