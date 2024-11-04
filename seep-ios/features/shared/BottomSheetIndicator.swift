import UIKit

final class BottomSheetIndicator: BaseView {
    enum Layout {
        static let height: CGFloat = 20
        static let indicatorSize = CGSize(width: 48, height: 4)
    }
    
    let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()
    
    override func setup() {
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(indicatorView)
        
        indicatorView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(Layout.indicatorSize)
        }
        
        snp.makeConstraints {
            $0.height.equalTo(Layout.height)
        }
    }
}
