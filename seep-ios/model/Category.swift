enum Category: String {
    case wantToDo = "category_want_to_do"
    case wantToGet = "category_want_to_get"
    case wantToGo = "category_want_to_go"
    
    func getIndex() -> Int {
        switch self {
        case .wantToDo:
            return 0
        case .wantToGet:
            return 1
        case .wantToGo:
            return 2
        }
    }
}
