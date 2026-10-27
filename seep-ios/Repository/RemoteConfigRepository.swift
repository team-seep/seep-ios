import FirebaseRemoteConfig

protocol RemoteConfigRepository {
    func fetchForceUpdateVersion() async -> Result<String, Error>
    /// 최신 값을 받아 적용한다. 실패하면 마지막으로 적용된 값이 그대로 남는다 (GH-34 R-9)
    func fetchAndActivate() async
    /// 마지막으로 적용된 연말 회고 노출 기간. 값이 없거나 틀리면 nil (GH-34 R-9)
    func fetchYearReviewPeriod() -> YearReviewPeriod?
    /// 마지막으로 적용된 Realm 재이전 토큰. 비어 있으면 재이전하지 않는다 (GH-96 R-2)
    func fetchLegacyRealmReimportToken() -> String
}

struct RemoteConfigRepositoryImpl: RemoteConfigRepository {
    enum Constant {
        static let timeout: TimeInterval = 1800
        static let yearReviewPeriodKey = "year_review_period"
        static let legacyRealmReimportTokenKey = "legacy_realm_reimport_token"
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
    
    func fetchAndActivate() async {
        _ = try? await instance.fetch(withExpirationDuration: Constant.timeout)
        _ = try? await instance.activate()
    }
    
    func fetchYearReviewPeriod() -> YearReviewPeriod? {
        return YearReviewPeriod.parse(instance[Constant.yearReviewPeriodKey].stringValue)
    }

    func fetchLegacyRealmReimportToken() -> String {
        instance[Constant.legacyRealmReimportTokenKey].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
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
