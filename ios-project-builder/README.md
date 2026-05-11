# ios-project-builder

iOS 프로젝트 빌드를 돕는 Claude Code 플러그인. 스펙 분석부터 기술 스택 결정, 아키텍처 셋업, 네트워크 베이스 코드 생성까지 단계별로 위임할 수 있게 구성.

## 스킬 목록

### 스펙 / 아키텍처

| 스킬 | 역할 |
| --- | --- |
| `spec-analysis` | 코딩 과제 스펙을 읽고 `docs/specs/base.md`로 정리 |
| `ios-tech-stack` | base.md 기반으로 기술 스택 후보 제시 → `CLAUDE.md ## 기술 스택` 작성 |
| `ios-architecture-build` | 아키텍처 빌더 라우터. 클린 / MVVM / 대화형 중 선택해 후속 스킬 호출 |
| `ios-clean-architecture-build` | 클린 아키텍처 폴더 트리, `## 아키텍처 구조`, 도메인/데이터 룰. 내부적으로 네트워크/MVVM 빌더 호출 |
| `ios-mvvm-architecture-build` | MVVM 셋업. UIKit이면 `Base/ViewModel.swift` 생성, 비동기 + (반응형+UI) 조합으로 룰 작성 |
| `ios-conversational-architecture-build` | 대화형 아키텍처 설계. 정해진 틀 없이 user 주도로 폴더/룰 결정 |
| `ios-network-base-build` | 네트워크 베이스 코드(`Endpoint`/`APIResponse`/`APIClient`) 생성. Moya/URLSession × Swift Concurrency/Combine/RxSwift 조합 |

### Xcode 프로젝트 생성 / Tuist

아키텍처 빌드가 끝난 뒤(`CLAUDE.md`의 `## 기술 스택` / `## 아키텍처 구조`가 채워진 상태)에 호출되는 스킬군. 결정된 스택/구조에 맞춰 Xcode 프로젝트를 실제로 만든다.

| 스킬 | 역할 |
| --- | --- |
| `xcode-project-create` | 프로젝트 생성 진입 라우터. 단일/멀티 모듈 의도를 묻고 single/multi 스킬에 위임, 마지막에 `CLAUDE.md` 생성/갱신 |
| `xcode-project-create-single` | 단일 모듈 프로젝트를 Tuist **일회성**으로 생성. 베이스 셋업 → 앱 모듈 구성(루트 직접 배치) → `tuist generate` → Tuist 파일 일괄 제거. 결과물은 순수 `.xcodeproj` |
| `xcode-project-create-multi` | 멀티 모듈 프로젝트를 Tuist로 생성. 베이스 셋업 → 외부 SPM 의존성 등록 → 모듈 의존성 그래프 결정 → 모듈별 `xcode-module-add` 호출 → `tuist generate` |
| `tuist-base-setup` | Tuist 공통 초기 셋업. 설치 확인, mise/asdf로 버전 고정, `Tuist/`·`xcconfigs/`·`Tuist.swift` 배치, `.gitignore` 생성. `mode`(single/multi)는 `.gitignore` 정책에만 영향 |
| `tuist-cleanup` | Tuist 일회성 사용 후 매니페스트/헬퍼/버전 고정 항목 일괄 제거. `.xcodeproj`·소스·리소스·`xcconfigs/`는 보존. 단일 모듈 흐름 마지막 단계 전용 |
| `xcode-module-add` | 멀티 모듈 프로젝트에 새 모듈 추가. `Projects/<ModuleName>/` 디렉터리·진입점·리소스 배치, `Project.swift` 작성, `Dependency.swift`의 Internal enum 등록. 테스트 타깃·기존 소스/리소스 마이그레이션 옵션 |

## 훅

| 훅 | 트리거 | 역할 |
| --- | --- | --- |
| `sync-base-md` | `PostToolUse` (Write / Edit / MultiEdit) | `CLAUDE.md` 갱신 감지 시 `docs/specs/base.md`의 user 결정 항목 동기화를 모델에게 안내 |

발화 조건: 편집된 파일의 basename이 `CLAUDE.md`이고, `cwd/docs/specs/base.md`가 존재할 때만. 조건을 만족하면 모델에게 base.md의 결정 항목을 갱신/체크 처리하라는 `additionalContext`를 주입.

## 플로우

### 1. 아키텍처 빌드

```
spec-analysis
   │
   ▼
ios-tech-stack
   │
   ▼
ios-architecture-build  (라우터)
   │
   ├── 클린 아키텍처 ──→ ios-clean-architecture-build
   │                        ├── ios-network-base-build
   │                        └── ios-mvvm-architecture-build  (Presentation 부분)
   │
   ├── MVVM ───────────→ ios-mvvm-architecture-build
   │                        └── ios-network-base-build  (선택)
   │
   └── 대화형 설계 ─────→ ios-conversational-architecture-build
                            └── ios-network-base-build  (선택)
```

- `ios-clean-architecture-build`는 클린 아키텍처 + MVVM Presentation 셋업을 한 번에 처리.
- `ios-mvvm-architecture-build`는 단독 호출도 가능 (라우터에서 직접 진입).
- `ios-network-base-build`는 다른 빌더가 인자로 호출하는 하위 스킬.

### 2. 프로젝트 생성

아키텍처 빌드로 결정된 스택/구조를 토대로 실제 Xcode 프로젝트를 만든다.

```
xcode-project-create  (라우터)
   │
   ├── 단일 모듈 ──→ xcode-project-create-single
   │                    ├── tuist-base-setup  (mode=single)
   │                    └── tuist-cleanup     (generate 후 Tuist 파일 제거)
   │
   └── 멀티 모듈 ──→ xcode-project-create-multi
                       ├── tuist-base-setup  (mode=multi)
                       └── xcode-module-add  (모듈별 반복)
```

- 단일 모듈은 Tuist를 **일회성**으로만 사용 — 결과물은 순수 `.xcodeproj`. 이후 의존성/빌드 설정은 Xcode에서 직접 관리.
- 멀티 모듈은 Tuist를 **지속 사용** — `.xcodeproj` 미커밋, 매번 `tuist generate`로 재생성.
- `tuist-base-setup`은 `mode` 입력으로 `.gitignore` 정책만 분기, 베이스 스캐폴딩(`Tuist/`, `xcconfigs/`, `Tuist.swift`) 자체는 동일.
- `xcode-module-add`는 멀티 모듈 전용. 단일 모듈은 `xcode-project-create-single`이 자체 처리.

## 산출물 위치

- `docs/specs/base.md` — spec 분석 결과
- `CLAUDE.md` — `## 기술 스택`, `## 아키텍처 구조` 섹션 (+ `xcode-project-create`가 프로젝트 구조/도구 정책 갱신)
- `.claude/rules/` — 레이어/단위별 룰 파일 (`domain.md`, `data.md`, `presentation.md`, `<루트 마지막 컴포넌트>.md` 등)
- `Tuist/`, `xcconfigs/`, `Tuist.swift` — Tuist 베이스 스캐폴딩 (단일 모듈은 `tuist-cleanup` 후 `xcconfigs/`만 잔존)
- `Projects/<Module>/` — 멀티 모듈의 모듈별 디렉터리 (`Sources/`, `Resources/`, `Project.swift`, 옵션 `Tests/`)
- `<AppName>.xcodeproj` — `tuist generate` 산출물. 단일 모듈은 커밋 대상, 멀티 모듈은 미커밋
- 프로젝트 트리 — Presentation/Domain/Data 폴더, ViewModel 베이스, 네트워크 베이스 Swift 파일
