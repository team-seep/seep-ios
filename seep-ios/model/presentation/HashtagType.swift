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
