import Foundation

struct AuthorizeDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingsKeys: String, CodingKey {
        case accessToken
        case refreshToken
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingsKeys.self)
        
        self.accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken) ?? ""
        self.refreshToken = try values.decodeIfPresent(String.self, forKey: .refreshToken) ?? ""
    }
}
