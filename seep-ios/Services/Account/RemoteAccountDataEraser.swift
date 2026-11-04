import Foundation

/// 계정 삭제 때 서버에 있는 내 위시·사진을 지운다 (GH-93 R-29, 설계 §8)
protocol RemoteAccountDataEraser {
    func eraseAll(uid: String) async throws
}

/// 동기화(2단계) 전에는 서버에 올라간 위시가 없다. 동기화 엔진이 들어오면 Firestore·Storage 삭제 구현으로 바꾼다
struct NoRemoteAccountData: RemoteAccountDataEraser {
    func eraseAll(uid: String) async throws {}
}
