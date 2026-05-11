---
name: xcode-module-add
description: Tuist **멀티 모듈** 프로젝트에 library/framework 모듈을 추가할 때 사용. 지원 타입은 `framework` / `staticFramework` / `staticLibrary` / `dynamicLibrary`. 모듈은 `${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>` 경로에 고정 생성된다. 디렉터리·리소스 배치, Project.swift 매니페스트 작성, Dependency.swift의 Internal enum 등록까지 처리한다. 테스트 타깃은 기본 생성하며, 기존 소스/리소스 마이그레이션을 옵션으로 지원한다. 외부 SPM 의존성 등록은 본 스킬에서 처리하지 않으며, 호출자가 미리 등록한 키만 참조한다. **앱(`.app`) 모듈은 본 스킬이 아니라 `xcode-app-module-add` 스킬을 사용한다**. 단일 모듈 프로젝트의 단일 앱은 `xcode-project-create-single`이 `xcode-app-module-add`를 호출해 처리한다. 베이스 스캐폴딩(Tuist/, xcconfigs/, Tuist.swift)이 이미 완료된 상태에서 호출되는 것을 전제로 한다. `Projects/` 디렉터리는 본 스킬이 필요 시 자동 생성한다. 다른 스킬이나 워크플로에서 호출할 때는 frontmatter의 `inputs`에 정의된 인자를 전달한다.
inputs:
  required:
    - module_name: "Swift identifier (예: Domain, Presentation). 모듈 디렉터리는 ${CLAUDE_PROJECT_DIR}/Projects/<module_name> 으로 고정 생성된다."
    - module_type: "framework | staticFramework | staticLibrary | dynamicLibrary"
  optional:
    - with_tests: "boolean, 기본 true. true면 Tests/<Name>Tests.swift 생성 + 매니페스트에 테스트 타깃 추가. false를 명시한 경우에만 미생성"
    - migrate_sources_from: "절대경로. 그 경로의 모든 파일/디렉터리(숨김 포함)를 모듈 Sources/로 mv. 완료 후 원본 디렉터리가 비면 자동 삭제"
    - migrate_resources_from: "절대경로. 그 경로의 모든 파일/디렉터리(숨김 포함)를 모듈 Resources/로 mv. 완료 후 원본 디렉터리가 비면 자동 삭제"
    - dependencies: "list of Dependency.Internal/External 키 (예: [Internal.domain, External.rxSwift]). Project.swift 의존성에 반영"
---

# Xcode 모듈 추가 스킬 (멀티 모듈 / library·framework 전용)

Tuist 기반 **멀티 모듈** 프로젝트에 library/framework 모듈을 추가한다. 지원 타입: `framework` / `staticFramework` / `staticLibrary` / `dynamicLibrary`.

**앱(`.app`) 모듈은 본 스킬이 처리하지 않는다** — `xcode-app-module-add` 스킬을 사용한다. 단일 모듈 프로젝트의 단일 앱은 `xcode-project-create-single` 이 `xcode-app-module-add` 를 호출해 처리한다.

**모듈 위치**: 항상 `${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>` 으로 고정. 호출자가 위치를 바꿀 수 없다.

**전제 조건**: 베이스 스캐폴딩(`${CLAUDE_PROJECT_DIR}/Tuist.swift`, `Tuist/`, `xcconfigs/`)이 완료된 상태여야 한다. 충족되지 않으면 사용자에게 **베이스 스캐폴딩이 먼저 필요하다**고 안내한 뒤 본 스킬을 즉시 종료한다 — 베이스를 본 스킬이 직접 만들지 않는다. `Projects/` 디렉터리가 없으면 본 스킬의 2단계 `mkdir -p` 가 자동으로 만든다.

아래 절차를 **위에서부터 순서대로** 따른다. 한 단계의 결과에 따라 다음 단계 진행 여부가 달라질 수 있다.

## 1. 모듈 정보 확인

