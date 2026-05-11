## Input / Output (RxSwift + UIKit)

- ViewModel은 `Base/ViewModel.swift`의 `ViewModel` 프로토콜을 채택. `Input`, `Output`은 ViewModel 안에 nested struct로 정의.
- `Input`/`Output` struct 정의와 `transform(input:)` 구현은 ViewModel 본체와 같은 파일 내 `extension`으로 분리. 별도 파일로 분리 금지.
- `Input`의 멤버 타입은 `Signal<X>` 우선 (이벤트 표현 + 에러 흡수 + 메인 스레드). 상태성 입력(텍스트 필드 값 등)은 `Driver<X>`. `PublishRelay`/`PublishSubject` 등 송신 가능한 타입을 직접 노출 금지 — `ControlEvent`는 View가 `asSignal(onErrorSignalWith: .empty())`로 변환해 전달.
- `Output`의 멤버 타입은 `Driver<X>` 우선 (메인 스레드 보장 + 에러 흡수). 에러는 `transform(input:)` 안에서 흡수.
- View 측 구독 코드는 ViewController의 `bind()` 메서드에 모으고 `viewDidLoad`에서 호출. ViewModel Output은 `bind(to:)`/`drive(onNext:)`로 받아 `DisposeBag`에 보관.
