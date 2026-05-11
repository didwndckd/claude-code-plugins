## Input / Output (Combine + UIKit)

- ViewModel은 `Base/ViewModel.swift`의 `ViewModel` 프로토콜을 채택. `Input`, `Output`은 ViewModel 안에 nested struct로 정의.
- `Input`/`Output` struct 정의와 `transform(input:)` 구현은 ViewModel 본체와 같은 파일 내 `extension`으로 분리. 별도 파일로 분리 금지.
- `Input`의 멤버 타입은 `AnyPublisher<X, Never>`만 허용. `PassthroughSubject` 등 송신 가능한 타입을 직접 노출 금지 — 송신은 View 책임.
- `Output`의 멤버 타입은 `AnyPublisher<X, Never>`. Failure는 `Never`로 강제하고, 에러는 `transform(input:)` 안에서 흡수해 별도 Output 멤버(예: `errorMessage`)로 노출.
- View 측 구독 코드는 ViewController의 `bind()` 메서드에 모으고 `viewDidLoad`에서 호출. ViewModel Output은 `sink`/`assign`으로 받아 `Set<AnyCancellable>`에 보관.
