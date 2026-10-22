import Foundation

/// 링크 미리보기 상태 (GH-29). 작성·수정의 링크 칸과 상세 링크 줄이 같이 쓴다
enum WishLinkPreviewState: Equatable {
    case hidden
    case loading(domain: String)
    case loaded(LinkPreview)
    /// 미리보기를 못 불러왔다. 링크는 그대로 저장·열기 가능 (GH-29 R-3)
    case failed(domain: String)
}
