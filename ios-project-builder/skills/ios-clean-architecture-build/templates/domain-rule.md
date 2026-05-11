---
paths:
  - "**/Domain/**"
---

# 도메인 룰

## 폴더 구조

```
<도메인명>/
├── Model/
├── Repository/
└── UseCase/   # Optional
```

## 규칙

- UseCase는 의미있는 비즈니스 로직이 있는 경우에만 작성한다.
- Repository 메서드를 그대로 호출만 하는 passthrough UseCase는 만들지 않는다.
- UseCase: `protocol <동작>UseCase` + `final class <동작>UseCaseImpl` (둘 다 Domain). 메서드는 `execute` 단일.
- Repository: `protocol <도메인명>Repository`만 Domain에 둔다. Impl은 Data 레이어.
