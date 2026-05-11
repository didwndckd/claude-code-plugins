---
name: xcode-project-create-single
description: 단일 모듈 iOS Xcode 프로젝트를 Tuist로 **일회성** 생성할 때 사용. 베이스 셋업(tuist-base-setup 위임), 프로젝트 루트에 앱 모듈 구성(진입점/리소스/Project.swift), tuist generate 후 **Tuist 관련 파일 일괄 제거**까지 처리한다. 결과물은 순수 .xcodeproj + 소스/리소스/xcconfigs 만 남으며, 이후 의존성·빌드 설정은 Xcode에서 직접 관리한다. SPM 등 외부 의존성과 `Dependency.swift`/`Package.swift` 는 본 스킬에서 다루지 않는다 — 필요하면 generate 후 Xcode에서 추가한다. 멀티 모듈 프로젝트는 xcode-project-create-multi 스킬을 사용한다.
---

# 단일 모듈 Xcode 프로젝트 생성 스킬 (Tuist 일회성 사용)

Tuist 기반 **단일 모듈** iOS 프로젝트의 초기 구성을 처리한다. 본 스킬의 흐름은 **Tuist를 한 번만 사용해 `.xcodeproj` 를 만든 뒤, Tuist 관련 파일을 모두 제거**하는 것이다. 이후 사용자는 순수 Xcode 프로젝트로 작업하며, SPM 같은 의존성은 Xcode에서 직접 추가한다.

따라서 본 스킬은:
- `Dependency.swift` 의 External/Internal 항목을 채우지 않는다 (어차피 generate 후 제거됨).
- `Package.swift` 도 채우지 않는다 (`tuist install` 미실행).
- `Project.swift` 의 `dependencies` 도 비어둔 상태로 작성한다.

단일 모듈은 구조적으로 모듈 1개가 프로젝트 루트에 직접 위치한다 — `Projects/<Module>/` 하위 디렉터리를 만들지 않는다. 사용자가 단일/멀티 의도를 명시하지 않은 채 호출했다면, 먼저 단일 모듈 + 일회성 generate 의도가 맞는지 확인한다. 멀티 모듈이거나 Tuist를 지속 사용할 계획이면 본 스킬을 종료하고 `xcode-project-create-multi` 사용을 안내한다.

아래 절차를 **위에서부터 순서대로** 따른다. 한 단계의 결과에 따라 다음 단계 진행 여부가 달라질 수 있다.

## 1. 베이스 셋업 — `tuist-base-setup` 위임

`tuist-base-setup` 스킬을 호출한다. frontmatter `inputs`에 다음을 전달:

| 인자 | 값 |
|---|---|
| `mode` | `single` |
| `tuist_version` | (옵션) 사용자가 미리 지정했으면 그 값. 없으면 `tuist-base-setup`이 사용자에게 직접 묻는다. |

이 스킬이 다음을 처리한다 (반복하지 않는다):
- Tuist 설치 확인 (미설치 시 본 흐름 즉시 종료)
- Tuist 버전 결정 + mise/asdf로 고정 (`.mise.toml` 또는 `.tool-versions`)
- 베이스 스캐폴딩 (`Tuist/`, `xcconfigs/`, `Tuist.swift`)
- `.gitignore` 생성 — `mode=single` 이므로 `*.xcodeproj` / `*.xcworkspace` 를 **무시하지 않음**

본 스킬의 흐름에서 `Tuist/`, `Tuist.swift`, `Package.swift` 등은 5단계에서 제거된다. 하지만 `Project.swift` 작성 시 `BundleID` / `ProjectSetting` 등 `ProjectDescriptionHelpers/` 의 헬퍼를 사용해야 하므로, 베이스 스캐폴딩 자체는 정상적으로 깔아야 한다. **3단계의 `Dependency.swift` / `Package.swift` 편집은 건너뛴다** (멀티 스킬과 다른 점).

## 2. 앱 정보 확인

호출자(상위 스킬/워크플로)가 frontmatter `inputs` 로 값을 전달했으면 그대로 사용하고, 누락된 항목만 사용자에게 묻는다. 직접 invoke된 경우(인자 없음)에는 다음을 묻는다 (이미 사용자가 언급한 값은 다시 묻지 말 것):

- **앱 이름** — Swift identifier (예: `MyApp`)
- **진입점**: `swiftui` 또는 `uikit`
- **번들 ID** (3단계 `Project.swift` 작성 시 필요. 예: `BundleID.create("<AppName>")` 결과 그대로)
- **테스트 타깃 포함 여부** — 포함 시 `Tests/<AppName>Tests.swift` 빈 파일 + 매니페스트에 테스트 타깃 추가
- **기존 소스 마이그레이션** (옵션) — 절대경로. 그 경로의 모든 파일/디렉터리(숨김 파일 포함)를 루트 `Sources/`로 `mv`. 원본 디렉터리는 비워진 채 남는다.
- **기존 리소스 마이그레이션** (옵션) — 위와 동일하게 루트 `Resources/`로 `mv`

