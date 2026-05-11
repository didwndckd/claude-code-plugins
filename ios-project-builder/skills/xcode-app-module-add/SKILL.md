---
name: xcode-app-module-add
description: 앱(`.app`) 모듈 하나를 지정한 디렉터리에 추가할 때 사용. 단일 모듈 프로젝트(루트에 직접 배치)와 멀티 모듈 프로젝트(`Projects/<Name>` 배치) 양쪽에서 호출된다. 진입점/Info.plist/Assets 배치(`init-app-module.sh` 호출), 옵션 테스트 타깃, `Project.swift` 작성, 옵션 소스/리소스 마이그레이션까지 처리한다. `Dependency.swift` 의 Internal 등록은 하지 않는다 — 앱 모듈에는 다른 모듈이 의존하지 않으므로. 외부 SPM 등록도 본 스킬에서 처리하지 않으며, 호출자가 미리 등록한 키만 `dependencies` 인자로 받는다. library/framework 모듈은 `xcode-module-add` 스킬을 사용한다. 다른 스킬이나 워크플로에서 호출할 때는 frontmatter의 `inputs` 에 정의된 인자를 전달한다.
inputs:
  required:
    - output_dir: "절대경로. 앱 모듈을 배치할 디렉터리. 단일 모듈이면 보통 ${CLAUDE_PROJECT_DIR}, 멀티 모듈이면 ${CLAUDE_PROJECT_DIR}/Projects/<AppName>. 디렉터리가 없으면 본 스킬이 생성한다."
    - name: "앱 이름. Swift identifier (letters/digits/underscore, no leading digit)."
    - entry_point: "swiftui | uikit"
    - bundle_id: "string. 5단계 Project.swift 작성 시 사용 (예: BundleID.create(\"<AppName>\") 결과 그대로)."
  optional:
    - with_tests: "boolean, 기본 true. true면 Tests/<Name>Tests.swift 생성 + 매니페스트에 테스트 타깃 추가. false 명시한 경우에만 미생성"
    - dependencies: "list of Dependency.Internal/External 키 (예: [Internal.presentation, External.rxSwift]). Project.swift 의존성에 반영. **호출자가 외부 SPM을 미리 등록해 둔 키만 사용 가능**"
    - migrate_sources_from: "절대경로. 그 경로의 모든 파일/디렉터리(숨김 포함)를 모듈 Sources/로 mv. 완료 후 원본 디렉터리가 비면 자동 삭제"
    - migrate_resources_from: "절대경로. 그 경로의 모든 파일/디렉터리(숨김 포함)를 모듈 Resources/로 mv. 완료 후 원본 디렉터리가 비면 자동 삭제"
---

# 앱 모듈 추가 스킬

앱(`.app`) 타깃 모듈 하나를 지정한 디렉터리(`output_dir`)에 추가한다. 단일/멀티 어느 구조에서도 동일하게 사용한다.

- **단일 모듈 프로젝트**: `output_dir = ${CLAUDE_PROJECT_DIR}` (프로젝트 루트에 직접 배치).
- **멀티 모듈 프로젝트**: `output_dir = ${CLAUDE_PROJECT_DIR}/Projects/<AppName>` (호출자가 정한 위치).

본 스킬은 위치를 강제하지 않는다 — 호출자가 `output_dir` 로 결정한다.

**전제 조건**: 베이스 스캐폴딩(`${CLAUDE_PROJECT_DIR}/Tuist.swift`, `Tuist/`, `xcconfigs/`)이 완료된 상태여야 한다. 충족되지 않으면 사용자에게 베이스 스캐폴딩이 먼저 필요하다고 안내한 뒤 본 스킬을 즉시 종료한다 — 베이스를 본 스킬이 직접 만들지 않는다.

아래 절차를 **위에서부터 순서대로** 따른다. 한 단계의 결과에 따라 다음 단계 진행 여부가 달라질 수 있다.

이후 절차에서 앱 모듈 디렉터리를 `<output_dir>` 로 표기한다.

## 1. 앱 정보 확인

호출자가 frontmatter `inputs` 로 값을 전달했으면 그대로 사용하고, 누락된 항목만 사용자에게 묻는다. 직접 invoke된 경우에는 모든 항목을 묻는다 (이미 사용자가 언급한 값은 다시 묻지 말 것):

- **`output_dir`** — 절대경로. 단일이면 보통 `${CLAUDE_PROJECT_DIR}`, 멀티면 `${CLAUDE_PROJECT_DIR}/Projects/<AppName>`.
- **앱 이름** — Swift identifier (예: `MyApp`).
- **진입점**: `swiftui` 또는 `uikit`.
- **번들 ID** (5단계 `Project.swift` 작성 시 필요).
- **테스트 타깃 포함 여부** — **기본 포함**(`Tests/<Name>Tests.swift` 빈 파일 + 매니페스트에 테스트 타깃 추가). `with_tests=false` 가 명시된 경우에만 미생성.
- **기존 소스 마이그레이션** (옵션) — 절대경로. 그 경로의 모든 파일/디렉터리(숨김 파일 포함)를 새 모듈 `Sources/` 로 `mv`. 완료 후 원본 디렉터리가 비면 자동 삭제.
- **기존 리소스 마이그레이션** (옵션) — 위와 동일하게 `Resources/` 로 적용.
- **의존성** (있다면) — `Dependency.Internal/External.<key>` 로 이미 등록된 키만 사용 가능. 외부 SPM이 등록 안 되어 있으면 본 스킬은 등록하지 않는다.

