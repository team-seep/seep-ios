enum ViewType: Int {
  case list
  case grid
  
  var imageName: String {
    switch self {
    case .list:
      return "ic_list"
    case .grid:
      return "ic_grid"
    }
  }
  
  func toggle() -> ViewType {
    switch self {
    case .list:
      return .grid
    case .grid:
      return .list
    }
  }
}
