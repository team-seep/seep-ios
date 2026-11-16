enum HashtagType: String {
    /// 여행
    case trip
    
    /// 스포츠
    case shopping
    
    /// 스포츠
    case sports
    
    /// 커리어
    case career
    
    /// 일상
    case life
    
    /// 취미
    case hobby
    
    /// 데이터
    case date
    
    /// 주식
    case stock
    
    /// 여가생활
    case leisure
    
    var description: String {
        switch self {
        case .trip: return Strings.hashtagTrip
        case .shopping: return Strings.hashtagShopping
        case .sports: return Strings.hashtagSports
        case .career: return Strings.hashtagCareer
        case .life: return Strings.hashtagLife
        case .hobby: return Strings.hashtagHobby
        case .date: return Strings.hashtagDate
        case .stock: return Strings.hashtagStock
        case .leisure: return Strings.hashtagLeisure
        }
    }
    
    /// 저장한 태그를 보여줄 이름. 기본 태그면 언어에 맞는 이름, 직접 입력이면 그대로 (GH-136)
    static func displayName(for tag: String) -> String {
        return HashtagType(rawValue: tag)?.description ?? tag
    }

    /// 직접 입력한 글자가 기본 태그 이름과 같으면 그 기본 태그로 본다 — "여행"을 직접 쳐도 기본 태그 여행과 겹치지 않게 (GH-136)
    static func preset(named name: String) -> HashtagType? {
        return array.first { $0.description == name || $0.rawValue == name }
    }

    static var array: [HashtagType] {
        return [
            .trip,
            .shopping,
            .sports,
            .career,
            .life,
            .hobby,
            .date,
            .stock,
            .leisure
        ]
    }
}