## 2. 진입점·리소스 배치 — `init-app-module.sh`

진입점/Info.plist/Assets를 결정적으로 배치한다:

```bash
"${CLAUDE_SKILL_DIR}/scripts/init-app-module.sh" \
  --output-dir "<output_dir>" \
  --name "<AppName>" \
  --entry-point <swiftui|uikit> \
  --templates-dir "${CLAUDE_SKILL_DIR}/templates" \
  --assets-dir "${CLAUDE_PLUGIN_ROOT}/templates/Assets.xcassets"
```

`${CLAUDE_SKILL_DIR}` 는 본 스킬(`xcode-app-module-add`)의 디렉터리(= SKILL.md가 있는 곳). 진입점 템플릿(`swiftui/`, `uikit/`)과 `init-app-module.sh` 는 모두 본 스킬 로컬에 있다. `--assets-dir` 만 plugin root의 공유 `Assets.xcassets/` 를 가리키며, `xcode-module-add` 의 framework 분기에서도 같은 plugin root 경로로 참조한다.

생성되는 구조:
- `<output_dir>/Sources/Entry/` — 진입점 소스 (SwiftUI는 `<AppName>App.swift`, UIKit는 `AppDelegate.swift` + `SceneDelegate.swift`).
- `<output_dir>/Info.plist` — 모듈 루트.
- `<output_dir>/Resources/Assets.xcassets/`.

## 3. 테스트 타깃 디렉터리 (기본 생성)

기본적으로 테스트 타깃을 만든다. 빈 Swift 파일 하나만 생성한다 (테스트 코드는 사용자가 작성하거나 이후 작업에서 채움):

```bash
mkdir -p "<output_dir>/Tests"
: > "<output_dir>/Tests/<AppName>Tests.swift"
```

`with_tests=false` 가 명시된 경우에만 본 단계를 건너뛴다.

## 4. 기존 소스/리소스 마이그레이션 (옵션)

`migrate_sources_from` 또는 `migrate_resources_from` 이 주어졌으면, 그 경로 안의 모든 파일/디렉터리(숨김 파일 포함)를 모듈의 해당 디렉터리로 `mv` 한다. **완료 후 원본 디렉터리가 비면 자동 삭제** 한다 (rmdir — 비어있지 않으면 실패하고 그대로 둠).

```bash
shopt -s dotglob nullglob
mv "<migrate_sources_from>"/* "<output_dir>/Sources/"
shopt -u dotglob nullglob
rmdir "<migrate_sources_from>" 2>/dev/null || true
```

리소스 마이그레이션도 동일한 패턴으로 `Resources/` 에 적용한다.

앱 모듈은 2단계에서 `Sources/Entry/` 가 채워지므로 placeholder 처리는 필요 없다.

## 5. Project.swift 작성

`<output_dir>/Project.swift` 를 작성한다. `${CLAUDE_PROJECT_DIR}/Tuist/ProjectDescriptionHelpers/` 의 헬퍼를 다음과 같이 활용한다:

- **product**: `.app`
- **번들 ID**: `BundleID.create("<AppName>")` (인자로 받은 `bundle_id` 와 일치하는지 확인. 다르면 사용자에게 어느 쪽을 쓸지 한 번 확인)
- **settings**: `ProjectSetting.app`
- **sources**: `Sources/**` (`Sources/Entry/**` 까지 포함됨)
- **resources**: `Resources/**` + `infoPlist: .file(path: "Info.plist")`
- **의존성**: `Dependency.Internal.<module>` / `Dependency.External.<lib>` 만 사용. `Project.swift` 안에서 `.project(...)` / `.external(...)` 을 직접 호출 **금지** — 모듈/외부 의존성 표현이 `Dependency.swift` 한 곳에 모이도록 한다. 단일 모듈 일회성 generate 흐름(`xcode-project-create-single`)에서 호출된 경우 호출자가 빈 배열을 넘기므로 그대로 비워둔다.
- **테스트 타깃**: 3단계에서 디렉터리를 만든 경우(`with_tests=false` 가 아닌 기본 흐름) 같은 `targets` 배열에 함께 추가.

전체 매니페스트 골격(메인 + 테스트):

```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "<AppName>",
    settings: ProjectSetting.app,
    targets: [
        .target(
            name: "<AppName>",
            destinations: .iOS,
            product: .app,
            bundleId: BundleID.create("<AppName>"), // 인자 bundle_id 와 다르면 사용자 확인 후 그 값 문자열로 대체
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                // Dependency.Internal.<module>, Dependency.External.<lib> 만. 단일 모듈 generate 흐름은 빈 배열
            ]
        ),
        // with_tests=false 면 아래 타깃 제거
        .target(
            name: "<AppName>Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: BundleID.create("<AppName>Tests"),
            sources: ["Tests/**"],
            dependencies: [.target(name: "<AppName>")]
        ),
    ]
)
```

작성 후 사용자에게 매니페스트를 보여주고 확인받는다.

## 6. 후처리 — `Dependency.swift` 비등록

앱 모듈은 `Dependency.Internal` 에 **등록하지 않는다**. 다른 모듈이 앱에 의존하는 경우가 없으므로. 본 스킬은 `Dependency.swift` 를 편집하지 않는다.
