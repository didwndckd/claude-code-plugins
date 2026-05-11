---
name: ios-network-base-build
description: 네트워크 베이스 코드(Endpoint, APIResponse, APIClient)를 지정 경로에 생성한다. network(Moya|URLSession)와 async(SwiftConcurrency|Combine|RxSwift) 인자에 따라 해당 변형의 템플릿 파일을 destination에 통째로 복사. ios-clean-architecture-build 이후, 도메인별 네트워크 코드 작성 전에 호출.
context: fork
arguments:
  - name: path
    description: 베이스 파일을 생성할 대상 디렉터리(절대/상대 경로 모두 허용). 일반적으로 `<프로젝트>/Data/Network` 또는 그 하위.
    type: string
    required: true
    hint: "./Sources/Data/Network"
  - name: network
    description: 네트워크 라이브러리. Moya 또는 URLSession.
    type: string
    required: true
    hint: "Moya"
  - name: async
    description: 비동기 패턴. SwiftConcurrency, Combine, RxSwift 중 하나.
    type: string
    required: true
    hint: "SwiftConcurrency"
---

# 네트워크 베이스 빌더 (iOS)

`Endpoint`, `APIResponse`, `APIClient` 베이스 파일을 `<path>`에 복사한다. 어떤 변형을 복사할지는 `network`/`async` 인자로 결정.

## 템플릿 위치

```
${CLAUDE_SKILL_DIR}/templates/
├── Moya/
│   ├── Endpoint.swift
│   ├── APIResponse.swift
│   ├── SwiftConcurrency/APIClient.swift
│   ├── Combine/APIClient.swift
│   └── RxSwift/APIClient.swift
└── URLSession/
    ├── Endpoint.swift
    ├── APIResponse.swift
    ├── SwiftConcurrency/APIClient.swift
    ├── Combine/APIClient.swift
    └── RxSwift/APIClient.swift
```

`Endpoint`/`APIResponse`는 `network`에만 의존, `APIClient`는 `network`+`async` 조합에 의존.

## 작업 절차

### 1. 스크립트 호출

```
${CLAUDE_SKILL_DIR}/scripts/build-network-base.sh <path> <network> <async>
```

스크립트가 인자 검증, `mkdir -p`, 템플릿 복사를 수행한다.

스크립트 종료 코드:
- `0`: 성공
- `1`: 인자 부족 / 잘못된 플래그 (usage)
- `2`: `network`/`async` 값 오류 → 멈추고 `AskUserQuestion`으로 user에게 다시 묻고 재호출
- `3`: 템플릿 파일 누락 (스킬 설치 손상) → user에게 보고하고 멈춤
- `4`: destination에 동일 파일이 이미 존재 → user에게 덮어쓸지 묻고, 동의 시 `--force` 플래그로 재호출

### 2. 결과 보고

스크립트 stdout의 "Created:" 목록을 user에게 그대로 전달한다.

## 제약

- 템플릿 파일 내용은 수정하지 않고 통째로 복사한다. 토큰 치환/렌더링 없음.
- `path` 외부에는 어떤 파일도 만들지 않는다.
- `CLAUDE.md`는 건드리지 않는다 (기술 스택 결정은 `ios-tech-stack`, 폴더 구조는 `ios-clean-architecture-build` 책임).
- 도메인별 `Endpoint`/`Repository` 작성은 이 스킬 범위 밖.
