---
name: ios-architecture-build
description: base spec(`docs/specs/base.md`)을 기반으로 iOS 프로젝트 구조를 결정한다. user에게 세 가지 진입점(클린 아키텍처 / MVVM / 대화형 설계)을 제시하고 선택된 후속 스킬을 호출한다. spec 분석(`spec-analysis`) + 기술 스택 결정(`ios-tech-stack`) 이후에 호출.
---

# 아키텍처 빌드 스킬 (iOS)

## 사전 조건

- `docs/specs/base.md`가 없으면 멈추고 `spec-analysis` 스킬을 먼저 돌리라고 안내.
- `CLAUDE.md`(프로젝트 루트)에 `## 기술 스택` 섹션이 없으면 멈추고 `ios-tech-stack` 스킬을 먼저 돌리라고 안내.

## 작업 절차

### 1. 컨텍스트 적재

후속 스킬이 자연스럽게 참조할 수 있도록 본 스킬에서 미리 읽어 컨텍스트로 보관한다.

- `docs/specs/base.md` 전문.
- `CLAUDE.md`의 `## 기술 스택` 섹션.

### 2. 진입점 선택

`AskUserQuestion`으로 user에게 다음 중 하나를 선택받는다:

- `클린 아키텍처`: `ios-clean-architecture-build` 스킬 호출
- `MVVM`: `ios-mvvm-architecture-build` 스킬 호출
- `대화형 설계`: `ios-conversational-architecture-build` 스킬 호출

### 3. 선택된 스킬 호출

`Skill` 도구로 선택지에 매핑된 스킬을 호출한다. 1단계에서 적재한 base.md와 `## 기술 스택`이 호출 시점의 컨텍스트로 함께 전달된다. 호출 후 본 스킬의 작업은 종료.

- `클린 아키텍처` → `ios-clean-architecture-build`
- `MVVM` → `ios-mvvm-architecture-build`
- `대화형 설계` → `ios-conversational-architecture-build`

## 제약

- 본 스킬은 라우터 역할만 한다. 폴더 생성, `CLAUDE.md` 작성, 룰 배치 등은 후속 스킬의 책임.
- 후속 스킬에 전달할 인자가 필요하면 후속 스킬의 사양을 따른다. 본 스킬에서 임의로 결정하지 않는다.
