import UIKit

// Deprecated (GH-9): 앱 시작 때 화면 크기로 한 번 계산돼 폴더블·창 크기 변경을 따라가지 못한다.
// 새 코드는 뷰의 bounds를 쓴다(린트 no_screen_size). 남은 사용처가 정리되면 지운다.
struct RatioUtils {
    static let height = UIScreen.main.bounds.height / 812
    static let width = UIScreen.main.bounds.width / 375
}
