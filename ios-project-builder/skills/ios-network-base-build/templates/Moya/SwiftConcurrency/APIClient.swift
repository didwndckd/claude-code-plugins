import Foundation
import Moya

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

    private func request<T: TargetType>(target: T) async throws -> Response {
        let result = await withCheckedContinuation { continuation in
            _ = provider.requestNormal(MultiTarget(target), callbackQueue: nil, progress: nil) { response in
                continuation.resume(returning: response)
            }
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func request<E: Endpoint>(_ endpoint: E) async throws -> APIResponse<E.ResponseData> where E.ResponseData: Decodable {
        let response = try await request(target: endpoint)
        let data = try decoder.decode(E.ResponseData.self, from: response.data)
        return APIResponse(response: response, data: data)
    }

    func request<E: Endpoint>(_ endpoint: E) async throws -> APIResponse<Void> where E.ResponseData == Void {
        let response = try await request(target: endpoint)
        return APIResponse(response: response, data: ())
    }
}
