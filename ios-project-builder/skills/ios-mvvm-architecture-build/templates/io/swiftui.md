## SwiftUI

- ViewModel은 `@MainActor`로 격리하고 `ObservableObject` 채택. 출력 상태는 `@Published private(set) var` 권장 — Toggle/TextField 등 양방향 바인딩이 필요한 경우에 한해 `@Published var` 허용.
- View는 자기 ViewModel 외 Repository/Network 등 외부 의존을 직접 호출하지 않는다 — 모든 사이드이펙트는 ViewModel 메서드를 통해.
- View가 ViewModel을 처음 생성하는 경우 `@StateObject`, 부모로부터 주입받는 경우 `@ObservedObject`. 같은 ViewModel 인스턴스를 두 위치에서 모두 `@StateObject`로 선언 금지.
- View → ViewModel 입력은 ViewModel 메서드 직접 호출. 화면 진입 시 비동기 트리거는 `.task` modifier 사용 (`onAppear` + `Task { }`는 화면 dismiss 시 자동 취소 안 됨).
