import UIKit

/// 클립보드에 글자를 넣는다. ViewModel 은 이 프로토콜만 알고, UIKit 은 이 파일에만 둔다 (GH-77 R-3)
protocol PasteboardWriting {
    func copy(_ text: String)
}

/// iOS SwiftUI 에는 클립보드 쓰기 API가 없어 `UIPasteboard`를 감싼다 (RULES.md R1 예외)
struct SystemPasteboard: PasteboardWriting {
    func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
