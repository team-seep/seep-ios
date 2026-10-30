import Foundation

/// 문구에 들어가는 기기 이름("아이폰 설정"·"아이패드 설정")을 고를 때만 쓴다.
/// 화면 배치는 기기가 아니라 size class 로 나눈다 (GH-99 R-2, R-11)
enum DeviceKind {
    case phone
    case pad

    /// UIKit 은 AppDelegate 만 쓰므로(R1) 실행할 때 AppDelegate 가 정한다
    static var current: DeviceKind = .phone
}