호출자가 frontmatter `inputs`로 값을 전달했으면 그대로 사용하고, 누락된 항목만 사용자에게 묻는다. 직접 invoke된 경우(인자 없음)에는 모든 항목을 묻는다 (이미 사용자가 언급한 값은 다시 묻지 말 것):
- **모듈 이름** — Swift identifier (예: `Domain`, `Presentation`).
- **모듈 타입** — 다음 중 하나 (앱 모듈은 본 스킬에서 받지 않는다 — `xcode-app-module-add` 사용):
  - `framework`
  - `staticFramework`
  - `staticLibrary`
  - `dynamicLibrary`
- **테스트 타깃 포함 여부** — **기본 포함**(`Tests/<ModuleName>Tests.swift` 빈 파일 + 매니페스트에 테스트 타깃 추가). 호출자가 `with_tests=false`를 명시했거나, 사용자가 직접 invoke 흐름에서 "테스트 불필요"를 명확히 한 경우에만 미생성
- **기존 소스 마이그레이션** (옵션) — 절대경로. 그 경로의 모든 파일/디렉터리(숨김 파일 포함)를 새 모듈 `Sources/`로 `mv`. 완료 후 원본 디렉터리가 비면 자동 삭제.
- **기존 리소스 마이그레이션** (옵션) — 위와 동일하게 `Resources/`로 적용.
- **의존성** (있다면) — 다른 내부 모듈, 외부 SPM 패키지. **`Dependency.Internal/External.<key>` 로 이미 등록된 키만 사용 가능**. 외부 SPM이 등록 안 되어 있으면 본 스킬은 등록하지 않는다 — 호출자(상위 스킬) 또는 사용자가 미리 `Package.swift` 와 `Dependency.External` 에 등록해야 한다.

호출 시 `module_type=app` 가 들어왔다면 본 스킬은 **즉시 종료** 하고 사용자/호출자에게 `xcode-app-module-add` 를 사용하라고 안내한다.

이후 절차에서 모듈 디렉터리를 `${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>` 으로 표기한다.

## 2. 모듈 디렉터리 생성 / 리소스 배치

### `framework` / `staticFramework` 인 경우

`Sources/`와 `Resources/Assets.xcassets/`를 함께 만든다 (프레임워크는 리소스 번들이 가능하고, Assets는 모듈별로 자주 추가되므로 기본 배치):

```bash
mkdir -p "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Sources"
mkdir -p "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Resources"
cp -R "${CLAUDE_PLUGIN_ROOT}/templates/Assets.xcassets" \
      "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Resources/"
```

### `staticLibrary` / `dynamicLibrary` 인 경우

라이브러리 산출물은 리소스 번들을 직접 가질 수 없으므로 `Sources/`만 생성한다:

```bash
mkdir -p "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Sources"
```

리소스가 별도로 필요하면 사용자에게 별도 리소스 번들 모듈을 만들지 묻고, 본 스킬은 라이브러리 모듈에 직접 `Resources/`를 만들지 않는다.

`mkdir -p` 가 부모인 `Projects/`도 같이 생성하므로 별도 처리 불필요.

## 3. 테스트 타깃 디렉터리 (기본 생성)

기본적으로 테스트 타깃을 만든다. 빈 Swift 파일 하나만 생성한다 (테스트 코드는 사용자가 작성하거나 이후 작업에서 채움):

```bash
mkdir -p "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Tests"
: > "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Tests/<ModuleName>Tests.swift"
```

`with_tests=false`가 명시된 경우에만 본 단계를 건너뛴다.

## 4. 기존 소스/리소스 마이그레이션 (옵션)

`migrate_sources_from` 또는 `migrate_resources_from` 이 주어졌으면, 그 경로 안의 모든 파일/디렉터리(숨김 파일 포함)를 모듈의 해당 디렉터리로 `mv` 한다. **완료 후 원본 디렉터리가 비면 자동 삭제** 한다 (rmdir — 비어있지 않으면 실패하고 그대로 둠).

```bash
shopt -s dotglob nullglob
mv "<migrate_sources_from>"/* "${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Sources/"
shopt -u dotglob nullglob
rmdir "<migrate_sources_from>" 2>/dev/null || true
```

리소스 마이그레이션도 동일한 패턴으로 `Resources/` 에 적용한다.

