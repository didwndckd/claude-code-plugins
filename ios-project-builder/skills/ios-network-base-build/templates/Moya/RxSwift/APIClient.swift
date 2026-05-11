import Foundation
import RxSwift
import Moya
import RxMoya

final class APIClient {
    let provider: MoyaProvider<MultiTarget>
    let decoder: JSONDecoder

    init(
        provider: MoyaProvider<MultiTarget> = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    private func request<T: TargetType>(target: T) -> Single<Response> {
        provider.rx.request(MultiTarget(target))
    }

    func request<E: Endpoint>(_ endpoint: E) -> Single<APIResponse<E.ResponseData>> where E.ResponseData: Decodable {
        request(target: endpoint)
            .map { [decoder] response in
                let data = try decoder.decode(E.ResponseData.self, from: response.data)
                return APIResponse(response: response, data: data)
            }
    }

    func request<E: Endpoint>(_ endpoint: E) -> Single<APIResponse<Void>> where E.ResponseData == Void {
        request(target: endpoint)
            .map { APIResponse(response: $0, data: ()) }
    }
}
