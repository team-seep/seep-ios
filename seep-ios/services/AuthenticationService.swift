import RxSwift
import Alamofire

protocol AuthenticationServiceType {
    func authorizeWithApple(token: String) -> Observable<AuthorizeDTO>
    
    func authorizeWithKakao(token: String) -> Observable<AuthorizeDTO>
}

struct AuthenticationService: AuthenticationServiceType {
    private let networkManager = NetworkManager()
    
    func authorizeWithApple(token: String) -> Observable<AuthorizeDTO> {
        let urlString = HTTPUtils.url + "/auth/apple/authorize"
        let parameters: [String: Any] = ["code": token]
        let headers = HTTPUtils.jsonHeader()
        
        return self.networkManager.createGetObservable(
            class: AuthorizeDTO.self,
            urlString: urlString,
            headers: headers,
            parameters: parameters
        )
    }
    
    func authorizeWithKakao(token: String) -> Observable<AuthorizeDTO> {
        let urlString = HTTPUtils.url + "/auth/kakao/authorize"
        let parameters: [String: Any] = ["code": token]
        let headers = HTTPUtils.jsonHeader()
        
        return self.networkManager.createGetObservable(
            class: AuthorizeDTO.self,
            urlString: urlString,
            headers: headers,
            parameters: parameters
        )
    }
}
