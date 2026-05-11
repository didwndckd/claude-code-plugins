---
name: tuist-base-setup
description: Tuist 기반 iOS 프로젝트의 공통 초기 셋업을 처리. mise 설치 확인, Tuist 버전 결정 및 mise로 고정, init-tuist-base.sh 호출(Tuist 템플릿/xcconfigs/Tuist.swift 배치), init-gitignore.sh 호출(.gitignore 생성)을 한 흐름으로 묶는다. mise가 없으면 사용자에게 직접 설치를 안내하고 스킬을 즉시 종료한다. 멀티 모듈/단일 모듈 프로젝트 둘 다에서 호출되는 진입 단계 스킬. xcode-project-create-multi 및 xcode-project-create-single 스킬이 이 스킬을 호출해 베이스 셋업을 위임한다. 다른 스킬에서 호출할 때는 frontmatter `inputs`의 `mode`를 전달한다.
inputs:
  required:
    - mode: "multi | single. .gitignore의 *.xcodeproj/*.xcworkspace 무시 여부에만 영향 (multi=무시, single=Xcode 공유). 베이스 스캐폴딩 자체는 동일하다."
  optional:
    - tuist_version: "예: 4.55.6. 미지정 시 사용자에게 묻고, '최신' 답변이면 최신 안정 태그를 자동 조회한다."
---

# Tuist 베이스 셋업 스킬

Tuist 프로젝트의 공통 초기 셋업을 처리한다. 멀티/단일 모듈 어느 쪽이든 베이스 스캐폴딩(`Tuist/`, `xcconfigs/`, `Tuist.swift`)은 동일하다. 차이는 `.gitignore` 정책 한 가지뿐이며, frontmatter `mode` 입력으로 분기된다.

호출자(상위 스킬)가 `mode`를 전달하지 않으면 사용자에게 직접 묻는다.

버전 매니저는 **mise만 지원**한다. mise가 없으면 사용자에게 직접 설치를 안내하고 본 스킬을 즉시 종료한다 (asdf/Homebrew 등 다른 경로는 다루지 않는다).

아래 절차를 **위에서부터 끝까지 순서대로 모두 실행**한다. 단계 누락 금지 — 특히 2단계(버전 고정)는 종종 빠뜨려지는데, 빠지면 팀/CI 간 Tuist 버전 차이로 매니페스트가 깨진다.

## 1. mise 유무 + 기존 Tuist 설치 상태 한 번에 확인

```bash
mise ls tuist
```

이 한 줄로 두 가지가 동시에 잡힌다:
- **mise 미설치**: 명령 자체가 실패(`command not found`, non-zero exit) → 사용자에게 다음을 안내하고 **본 스킬을 즉시 종료** (이후 단계 진행 금지):
  - mise를 설치하거나(권장: `curl https://mise.run | sh`), 그게 어렵다면 Tuist를 직접 설치(예: `brew install tuist`) 후 본 스킬을 다시 호출
  - mise/Tuist를 임의로 설치하지 말 것.
- **mise 설치됨, exit 0**:
  - 출력이 비어있으면 → 아직 Tuist가 mise를 통해 깔려있지 않음. 다음 단계의 `mise use`가 자동 설치한다.
  - 출력에 `tuist  <버전>` 줄이 하나 이상 있으면 → 이미 설치된 버전들. 다음 단계 버전 결정 시 후보로 활용한다 (재설치 없이 `mise use tuist@<기존버전>`만 해도 핀 고정 끝).

## 2. Tuist 버전 결정 및 고정

이 단계는 **반드시 끝까지 실행**한다. 결정만 하고 고정 명령을 누락하지 않는다.

### 2-1. 사용할 버전 결정

우선순위:
1. `tuist_version` 인자가 주어졌으면 그 값 사용.
2. 아니면 사용자에게 묻는다. 1단계에서 기존 설치 버전이 보였다면 그 목록도 함께 제시 (재사용 가능함을 알 수 있게). 특별한 이유가 없으면 **최신 안정 버전 추천**.

사용자가 "최신"이라고 답하거나 버전을 지정하지 않은 경우에만 다음 명령으로 최신 안정 버전을 조회한다:

```bash
mise ls-remote tuist | tail -1
```

> ⚠️ `mise latest tuist` 또는 `https://github.com/tuist/tuist/releases/latest` redirect는 사용 금지. Tuist 레포는 모노레포라 `server@x.y.z` 같은 다른 컴포넌트 태그가 latest로 잡혀 **Tuist CLI가 아닌 Tuist Server 버전이 반환**된다. mise asdf plugin은 CLI 태그만 인덱싱하므로 `ls-remote`가 안전하다.

이후 결정된 버전을 `<TUIST_VERSION>` 으로 표기한다 (예: `4.55.6`).

### 2-2. mise로 고정

```bash
cd "${CLAUDE_PROJECT_DIR}" && mise use tuist@<TUIST_VERSION>
```

이 명령이 `${CLAUDE_PROJECT_DIR}/.mise.toml` (또는 기존 `.tool-versions`)에 항목을 추가/갱신하고, 필요 시 해당 버전을 자동 설치한다.

### 2-3. 검증

작성된 파일(`.mise.toml` 또는 `.tool-versions`)에 `tuist <TUIST_VERSION>` 항목이 정확히 들어갔는지 한 번 읽어 확인하고, 실제 호출이 되는지도 검증:

```bash
cd "${CLAUDE_PROJECT_DIR}" && mise exec -- tuist version
```

출력이 `<TUIST_VERSION>`과 일치해야 한다. 사용자에게 결과를 한 줄로 보고 (예: "mise로 Tuist 4.55.6 고정, .mise.toml에 기록 및 호출 확인 완료").

## 3. 베이스 스캐폴딩

```bash
"${CLAUDE_SKILL_DIR}/scripts/init-tuist-base.sh" \
  --project-root "${CLAUDE_PROJECT_DIR}" \
  --tuist-template "${CLAUDE_SKILL_DIR}/templates/Tuist" \
  --xcconfigs-template "${CLAUDE_SKILL_DIR}/templates/xcconfigs" \
  --tuist-config-file "${CLAUDE_SKILL_DIR}/templates/Tuist.swift"
```

이 명령이 수행하는 범위:
- `templates/Tuist/*` (`Package.swift`, `ProjectDescriptionHelpers/`)를 `${CLAUDE_PROJECT_DIR}/Tuist/`로 머지 복사 (같은 이름 파일은 덮어쓰기, 기존 디렉터리는 보존)
- `templates/xcconfigs/*`를 `${CLAUDE_PROJECT_DIR}/xcconfigs/`로 머지 복사
- `templates/Tuist.swift`를 `${CLAUDE_PROJECT_DIR}/Tuist.swift`로 복사 (덮어쓰기)

`Projects/` 디렉터리는 본 스크립트가 만들지 않는다. 멀티 모듈은 `xcode-module-add` 스킬이 모듈 추가 시 `mkdir -p`로 자연스럽게 생성한다.

## 4. .gitignore 생성

```bash
"${CLAUDE_SKILL_DIR}/scripts/init-gitignore.sh" \
  --project-root "${CLAUDE_PROJECT_DIR}"<MODE_FLAG>
```

`<MODE_FLAG>`:
- `mode=multi` → ` --multi-module` (`*.xcodeproj` / `*.xcworkspace` 무시 — 매번 `tuist generate`로 재생성)
- `mode=single` → 빈 문자열 (위 두 항목을 무시하지 않음 — 1회성 generate 후 Xcode가 직접 관리)

이미 `.gitignore`가 있으면 보존되고 건너뛴다 (사용자 추가 항목 손실 방지).
