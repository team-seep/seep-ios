import UIKit

import RxSwift
import RxCocoa

final class PageItemView: BaseView {
    let pullToRefreshTableView = UIRefreshControl()
    let pullToRefreshCollectionView = UIRefreshControl()
    
    let tableView = UITableView().then {
        $0.tableFooterView = UIView()
        $0.backgroundColor = .clear
        $0.rowHeight = UITableView.automaticDimension
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        $0.register(
            HomeWishListCell.self,
            forCellReuseIdentifier: "HomeWishListCell"
        )
    }
    
    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        // itemSize·하단 inset은 layoutSubviews에서 실제 폭으로 계산한다
        layout.minimumInteritemSpacing = 15
        layout.minimumLineSpacing = 16
        $0.collectionViewLayout = layout
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
        $0.alpha = 0.0
        $0.register(
            HomeWishListCell.self,
            forCellWithReuseIdentifier: "HomeWishListCell"
        )
    }
    
    let emptyLabel = UILabel().then {
        $0.textColor = UIColor(r: 170, g: 170, b: 170)
        $0.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle().then {
            $0.lineHeightMultiple = 1.5
        }
        let attributedText = NSMutableAttributedString(
            string: "home_empty".localized,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.appleMedium(size: 12) as Any
            ])
        $0.attributedText = attributedText
        $0.textAlignment = .center
    }
    
    private let gradientView = UIView().then {
        let gradientLayer = CAGradientLayer()
        let topColor = UIColor(r: 246, g: 247, b: 249, a: 0.0).cgColor
        let bottomColor = UIColor(r: 246, g: 247, b: 249, a: 1.0).cgColor
        
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0.0, 1.0]
        $0.layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 화면(UIScreen)이 아니라 이 뷰의 실제 크기로 계산해 창 크기가 바뀌어도 맞춘다
        gradientView.layer.sublayers?.forEach { $0.frame = gradientView.bounds }
        updateListLayout()
    }
    
    private func updateListLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let itemSize = CGSize(width: bounds.width - 40, height: HomeWishListCell.Layout.height)
        guard itemSize.width > 0, layout.itemSize != itemSize else { return }
        
        layout.itemSize = itemSize
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: (bounds.width - 40 - 15) / 2, right: 20)
        layout.invalidateLayout()
    }
    
    override func setup() {
        self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
        self.tableView.refreshControl = self.pullToRefreshTableView
        self.collectionView.refreshControl = self.pullToRefreshCollectionView
        self.addSubViews([
            self.tableView,
            self.collectionView,
            self.emptyLabel,
            self.gradientView
        ])
    }
    
    override func bindConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        self.emptyLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.tableView)
            make.top.equalToSuperview().offset(181)
        }
        
        self.gradientView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(150)
        }
    }
    
    fileprivate func changeViewType(to viewType: ViewType) {
        switch viewType {
        case .grid:
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.collectionView.alpha = 1.0
                self.tableView.alpha = 0.0
            }
        case .list:
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.collectionView.alpha = 0.0
                self.tableView.alpha = 1.0
            }
        }
    }
}

extension Reactive where Base: PageItemView {
    var viewType: Binder<ViewType> {
        return Binder(self.base) { view, viewType in
            view.changeViewType(to: viewType)
        }
    }
}
