import Foundation
import Combine

final class APIClient {
    let session: URLSession
    let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = .init()
    ) {
        self.session = session
        self.decoder = decoder
    }

    private func request<E: Endpoint>(endpoint: E) -> AnyPublisher<(Data, HTTPURLResponse), Error> {
        do {
            let urlRequest = try endpoint.urlRequest()
            return session.dataTaskPublisher(for: urlRequest)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    return (data, httpResponse)
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func request<E: Endpoint>(_ endpoint: E) -> AnyPublisher<APIResponse<E.ResponseData>, Error> where E.ResponseData: Decodable {
        request(endpoint: endpoint)
            .tryMap { [decoder] data, response in
                let decoded = try decoder.decode(E.ResponseData.self, from: data)
                return APIResponse(response: response, data: decoded)
            }
            .eraseToAnyPublisher()
    }

    func request<E: Endpoint>(_ endpoint: E) -> AnyPublisher<APIResponse<Void>, Error> where E.ResponseData == Void {
        request(endpoint: endpoint)
            .map { _, response in APIResponse(response: response, data: ()) }
            .eraseToAnyPublisher()
    }
}
