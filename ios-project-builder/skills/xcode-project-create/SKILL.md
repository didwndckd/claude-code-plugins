---
name: xcode-project-create
description: iOS Xcode 프로젝트를 새로 생성할 때 사용하는 진입 스킬. 사용자에게 단일/멀티 모듈 여부를 확인한 뒤, xcode-project-create-single 또는 xcode-project-create-multi 스킬에 위임한다. 위임이 끝나면 프로젝트 루트의 CLAUDE.md 를 생성/갱신해, 후속 작업에서 모델이 프로젝트 구조와 도구 사용 정책을 빠르게 파악할 수 있도록 한다. 본 스킬은 라우터 역할이며 직접 매니페스트나 모듈을 작성하지 않는다.
---

# Xcode 프로젝트 생성 진입 스킬

iOS Xcode 프로젝트를 새로 시작할 때의 진입점. 본 스킬은 **라우터**다 — 실제 베이스 셋업/매니페스트 작성/`tuist generate` 등은 단일/멀티 전용 하위 스킬이 처리한다. 본 스킬이 직접 모듈 파일을 만들거나 매니페스트를 편집하지 않는다.

아래 절차를 **위에서부터 순서대로** 따른다.

## 1. 모듈 구성 방식 결정

사용자에게 단일 모듈인지 멀티 모듈인지 묻는다. 사용자가 직전 대화에서 명시했다면 다시 묻지 말 것.

판단이 어렵다고 하면 다음 기준을 안내한다:

- **단일 모듈** — 앱 타깃 1개. 모든 소스가 프로젝트 루트(`Sources/`, `Resources/`)에 직접 위치. Tuist를 일회성으로만 사용해 `.xcodeproj` 를 만들고 Tuist 관련 파일은 제거. 이후 Xcode에서 직접 관리. 빠르게 시작하는 과제/프로토타입/소규모 앱에 적합.
- **멀티 모듈** — `Projects/<Module>/` 하위에 모듈별 디렉터리. 모듈 간 의존성 그래프를 명시적으로 구성. Tuist 지속 사용 (`.xcodeproj` 미커밋, 매번 `tuist generate`로 재생성). 레이어 분리/팀 작업/규모 있는 앱에 적합.

## 2. 하위 스킬 위임

선택에 따라 다음 스킬을 호출한다:

| 선택 | 호출할 스킬 |
|---|---|
| 단일 모듈 | `xcode-project-create-single` |
| 멀티 모듈 | `xcode-project-create-multi` |

호출된 스킬이 베이스 셋업, 외부 의존성(멀티만), 모듈 구성, `Project.swift` 작성, `tuist generate`, (단일의 경우) Tuist 관련 파일 제거까지 책임진다. 본 스킬은 그 절차를 반복하지 않는다.

위임 중에 하위 스킬이 사용자에게 추가 정보(앱 이름, 진입점, 번들 ID, 외부 SPM 패키지 목록, 모듈 의존성 그래프 등)를 물을 수 있다 — 그 흐름은 하위 스킬이 자체적으로 처리한다.

하위 스킬이 도중에 종료되면(예: Tuist 미설치) 본 스킬도 거기서 멈추고 3단계로 진행하지 않는다.

## 3. CLAUDE.md 싱크

위임이 정상 종료되면 `${CLAUDE_PROJECT_DIR}/CLAUDE.md` 를 생성/갱신한다. 목적은 **후속 대화에서 모델이 프로젝트 구조와 도구 사용 정책을 빠르게 파악**하도록 하는 것이다.

### 머지 정책

기존 `CLAUDE.md` 가 있으면 **머지**한다:
- 사용자 작성 본문/규칙은 보존.
- 본 스킬이 관리하는 섹션은 명확히 구분되도록 마커(예: `<!-- xcode-project-create:start -->` ~ `<!-- xcode-project-create:end -->`)로 감싸 그 안만 교체.
- 첫 생성 시에도 동일 마커를 함께 박아둔다 (다음 생성 시 갱신 위치를 식별하기 위함).

없으면 마커 포함해 새로 만든다.

### 반영할 내용 (해당 항목이 있는 경우만)

위임 결과와 현재 디렉터리 상태(`${CLAUDE_PROJECT_DIR}` 트리, `Project.swift`, `.mise.toml`/`.tool-versions`, `Package.swift`)를 근거로 다음을 정리한다. 추측 금지 — 파일에 박혀 있는 값을 그대로 반영한다.

- **프로젝트 구조**:
  - 단일: 루트 직속 레이아웃 (`Sources/`, `Resources/`, 옵션 `Tests/`, `xcconfigs/` 등 실제 존재하는 항목).
  - 멀티: 모듈 목록과 의존성 관계 (위임 중에 사용자가 정한 위상 정렬 결과를 그대로).
- **Tuist 사용 정책**:
  - 단일: "Tuist는 초기 generate에만 사용했고 관련 파일은 제거됨. `Project.swift` / `Tuist/` / `Package.swift` 는 존재하지 않음. 이후 의존성/설정 변경은 Xcode에서 직접 한다."
  - 멀티: "Tuist 지속 사용. 매니페스트(`Project.swift`, `Tuist/`) 변경 시 `tuist generate` 재실행. `.xcodeproj` / `.xcworkspace` 는 커밋하지 않음 (.gitignore 처리됨)."
- **버전 고정**: `.mise.toml` 또는 `.tool-versions` 에 박힌 Tuist 버전. 단일은 제거됐을 수 있으므로 파일을 먼저 확인하고 존재하는 항목만 적는다.
- **외부 SPM 의존성** (멀티만): `Dependency.swift` 의 `External` enum 에 등록된 키 목록. "추가/제거 시 `Package.swift` 와 `Dependency.External` 을 함께 갱신해야 한다" 는 운영 규칙도 함께 명시.
- **빌드 진입점**: 
  - 단일: `<AppName>.xcodeproj` 를 Xcode에서 오픈.
  - 멀티: `tuist generate` 후 생성되는 `.xcworkspace` (또는 `.xcodeproj`) 오픈.
- **앱 모듈 정보**: 앱 이름, 진입점(`SwiftUI` / `UIKit`), 번들 ID.

### 확인

작성 후 사용자에게 변경 요약을 보여주고 확인받는다. 신규 작성 시에는 전체 내용을, 머지 시에는 마커 영역의 변경 diff 만 보여주면 충분하다.