## 5. 빈 모듈 placeholder

마이그레이션이 끝난 시점에 `Projects/<ModuleName>/Sources/` 가 비어 있으면(앱 모듈은 `Sources/Entry/` 가 채워지므로 해당 없음), `Sources/<ModuleName>.swift` 한 개를 빈 파일로 생성한다. Tuist `sources: ["Sources/**"]` 가 빈 디렉터리에서 빌드 실패를 내는 케이스를 막고, 매니페스트가 즉시 빌드 가능한 상태로 끝나게 하기 위함이다.

```bash
SRC_DIR="${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Sources"
shopt -s dotglob nullglob
entries=("$SRC_DIR"/*)
shopt -u dotglob nullglob
if [[ ${#entries[@]} -eq 0 ]]; then
  : > "${SRC_DIR}/<ModuleName>.swift"
fi
```

이미 마이그레이션으로 파일이 들어왔거나, 사용자가 직접 채울 예정이라고 명시한 경우에는 건너뛴다.

## 6. Project.swift 작성

`${CLAUDE_PROJECT_DIR}/Projects/<ModuleName>/Project.swift`를 작성한다. `${CLAUDE_PROJECT_DIR}/Tuist/ProjectDescriptionHelpers/`의 헬퍼를 다음과 같이 활용한다:

- **product**: 모듈 타입 → Tuist `Product` 매핑
  - `framework` → `.framework`
  - `staticFramework` → `.staticFramework`
  - `staticLibrary` → `.staticLibrary`
  - `dynamicLibrary` → `.dynamicLibrary`
- **번들 ID**: `BundleID.create("<ModuleName>")`
- **settings**: `ProjectSetting.base`
- **sources**: `Sources/**`
- **resources**: 있으면 `Resources/**`. `framework` / `staticFramework` 는 2단계에서 항상 `Resources/Assets.xcassets/` 가 배치되므로 `Resources/**` 를 기본 포함
- **의존성**: `Dependency.Internal.<module>` / `Dependency.External.<lib>` 만 사용. `Project.swift` 안에서 `.project(...)` / `.external(...)` 을 직접 호출 **금지** — 모듈/외부 의존성 표현이 `Dependency.swift` 한 곳에 모이도록 한다.
- **테스트 타깃**: 3단계에서 디렉터리를 만든 경우(`with_tests=false` 가 아닌 기본 흐름) 같은 `targets` 배열에 함께 추가.

전체 매니페스트 골격(메인 + 테스트). 분기 처리는 주석 표시를 따른다:

```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "<ModuleName>",
    settings: ProjectSetting.base,
    targets: [
        .target(
            name: "<ModuleName>",
            destinations: .iOS,
            product: <.framework | .staticFramework | .staticLibrary | .dynamicLibrary>,
            bundleId: BundleID.create("<ModuleName>"),
            sources: ["Sources/**"],
            resources: ["Resources/**"], // framework / staticFramework 분기일 때만. staticLibrary / dynamicLibrary 분기는 이 줄 제거
            dependencies: [
                // Dependency.Internal.<module>, Dependency.External.<lib> 만
            ]
        ),
        // with_tests=false 면 아래 타깃 제거
        .target(
            name: "<ModuleName>Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: BundleID.create("<ModuleName>Tests"),
            sources: ["Tests/**"],
            dependencies: [.target(name: "<ModuleName>")]
        ),
    ]
)
```

작성 후 사용자에게 매니페스트를 보여주고 확인받는다.

## 7. Dependency.swift 에 모듈 등록

`${CLAUDE_PROJECT_DIR}/Tuist/ProjectDescriptionHelpers/Dependency.swift` 의 `Internal` enum에 `static let` 추가:

```swift
public static let <moduleName>: TargetDependency =
    .project(target: "<ModuleName>", path: .relativeToRoot("Projects/<ModuleName>"))
```

## 8. 의존성 반영 (필요 시)

이 모듈을 다른 모듈/앱에서 사용할 예정이면, 그쪽 `Project.swift`의 `dependencies`에도 `Dependency.Internal.<moduleName>` 을 추가한다.
