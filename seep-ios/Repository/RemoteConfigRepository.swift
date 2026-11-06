import FirebaseRemoteConfig

protocol RemoteConfigRepository {
    func fetchForceUpdateVersion() async -> Result<String, Error>
    /// 최신 값을 받아 적용한다. 실패하면 마지막으로 적용된 값이 그대로 남는다 (GH-34 R-9)
    func fetchAndActivate() async
    /// 마지막으로 적용된 연말 회고 노출 기간. 값이 없거나 틀리면 nil (GH-34 R-9)
    func fetchYearReviewPeriod() -> YearReviewPeriod?
    /// 마지막으로 적용된 Realm 재이전 토큰. 비어 있으면 재이전하지 않는다 (GH-96 R-2)
    func fetchLegacyRealmReimportToken() -> String
    /// 로그인·동기화 킬 스위치. 마지막으로 적용된 값, 받은 적 없으면 false (GH-93 R-30)
    func fetchSyncEnabled() -> Bool
}

struct RemoteConfigRepositoryImpl: RemoteConfigRepository {
    enum Constant {
        static let timeout: TimeInterval = 1800
        static let yearReviewPeriodKey = "year_review_period"
        static let legacyRealmReimportTokenKey = "legacy_realm_reimport_token"
        static let syncEnabledKey = "sync_enabled"
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

    func fetchSyncEnabled() -> Bool {
        #if DEBUG
        // 개발 빌드에서 콘솔 값과 상관없이 켜 보려면 실행 인자 `-sync_enabled YES`
        if UserDefaults.standard.object(forKey: Constant.syncEnabledKey) != nil {
            return UserDefaults.standard.bool(forKey: Constant.syncEnabledKey)
        }
        #endif
        return instance[Constant.syncEnabledKey].boolValue
    }
}

enum RemoteConfigError: LocalizedError {
    case fetchingFailed
    
    var errorDescription: String? {
        switch self {
        case .fetchingFailed:
            return Strings.Common.temporaryError
        }
    }
}
