import Moya

struct APIResponse<ResponseData> {
    let response: Moya.Response
    let data: ResponseData
}
