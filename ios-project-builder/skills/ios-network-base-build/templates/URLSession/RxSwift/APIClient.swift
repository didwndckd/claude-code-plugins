import Foundation
import RxSwift

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

    private func request<E: Endpoint>(endpoint: E) -> Single<(Data, HTTPURLResponse)> {
        Single<(Data, HTTPURLResponse)>.create { [session] single in
            let urlRequest: URLRequest
            do {
                urlRequest = try endpoint.urlRequest()
            } catch {
                single(.failure(error))
                return Disposables.create()
            }

            let task = session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    single(.failure(error))
                    return
                }
                guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                    single(.failure(URLError(.badServerResponse)))
                    return
                }
                single(.success((data, httpResponse)))
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }

    func request<E: Endpoint>(_ endpoint: E) -> Single<APIResponse<E.ResponseData>> where E.ResponseData: Decodable {
        request(endpoint: endpoint)
            .map { [decoder] data, response in
                let decoded = try decoder.decode(E.ResponseData.self, from: data)
                return APIResponse(response: response, data: decoded)
            }
    }

    func request<E: Endpoint>(_ endpoint: E) -> Single<APIResponse<Void>> where E.ResponseData == Void {
        request(endpoint: endpoint)
            .map { _, response in APIResponse(response: response, data: ()) }
    }
}
