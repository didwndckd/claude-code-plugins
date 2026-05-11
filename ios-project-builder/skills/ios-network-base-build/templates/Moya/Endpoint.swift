import Foundation
import Moya

protocol Endpoint: TargetType {
    associatedtype ResponseData
}