외부 SPM 등 의존성은 묻지 않는다 — 본 스킬에서는 다루지 않으며, generate 후 Xcode에서 직접 추가한다.

## 3. 앱 모듈 구성 — `xcode-app-module-add` 위임

`xcode-app-module-add` 스킬을 호출한다. 단일 모듈은 모듈이 프로젝트 루트에 직접 위치하므로 `output_dir` 을 **프로젝트 루트**로 지정한다. frontmatter `inputs`에 다음을 전달:

| 인자 | 값 |
|---|---|
| `output_dir` | `${CLAUDE_PROJECT_DIR}` |
| `name` | 2단계에서 받은 앱 이름 |
| `entry_point` | 2단계에서 받은 진입점 (`swiftui` / `uikit`) |
| `bundle_id` | 2단계에서 받은 번들 ID |
| `with_tests` | 2단계에서 받은 값 (기본 `true`) |
| `migrate_sources_from` | 2단계에서 받았으면 절대경로 |
| `migrate_resources_from` | 2단계에서 받았으면 절대경로 |
| `dependencies` | **빈 배열** — 본 single 흐름은 외부/내부 의존성을 박지 않는다 (`Dependency.swift` / `Package.swift` 가 5단계에서 통째로 제거됨) |

`xcode-app-module-add` 가 다음을 처리한다 (반복하지 않는다):
- `init-app-module.sh` 호출로 `Sources/Entry/`, `Resources/Info.plist`, `Resources/Assets.xcassets/` 배치
- (기본) `Tests/<AppName>Tests.swift` 빈 파일 생성
- 옵션 마이그레이션 (`mv` + 원본 빈 폴더 자동 삭제)
- `Project.swift` 작성 (`.app`, `ProjectSetting.app`, sources/resources/infoPlist, 옵션 테스트 타깃)
- `Dependency.swift` 는 편집하지 않음 (앱 모듈은 등록 대상 아님)

`Project.swift` 의 `dependencies` 가 빈 배열로 박히는 점만 본 single 흐름의 특이 사항이다 — 일회성 generate 후 모두 제거되므로 외부/내부 의존성 표현이 무의미함.

## 4. 프로젝트 생성

```bash
tuist generate
```

`tuist install` 은 실행하지 않는다 — 외부 SPM 패키지를 본 스킬에서 다루지 않기 때문. (`Package.swift` 의 템플릿 샘플 항목이 있어도 이 단계에서 무시된다.)

generate 결과로 `${CLAUDE_PROJECT_DIR}/<AppName>.xcodeproj` 가 생성된다. 진행 전 빌드까지 확인하고 싶다면 사용자가 Xcode에서 한 번 열어 빌드해보고, 문제 없으면 5단계로 진행한다.

## 5. Tuist 관련 파일 제거 — `tuist-cleanup` 위임

`tuist-cleanup` 스킬을 호출한다. 본 스킬은 호출자에 추가 인자를 강제로 박지 않으며, 사용자 확인 절차도 `tuist-cleanup` 이 자체적으로 진행한다.

| 인자 | 값 |
|---|---|
| `skip_confirmation` | (옵션) 본 single 흐름 진행 중에 이미 사용자가 "Tuist 제거 단계로 진행해도 됨"을 명시적으로 확인했다면 `true` 로 넘겨도 된다. 그렇지 않으면 생략해 `tuist-cleanup` 이 한 번 더 확인하도록 둔다. |

`tuist-cleanup` 이 다음을 처리한다 (본 스킬은 반복하지 않는다):
- 제거 대상 실재 여부 확인 + 사용자 승인
- `Tuist/`, `Tuist.swift`, `Project.swift`, `Package.swift`, `Package.resolved`, `Derived/` 일괄 제거
- `.mise.toml` / `.tool-versions` 의 `tuist` 항목 정리 (단독이면 파일 삭제, 다른 도구 함께면 라인만 제거)
- `.gitignore` 정리 안내 (자동 편집 금지)
- 산출물 검증 (`<AppName>.xcodeproj`, `Sources/`, `Resources/`, `xcconfigs/` 보존 확인)

빌드 검증(Xcode 오픈 후 빌드 성공)은 본 스킬 종료 후 사용자에게 한 번 안내한다 — `tuist-cleanup` 도, 본 스킬도 빌드 자체는 수행하지 않는다.
