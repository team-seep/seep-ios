import Foundation

import RxSwift
import Alamofire

extension AnyObserver {
    func processHTTPError<T>(response: AFDataResponse<T>) {
        if let statusCode = response.response?.statusCode {
            if let httpError = HTTPError(rawValue: statusCode) {
                self.onError(httpError)
            } else {
                self.onError(BaseError.unknown)
            }
        } else {
            switch response.result {
            case .failure(let error):
                if error._code == 13 {
                    self.onError(BaseError.timeout)
                } else {
                    self.onError(error)
                }
            default:
                break
            }
        }
    }
    
    func processDataResponse<T: Decodable>(class: T.Type, response: AFDataResponse<Data>) {
        if let data = response.value {
            if let element: T = JsonUtils.decode(data: data) {
                self.onNext(element as! Element)
                self.onCompleted()
            } else {
                self.onError(BaseError.failDecoding)
            }
        } else {
            self.onError(BaseError.nilValue)
        }
    }
    
//    func processAPIError(response: AFDataResponse<Data>) {
//        if let value = response.value,
//           let errorContainer: ResponseContainer<String> = JsonUtils.decode(data: value) {
//            self.onError(BaseError.custom(errorContainer.message))
//        } else {
//            self.processHTTPError(response: response)
//        }
//    }
}
