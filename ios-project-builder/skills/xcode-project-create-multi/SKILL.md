---
name: xcode-project-create-multi
description: 멀티 모듈 iOS Xcode 프로젝트를 Tuist로 새로 시작할 때 사용. 베이스 셋업(tuist-base-setup 위임), Workspace.swift 정의, 외부 SPM 의존성 셋업, 모듈 의존성 그래프 결정, 모듈별 구성(앱 모듈은 xcode-app-module-add, library/framework 모듈은 xcode-module-add 위임), tuist generate까지 처리한다. 단일 모듈 프로젝트는 xcode-project-create-single 스킬을 사용한다.
---

# 멀티 모듈 Xcode 프로젝트 생성 스킬

Tuist 기반 **멀티 모듈** iOS 프로젝트의 초기 구성을 처리한다. 사용자가 단일/멀티 의도를 명시하지 않은 채 호출했다면, 먼저 멀티 모듈이 맞는지 확인한다. 단일 모듈이면 본 스킬을 종료하고 `xcode-project-create-single` 사용을 안내한다.

본 스킬은 다음 하위 스킬에 위임한다:
- 베이스 셋업(Tuist 설치 확인/버전 고정/스캐폴딩/.gitignore) → `tuist-base-setup`
- 앱(`.app`) 모듈 구성 → `xcode-app-module-add`
- library/framework 모듈 구성 → `xcode-module-add`

본 스킬은 그 위에서 워크스페이스 정의 / 외부 의존성 / 모듈 구성 순서 / 검증을 책임진다.

아래 절차를 **위에서부터 순서대로** 따른다. 한 단계의 결과에 따라 다음 단계 진행 여부가 달라질 수 있다.

## 1. 베이스 셋업 — `tuist-base-setup` 위임

`tuist-base-setup` 스킬을 호출한다. frontmatter `inputs`에 다음을 전달:

| 인자 | 값 |
|---|---|
| `mode` | `multi` |
| `tuist_version` | (옵션) 사용자가 미리 지정했으면 그 값. 없으면 `tuist-base-setup`이 사용자에게 직접 묻는다. |

이 스킬이 다음을 처리한다 (반복하지 않는다):
- Tuist 설치 확인 (미설치 시 본 흐름 즉시 종료)
- Tuist 버전 결정 + mise/asdf로 고정 (`.mise.toml` 또는 `.tool-versions`)
- 베이스 스캐폴딩 (`Tuist/`, `xcconfigs/`, `Tuist.swift`)
- `.gitignore` 생성 — `mode=multi` 이므로 `*.xcodeproj` / `*.xcworkspace` 무시 포함

## 2. Workspace 정의 — `Workspace.swift` 생성

프로젝트 루트에 `Workspace.swift`를 만들어 멀티 모듈을 하나의 워크스페이스로 묶는다. 이 파일이 없으면 `tuist generate`가 워크스페이스를 자동 추론하는데, 다중 모듈 의존 관계가 복잡해지면 의도치 않은 묶음이 생길 수 있어 명시적으로 정의해 둔다.

사용자에게 워크스페이스 이름을 묻는다 (보통 앱 이름 또는 프로젝트 코드네임). 답을 받으면 템플릿에서 placeholder를 치환해 배치한다:

```bash
sed "s/__WORKSPACE_NAME__/<WorkspaceName>/g" \
  "${CLAUDE_SKILL_DIR}/templates/Workspace.swift" \
  > "${CLAUDE_PROJECT_DIR}/Workspace.swift"
```

생성된 파일은 `Projects/**` glob으로 모든 모듈의 `Project.swift`를 자동 포함한다. 5단계에서 모듈을 추가할 때마다 이 워크스페이스에 자동 합류되므로 추가 편집이 필요 없다.

`additionalFiles`나 `schemes` 같은 부수 항목은 의도적으로 빼두었다. 필요해지면 사용자가 직접 추가한다.

## 3. 외부 SPM 의존성 셋업

모듈 구성을 시작하기 전에 사용 예정인 모든 외부 SPM 패키지를 **이 단계에서 일괄 등록**한다. 5단계의 모듈 구성은 `xcode-module-add` 스킬에 위임되는데, 그 스킬은 외부 의존성을 등록하지 않고 **이미 등록된 `Dependency.External.<lib>` 키만 참조**한다. 따라서 빠짐없이 여기서 정리해야 한다.

사용자에게 사용할 외부 SPM 패키지 목록을 묻는다 (예: RxSwift, SnapKit, Kingfisher, Moya). 5단계 진행 중에 누락이 발견되면 본 단계로 돌아와 추가한다.

각 패키지마다 다음 두 가지를 수행한다:

1. **프로젝트 루트의 `Package.swift`에 SPM 선언 추가** — `tuist install` 시 이 파일이 패키지 다운로드의 근거가 된다:
   ```swift
   dependencies: [
       .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.0.0"),
       // ...
   ]
   ```

2. **`ProjectDescriptionHelpers/Dependency.swift`의 `External` enum에 `static let` 등록**:
   ```swift
   public static let rxSwift: TargetDependency = .external(name: "RxSwift")
   ```

`Dependency.External`에 미리 박혀있는 예시 항목(`rxSwift`, `snapKit`, `kingfisher` 등)은 템플릿 샘플이다. 사용자 프로젝트와 맞지 않으면 정리(삭제 또는 교체)한다.

`tuist install`은 6단계에서 일괄 실행 — 이 단계에서는 **선언만** 한다.

`Dependency.External` 외에 **모듈 추가 단계에서 외부 SPM을 새로 도입하지 않는다**. 새로 필요해지면 이 3단계로 돌아와 등록한 뒤 모듈 구성을 이어간다.

