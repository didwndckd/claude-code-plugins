---
name: ios-mvvm-architecture-build
description: iOS MVVM 아키텍처 초기 셋업. UIKit이면 `<루트>/Base/ViewModel.swift` 생성 + `## 아키텍처 구조` 섹션 + `.claude/rules/<루트 마지막 컴포넌트>.md`(비동기 + 반응형+UI 조합) 작성, 필요 시 `ios-network-base-build` 호출. 인자(`ui`/`async`/`reactive`/`network`/`root`)를 받으면 우선 사용하고, 비는 항목은 `CLAUDE.md ## 기술 스택` 또는 user 질문으로 채운다. 기술 스택 결정(`ios-tech-stack`) 이후, 화면별 코드 작성 전에 호출.
arguments:
  - name: ui
    description: UI 프레임워크. UIKit / SwiftUI / 혼합. 비우면 `CLAUDE.md ## 기술 스택`에서 읽음.
    type: string
    required: false
    hint: "UIKit"
  - name: async
    description: 비동기 패턴. Swift Concurrency / Combine / RxSwift / 혼합. 비우면 `CLAUDE.md ## 기술 스택`에서 읽음.
    type: string
    required: false
    hint: "Combine"
  - name: reactive
    description: 반응형 라이브러리. Combine / RxSwift / 사용 안 함. 비우면 `CLAUDE.md ## 기술 스택`에서 읽음.
    type: string
    required: false
    hint: "Combine"
  - name: network
    description: 네트워크 라이브러리. URLSession / Alamofire / Moya / 사용 안 함. 비우면 `CLAUDE.md ## 기술 스택`에서 읽고, 거기도 없으면 user에게 묻기.
    type: string
    required: false
    hint: "URLSession"
  - name: root
    description: 생성 루트(프로젝트 루트 기준 상대 경로). 비우면 `AskUserQuestion`으로 user에게 묻기 (기본 추천 `.`).
    type: string
    required: false
    hint: "."
---

# MVVM 아키텍처 구조 빌더 (iOS)

## 사전 조건

- `ui`/`async`/`reactive` 인자가 모두 채워지지 않은 경우, `CLAUDE.md`(프로젝트 루트)의 `## 기술 스택` 섹션이 존재해야 한다. 인자도 비어있고 `## 기술 스택`도 없으면 멈추고 user에게 `ios-tech-stack`을 먼저 돌리라고 안내.

## 작업 절차

### 1. 기술 스택 적재

다음 네 값을 결정한다:

- **UI**: UIKit / SwiftUI / 혼합
- **비동기**: Swift Concurrency / Combine / RxSwift / 혼합 등
- **반응형**: Combine / RxSwift / 사용 안 함 등
- **네트워크**: 6단계에서 사용

해결 순서: 인자(`ui`/`async`/`reactive`/`network`) → `CLAUDE.md`의 `## 기술 스택` 표 → 그래도 비면 `AskUserQuestion`. 인자가 우선이고, 인자가 비어있을 때만 `## 기술 스택`을 읽는다.

### 2. 생성 루트 결정

인자 `root`가 있으면 그 값 사용. 없으면 `AskUserQuestion`으로 user에게 묻는다 (기본 추천 `.`).

### 3. ViewModel 베이스 파일 생성 (UIKit인 경우)

UI 값에 따라 분기:

- **UIKit**: `${CLAUDE_SKILL_DIR}/scripts/create-base.sh <루트>` 호출 → `<루트>/Base/ViewModel.swift` 생성.
- **SwiftUI**: 이 단계 스킵.
- **혼합**: `AskUserQuestion`으로 UIKit 화면용 베이스 파일을 생성할지 user에게 묻는다. 생성 동의 시 UIKit과 동일하게 진행.

스크립트 종료 코드:
- `0`: 성공 (또는 이미 존재하여 스킵)
- `1`: 인자 부족 (usage)
- `3`: 템플릿 파일 누락 → user에게 보고하고 멈춤

### 4. CLAUDE.md `## 아키텍처 구조` 섹션 작성

`CLAUDE.md`(프로젝트 루트)의 `## 아키텍처 구조` 섹션을 아래 분기로 처리한다. 다른 섹션은 변경하지 않는다.

#### 4-a. 기존 섹션이 없는 경우

새 섹션을 만든다. 본문:

- 첫 줄: "이 프로젝트는 **MVVM**을 따른다."
- 폴더 트리 (UIKit + 베이스 파일 생성):

```
Base/
└── ViewModel.swift
<화면명>/
├── ViewModel/
└── View/
```

