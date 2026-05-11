---
name: ios-clean-architecture-build
description: iOS 클린 아키텍처 초기 셋업. Presentation/Domain/Data 폴더 생성, `CLAUDE.md ## 아키텍처 구조` 섹션 작성(레이어 루트 명시 포함), `.claude/rules/`에 도메인/데이터 룰 배치. 내부적으로 `ios-network-base-build`(네트워크 베이스)와 `ios-mvvm-architecture-build`(Presentation MVVM 셋업 + presentation 룰)를 호출. 기술 스택 결정(`ios-tech-stack`) 이후, 도메인별 코드 작성 전에 호출.
---

# 클린 아키텍처 구조 빌더 (iOS)

## 사전 조건

## 작업 절차

### 1. 폴더 생성 위치 결정 + 폴더 생성

`AskUserQuestion`으로 생성 루트를 user에게 묻는다. 기본 추천은 프로젝트 루트(`.`). user가 변경하면 그 값 사용.

결정된 경로를 인자로 `${CLAUDE_SKILL_DIR}/scripts/create-folders.sh <루트>` 호출.

### 2. CLAUDE.md `## 아키텍처 구조` 섹션 작성

`CLAUDE.md`(프로젝트 루트)에 `## 아키텍처 구조` 섹션을 작성/갱신한다. 파일이 없으면 새로 만들고, 있으면 동일 헤더 섹션만 교체/추가하고 다른 섹션은 보존.

섹션 본문은 다음을 포함한다:

- 첫 줄에 "이 프로젝트는 **클린 아키텍처**를 따른다." 명시.
- 레이어 루트 (1단계 `<루트>` 기준 — 후속 빌더가 매칭에 사용):
  - Presentation: `<루트>/Presentation`
  - Domain: `<루트>/Domain`
  - Data: `<루트>/Data`
- 아래 폴더 트리:

```
Presentation/
Domain/
└── <도메인명>/
    ├── Model/
    ├── Repository/
    └── UseCase/   # Optional
Data/
├── Network/
└── <도메인명>/
    ├── Repository/
    └── Endpoint/
```

- 의존 방향: `Presentation → Domain ← Data`

### 3. 네트워크 베이스 빌더 호출

`Skill` 도구로 `ios-network-base-build` 스킬을 호출한다.

인자:
- `path`: 1단계에서 결정된 루트 + `/Data/Network`
- `network`: 기술 스택 결정 결과(`CLAUDE.md`의 `## 기술 스택` 또는 동등 섹션)에서 가져온 네트워크 라이브러리. 값이 없으면 `AskUserQuestion`으로 user에게 묻는다.
- `async`: 같은 출처에서 가져온 비동기 패턴. 값이 없으면 `AskUserQuestion`으로 user에게 묻는다.

서브에이전트 격리 컨텍스트에서 실행되므로 호출 결과(stdout 요약)만 받아서 다음 단계로 진행한다.

### 4. 도메인 룰 작성

`${CLAUDE_SKILL_DIR}/templates/domain-rule.md`를 `.claude/rules/domain.md`로 그대로 복사한다.

```
mkdir -p .claude/rules
cp ${CLAUDE_SKILL_DIR}/templates/domain-rule.md .claude/rules/domain.md
```

### 5. 데이터 룰 작성

`${CLAUDE_SKILL_DIR}/templates/data-rule.md`를 `.claude/rules/data.md`로 그대로 복사한다.

```
mkdir -p .claude/rules
cp ${CLAUDE_SKILL_DIR}/templates/data-rule.md .claude/rules/data.md
```

### 6. MVVM 빌더 호출

`Skill` 도구로 `ios-mvvm-architecture-build`를 호출해 Presentation 부분의 ViewModel 베이스 파일 + `.claude/rules/presentation.md` 작성을 위임한다. MVVM 빌더는 2단계에서 작성한 `## 아키텍처 구조`의 Presentation 루트 명시를 보고 매칭 노드에 트리를 끼워넣는다.

인자:
- `root`: 1단계 루트 + `/Presentation`
- `ui`: `## 기술 스택`의 UI 값. 없으면 user에게 묻는다.
- `async`: `## 기술 스택`의 비동기 값. 없으면 user에게 묻는다.
- `reactive`: `## 기술 스택`의 반응형 값. 없으면 user에게 묻는다.
- `network`: `사용 안 함` (네트워크 베이스는 3단계에서 이미 처리했으므로 MVVM 빌더 6단계는 스킵 처리)

## 제약
