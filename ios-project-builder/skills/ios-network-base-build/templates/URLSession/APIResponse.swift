import Foundation

struct APIResponse<ResponseData> {
    let response: HTTPURLResponse
    let data: ResponseData
}
