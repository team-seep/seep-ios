import Foundation

enum RepositoryError: LocalizedError {
    case noDatabase
    case targetNotFound
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .noDatabase:
            return ""
        case .targetNotFound:
            return ""
        case .writeFailed:
            return ""
        }
    }
}