## 4. 모듈 구성 계획 — 의존성 그래프 + 작업 순서

사용자에게 만들 모듈 목록과 모듈 간 의존성 관계를 묻는다. 앱 모듈도 이 목록에 포함시킨다. 예:
- `App` (앱 타깃) — `Presentation`, `Data` 에 의존
- `Presentation` — `Domain` 에 의존
- `Data` — `Domain` 에 의존
- `Domain` — 의존성 없음

받은 정보를 바탕으로 **의존성이 적은 모듈부터 만드는 작업 순서**(위상 정렬)를 결정한다. 위 예시면: `Domain` → `Data` → `Presentation` → `App`. 의존성이 같은 레벨인 모듈은 어느 순서로 진행해도 무방.

순서가 결정되면 사용자에게 한 번 보여주고 확인받는다.

이 순서가 중요한 이유:
- 모듈 A가 모듈 B에 의존하면, A의 `Project.swift` 작성 시점에 `Dependency.Internal.b`가 이미 등록되어 있어야 함.
- 따라서 의존되는 쪽(B)이 먼저 만들어지고 등록되어야 함.

## 5. 모듈 구성 (반복) — 앱은 `xcode-app-module-add`, 그 외는 `xcode-module-add` 위임

4단계에서 정한 순서대로 각 모듈을 처리한다. 모듈 타입에 따라 호출하는 스킬이 갈린다.

### 5-A. 앱(`.app`) 모듈 — `xcode-app-module-add` 위임

| 인자 | 값 |
|---|---|
| `output_dir` | `${CLAUDE_PROJECT_DIR}/Projects/<AppName>` |
| `name` | 앱 이름 |
| `entry_point` | `swiftui` 또는 `uikit` |
| `bundle_id` | 예: `BundleID.create("<AppName>")` 결과 그대로 |
| `with_tests` | 기본 `true`. 미생성을 원할 때만 `false` 명시 |
| `migrate_sources_from` | 기존 소스가 있으면 절대경로 |
| `migrate_resources_from` | 기존 리소스가 있으면 절대경로 |
| `dependencies` | 앱이 의존하는 `Dependency.Internal/External.<key>` 키 배열. **`External` 은 3단계에서 등록된 키만 사용 가능** |

`xcode-app-module-add` 가 다음을 처리한다:
- `init-app-module.sh` 호출로 진입점/Info.plist/Assets 배치
- (기본) 테스트 타깃 디렉터리/파일 + 매니페스트 등록
- 옵션 소스/리소스 마이그레이션 (`mv` + 원본 빈 폴더 자동 삭제)
- `Project.swift` 작성 (`.app`, `ProjectSetting.app`, infoPlist, dependencies)
- `Dependency.swift` 는 편집하지 않음 (앱 모듈은 등록 대상 아님)

### 5-B. library/framework 모듈 — `xcode-module-add` 위임

| 인자 | 값 |
|---|---|
| `module_name` | 모듈 이름. 모듈 디렉터리는 `${CLAUDE_PROJECT_DIR}/Projects/<module_name>` 으로 자동 배치됨 (`xcode-module-add` 가 위치 고정). |
| `module_type` | `framework` / `staticFramework` / `staticLibrary` / `dynamicLibrary`. 사용자에게 타입을 묻고 다음을 권장값으로 제시한다: **UI 리소스(xib/storyboard/asset/폰트 등)를 포함하는 모듈(예: `Presentation`, `DesignSystem`)은 `staticFramework`**, **그 외 일반 로직 모듈은 `staticLibrary`**. 사용자가 다른 타입을 명시하면 그 값을 사용. |
| `with_tests` | 기본 `true`. 미생성을 원할 때만 `false` 명시 |
| `migrate_sources_from` | 기존 소스가 있으면 절대경로 |
| `migrate_resources_from` | 기존 리소스가 있으면 절대경로 |
| `dependencies` | 이 모듈이 의존하는 `Dependency.Internal/External.<key>` 키 배열. **`External` 은 3단계에서 등록된 키만 사용 가능** |

`xcode-module-add` 가 다음을 처리한다:
- 디렉터리 생성 (framework/staticFramework 는 `Resources/Assets.xcassets/` 자동 배치, 라이브러리는 `Sources/` 만)
- (기본) 테스트 타깃 디렉터리/파일 + 매니페스트 등록
- 옵션 소스/리소스 마이그레이션 (`mv` + 원본 빈 폴더 자동 삭제)
- `Sources/` 가 비어 있으면 `<ModuleName>.swift` placeholder 1개 생성
- `Project.swift` 작성, `Dependency.swift` 의 `Internal` enum 에 등록

### 공통 사항

외부 SPM 의존성 신규 등록은 본 스킬의 3단계에서만 처리한다 — 두 add 스킬 모두 외부 의존성을 등록하지 않는다. 5단계 진행 중 누락이 발견되면 3단계로 돌아가 등록 후 이어서 진행.

각 모듈 구성이 끝나면 다음 모듈로 진행한다. 위상 정렬 순서를 따랐기에 `Project.swift` 에서 다른 모듈을 `Dependency.Internal.x` 로 참조할 때 항상 등록이 선행되어 있다.

## 6. 프로젝트 생성 및 검증

```bash
# 외부 SPM 의존성이 있으면 (3단계에서 등록한 경우)
tuist install

# Xcode 프로젝트 생성
tuist generate
```

생성된 `.xcworkspace` 또는 `.xcodeproj`를 사용자가 Xcode에서 열어 빌드 확인. 에러가 있으면 본문 단계로 돌아가 매니페스트/소스 배치를 보완한다.
