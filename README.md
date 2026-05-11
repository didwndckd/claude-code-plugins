# Claude Plugin Marketplace

Claude 플러그인을 검색, 공유, 설치할 수 있는 마켓플레이스입니다.

## 설치

Claude Code에서 마켓플레이스를 추가하고 원하는 플러그인을 설치합니다.

```bash
# 마켓플레이스 추가
/plugin marketplace add didwndckd/claude-plugins

# 플러그인 설치
/plugin install doc-lens@didwndckd-plugins
/plugin install ios-project-builder@didwndckd-plugins
```

## 플러그인 목록

### [doc-lens](./doc-lens)

문서를 요약하고 정확성과 품질을 검증하는 플러그인.

| 스킬                | 역할                                   |
| ------------------- | -------------------------------------- |
| `summarize-doc`     | 문서를 핵심만 추려 요약               |
| `fact-check-doc`    | 요약 결과의 사실성과 누락 여부를 검증 |

### [ios-project-builder](./ios-project-builder)

iOS 프로젝트 빌드를 돕는 플러그인. 스펙 분석 → 기술 스택 결정 → 아키텍처 셋업 → Xcode 프로젝트 생성까지 단계별로 위임.

| 카테고리           | 주요 스킬                                                                                                                                                                                                  |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 스펙 / 아키텍처    | `spec-analysis`, `ios-tech-stack`, `ios-architecture-build`, `ios-clean-architecture-build`, `ios-mvvm-architecture-build`, `ios-conversational-architecture-build`, `ios-network-base-build`              |
| 프로젝트 생성      | `xcode-project-create`, `xcode-project-create-single`, `xcode-project-create-multi`, `xcode-app-module-add`, `xcode-module-add`                                                                            |
| Tuist              | `tuist-base-setup`, `tuist-cleanup`                                                                                                                                                                        |

자세한 플로우와 산출물 구조는 [ios-project-builder/CLAUDE.md](./ios-project-builder/CLAUDE.md) 참고.

## 저장소 구조

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json       # 마켓플레이스 메타데이터
├── doc-lens/                  # 플러그인
│   ├── .claude-plugin/plugin.json
│   └── skills/
└── ios-project-builder/       # 플러그인
    ├── .claude-plugin/plugin.json
    ├── hooks/
    ├── skills/
    └── templates/
```

## 라이선스

[MIT License](./LICENSE)
