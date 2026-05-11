import Foundation
import Combine
import Moya
import CombineMoya

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

    private func request<T: TargetType>(target: T) -> AnyPublisher<Response, MoyaError> {
        provider.requestPublisher(MultiTarget(target))
    }

    func request<E: Endpoint>(_ endpoint: E) -> AnyPublisher<APIResponse<E.ResponseData>, Error> where E.ResponseData: Decodable {
        request(target: endpoint)
            .mapError { $0 as Error }
            .tryMap { [decoder] response in
                let data = try decoder.decode(E.ResponseData.self, from: response.data)
                return APIResponse(response: response, data: data)
            }
            .eraseToAnyPublisher()
    }

    func request<E: Endpoint>(_ endpoint: E) -> AnyPublisher<APIResponse<Void>, Error> where E.ResponseData == Void {
        request(target: endpoint)
            .mapError { $0 as Error }
            .map { APIResponse(response: $0, data: ()) }
            .eraseToAnyPublisher()
    }
}
