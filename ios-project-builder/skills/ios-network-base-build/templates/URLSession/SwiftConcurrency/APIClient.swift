import Foundation

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

    private func request<E: Endpoint>(endpoint: E) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = try endpoint.urlRequest()
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }

    func request<E: Endpoint>(_ endpoint: E) async throws -> APIResponse<E.ResponseData> where E.ResponseData: Decodable {
        let (data, response) = try await request(endpoint: endpoint)
        let decoded = try decoder.decode(E.ResponseData.self, from: data)
        return APIResponse(response: response, data: decoded)
    }

    func request<E: Endpoint>(_ endpoint: E) async throws -> APIResponse<Void> where E.ResponseData == Void {
        let (_, response) = try await request(endpoint: endpoint)
        return APIResponse(response: response, data: ())
    }
}
