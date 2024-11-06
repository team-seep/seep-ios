import FirebaseRemoteConfig

protocol RemoteConfigRepository {
    func fetchForceUpdateVersion() async -> Result<String, Error>
}

struct RemoteConfigRepositoryImpl: RemoteConfigRepository {
    enum Constant {
        static let timeout: TimeInterval = 1800
    }
    
    private let instance = RemoteConfig.remoteConfig()
    
    func fetchForceUpdateVersion() async -> Result<String, Error> {
        do {
            let fetchResult = try await instance.fetch(withExpirationDuration: Constant.timeout)
            
            switch fetchResult {
            case .success:
                let minimumVersion = instance["minimumVersion"].stringValue
                
                return .success(minimumVersion)
            default:
                return .failure(RemoteConfigError.fetchingFailed)
            }
        } catch {
            return .failure(error)
        }
    }
}

enum RemoteConfigError: LocalizedError {
    case fetchingFailed
    
    var errorDescription: String? {
        switch self {
        case .fetchingFailed:
            return "일시적인 에러가 발생했습니다.\n잠시 후 다시 시도해주세요."
        }
    }
}