- 폴더 트리 (SwiftUI 또는 베이스 파일 미생성):

```
<화면명>/
├── ViewModel/
└── View/
```

- 6단계에서 네트워크 베이스를 생성한 경우 트리 최상위에 `Network/`를 추가.

#### 4-b. 기존 섹션이 있는 경우 (상위 아키텍처가 먼저 작성)

상위 아키텍처(예: 클린 아키텍처)가 이미 `## 아키텍처 구조`를 작성한 상태. 기존 본문은 **보존**한다 — 첫 줄("이 프로젝트는 **X**를 따른다.")도 교체하지 않는다.

기존 트리에서 2단계 `<루트>`(또는 상위가 명시한 Presentation 루트)와 일치하는 노드를 찾아, 그 아래에 MVVM 트리를 끼워넣는다:

- UIKit + 베이스 파일 생성: `Base/ViewModel.swift` + `<화면명>/{ViewModel,View}/`
- SwiftUI 또는 베이스 미생성: `<화면명>/{ViewModel,View}/`

매칭되는 노드를 단정하기 어려우면 `AskUserQuestion`으로 user에게 어느 노드 아래에 추가할지 묻는다.

#### 공통

`<화면명>/ViewModel/`, `<화면명>/View/` 폴더는 **트리 가이드**일 뿐, 본 스킬에서 미리 생성하지 않는다 (화면 작성 시점에 생성).

### 5. 룰 작성

`build-rule.sh`는 frontmatter + 본문을 stdout으로 뱉고, 저장은 본 스킬에서 redirect로 처리한다. `<루트>`는 2단계에서 결정된 생성 루트(프로젝트 루트 기준 상대 경로).

룰 파일명은 `<루트>`의 마지막 경로 컴포넌트를 소문자로 변환한 값 + `.md`. `<루트>`가 `.` 또는 비면 `presentation.md`로 fallback.

예:
- `<루트>` = `.` → `presentation.md`
- `<루트>` = `./Sources/Presentation` → `presentation.md`
- `<루트>` = `Modules/Feed` → `feed.md`

```
mkdir -p .claude/rules
${CLAUDE_SKILL_DIR}/scripts/build-rule.sh <루트> <async-key> <io-key> [--base] > .claude/rules/<rule-filename>
```

3단계에서 `Base/ViewModel.swift`를 생성한 경우 `--base` 플래그를 붙인다 (룰 본문의 폴더 구조 트리에 `Base/ViewModel.swift` 노드가 포함됨). SwiftUI거나 베이스 미생성이면 플래그 생략.

키 매핑:

- `<async-key>` (비동기 값 기반)
  - Swift Concurrency → `swift-concurrency`
  - Combine → `combine`
  - RxSwift → `rx`
- `<io-key>` (반응형 + UI 값 기반)
  - UIKit + Combine → `combine-uikit`
  - UIKit + RxSwift → `rx-uikit`
  - SwiftUI → `swiftui`

매핑에 없는 조합(예: UIKit + 반응형 "사용 안 함", 비동기 "혼합", UI "혼합")인 경우 `AskUserQuestion`으로 user에게 어느 변형 키를 사용할지 묻고 그 값으로 호출.

스크립트 종료 코드:
- `0`: 성공
- `1`: 인자 부족 (usage)
- `2`: 키 값 오류 → user에게 다시 묻고 재호출
- `3`: 템플릿 파일 누락 → user에게 보고하고 멈춤

기존 `.claude/rules/<rule-filename>`이 있으면 user에게 덮어쓸지 묻는다.

### 6. 네트워크 베이스 빌더 호출 (선택)

네트워크 값이 `사용 안 함` 또는 비어 있으면 이 단계 스킵. 그 외엔 `Skill` 도구로 `ios-network-base-build` 호출.

인자 매핑:
- `path`: `<루트>/Network` (2단계에서 결정된 루트 기준)
- `network`: 1단계에서 결정된 네트워크 값
- `async`: 1단계에서 결정된 비동기 값

서브에이전트 격리 컨텍스트에서 실행되므로 호출 결과(stdout 요약)만 받아서 다음 단계로 진행한다. 호출 성공 시 4단계의 트리 표기에 `Network/`를 반영.

## 제약

- `CLAUDE.md`의 `## 아키텍처 구조` 외 섹션은 임의 변경하지 않는다.
- 화면별 폴더(`<화면명>/ViewModel/`, `<화면명>/View/`)는 본 스킬에서 생성하지 않는다.
- 코드 작성, 화면별 구현, 프로젝트 파일(.xcodeproj) 변경은 이 스킬 범위 밖.
