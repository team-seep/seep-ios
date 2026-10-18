import UIKit

import CombineCocoa

final class HomeWishGridCell: BaseCollectionViewCell {
    enum Layout {
        static let spacing: CGFloat = 15
        static let heightRatio: CGFloat = 1.09
        /// 한 열에 이 폭이 확보될 때마다 열을 늘린다. 셀 폭이 아이폰(약 174pt)과 비슷하게 유지되는 값.
        /// 사용 가능 폭 540pt(컬렉션뷰 580pt)부터 3열 — 아이폰·듀오 바깥은 2열, 듀오 안쪽(폭 600 제한 시 560)은 3열
        static let columnWidthUnit: CGFloat = 180
        static let minimumColumnCount = 2

        /// availableWidth: 섹션 좌우 inset을 뺀 폭
        static func columnCount(availableWidth: CGFloat) -> Int {
            guard availableWidth > 0 else { return minimumColumnCount }
            return max(minimumColumnCount, Int(availableWidth / columnWidthUnit))
        }

        static func itemSize(availableWidth: CGFloat) -> CGSize {
            let columnCount = CGFloat(columnCount(availableWidth: availableWidth))
            let width = max(0, (availableWidth - spacing * (columnCount - 1)) / columnCount)
            return CGSize(width: width, height: width * heightRatio)
        }
        
        /// 사진이 있는 셀 (GH-36 R-6)
        enum Photo {
            static let height: CGFloat = 92
            static let emojiCircleSize: CGFloat = 34
            static let emojiFontSize: CGFloat = 19
            /// 사진 아래 모서리에 원의 절반쯤 걸치게 둔다
            static let emojiCircleOverlap: CGFloat = 18
            static let titleTopSpacing: CGFloat = 20
            /// 세로 사진(3:4)도 aspect fill 로 흐리지 않게 셀 폭보다 조금 크게 디코딩한다 (R-8)
            static let thumbnailScale: CGFloat = 4.0 / 3.0
        }
        
        static let emojiFontSize: CGFloat = 36
    }
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .gray2
        imageView.layer.cornerRadius = 12
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.accessibilityIgnoresInvertColors = true
        imageView.isHidden = true
        return imageView
    }()
    
    private let emojiCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = Layout.Photo.emojiCircleSize / 2
        view.isHidden = true
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Layout.emojiFontSize)
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray5
        label.numberOfLines = 2
        label.font = .appleSemiBold(size: 16)
        return label
    }()
    
    private let ddayLabel = DdayLabel()
    
    private let tagLabel = TagLabel()
    
    private let stepProgressBar = StepProgressBar(width: 32)
    
    private let stepProgressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray4
        label.font = .appleBold(size: 11)
        return label
    }()
    
    private let finishButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icCheckOff.image.resizeImage(scaledTo: 30), for: .normal)
        button.setImage(Assets.Icons.icCheckOn.image.resizeImage(scaledTo: 30), for: .selected)
        return button
    }()
    
    override func setup() {
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.attributedText = nil
        photoImageView.image = nil
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(containerView)
        contentView.addSubview(photoImageView)
        contentView.addSubview(emojiCircleView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ddayLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(stepProgressBar)
        contentView.addSubview(stepProgressLabel)
        contentView.addSubview(finishButton)
        
        containerView.snp.makeConstraints {
            $0.edges.equalTo(0)
        }
        
        photoImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.Photo.height)
        }
        
        emojiCircleView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.top.equalTo(photoImageView.snp.bottom).offset(-Layout.Photo.emojiCircleOverlap)
            $0.size.equalTo(Layout.Photo.emojiCircleSize)
        }
        
        finishButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.bottom.equalToSuperview().offset(-14)
            $0.size.equalTo(30)
        }
        
        stepProgressLabel.snp.makeConstraints {
            $0.leading.equalTo(stepProgressBar.snp.trailing).offset(4)
            $0.centerY.equalTo(ddayLabel)
        }
    }
    
    func bind(viewModel: HomeWishCellViewModel) {
        setupWish(viewModel.output.wish, hasPhoto: viewModel.output.photoFileName != nil)
        setupStepProgress(viewModel.output.stepProgress)
        
        finishButton.tapPublisher
            .subscribe(viewModel.input.didTapFinish)
            .store(in: &cancellables)
        
        if viewModel.output.photoFileName != nil {
            bindThumbnail(viewModel: viewModel)
        }
    }
    
    /// 셀 크기에 맞춘 썸네일을 백그라운드에서 받아 붙인다. 읽기에 실패하면 사진 없는 셀로 되돌린다 (GH-36 R-7, R-8).
    /// 재사용되면 prepareForReuse 에서 구독이 끊겨 늦게 온 썸네일이 다른 위시에 붙지 않는다.
    private func bindThumbnail(viewModel: HomeWishCellViewModel) {
        viewModel.output.thumbnail
            .main
            .withUnretained(self)
            .sink { (owner: HomeWishGridCell, image: CGImage?) in
                if let image {
                    owner.photoImageView.image = UIImage(cgImage: image)
                } else {
                    owner.setupWish(viewModel.output.wish, hasPhoto: false)
                    owner.setupStepProgress(viewModel.output.stepProgress)
                }
            }
            .store(in: &cancellables)
        
        let width = bounds.width > 0 ? bounds.width : Layout.columnWidthUnit
        let maxPixelSize = Int((width * traitCollection.displayScale * Layout.Photo.thumbnailScale).rounded(.up))
        viewModel.input.loadThumbnail.send(maxPixelSize)
    }
    
    func setupWish(_ wish: Wish, hasPhoto: Bool = false) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title
        ddayLabel.bind(dday: wish.endDate)
        finishButton.isSelected = wish.isSuccess
        
        tagLabel.isHidden = wish.hashtag.isEmpty
        if !wish.hashtag.isEmpty {
            tagLabel.text = HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
        }
        
        if hasPhoto {
            setupPhotoLayout(hasTag: !wish.hashtag.isEmpty)
        } else {
            setupDefaultLayout(hasTag: !wish.hashtag.isEmpty)
        }
        
        if wish.isSuccess {
            emojiLabel.alpha = 0.5
            titleLabel.alpha = 0.5
            
            let attributedString = NSMutableAttributedString(string: wish.title)
            attributedString.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: UIColor.gray4.copy()
            ], range: NSRange(location: 0, length: wish.title.count))
            titleLabel.attributedText = attributedString
            
            ddayLabel.alpha = 0.5
            tagLabel.alpha = 0.5
            photoImageView.alpha = 0.5
        } else {
            emojiLabel.alpha = 1
            titleLabel.alpha = 1
            ddayLabel.alpha = 1
            tagLabel.alpha = 1
            photoImageView.alpha = 1
        }
    }
    
    /// 사진 없는 셀 — 지금까지의 레이아웃 그대로. 그리드는 뱃지가 세로로 쌓이므로, 오른쪽이 비어 있는 D-day 줄에 진행도를 붙인다
    private func setupDefaultLayout(hasTag: Bool) {
        photoImageView.isHidden = true
        emojiCircleView.isHidden = true
        emojiLabel.font = .systemFont(ofSize: Layout.emojiFontSize)
        
        emojiLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.top.equalToSuperview().offset(14)
        }
        
        titleLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.trailing.equalToSuperview().offset(-14)
            $0.top.equalTo(emojiLabel.snp.bottom).offset(4)
        }
        
        if hasTag {
            ddayLabel.snp.remakeConstraints {
                $0.leading.equalTo(titleLabel)
                $0.bottom.equalTo(tagLabel.snp.top).offset(-6)
            }
            
            tagLabel.snp.remakeConstraints {
                $0.left.height.equalTo(ddayLabel)
                $0.bottom.equalTo(finishButton)
            }
        } else {
            ddayLabel.snp.remakeConstraints {
                $0.left.equalTo(titleLabel)
                $0.bottom.equalTo(finishButton)
            }
        }
        
        stepProgressBar.snp.remakeConstraints {
            $0.leading.equalTo(ddayLabel.snp.trailing).offset(6)
            $0.centerY.equalTo(ddayLabel)
        }
    }
    
    /// 사진 있는 셀 — 위쪽 92pt 사진, 이모지는 사진 왼쪽 아래 흰 원 안, 뱃지는 한 줄 (GH-36 R-6)
    private func setupPhotoLayout(hasTag: Bool) {
        photoImageView.isHidden = false
        emojiCircleView.isHidden = false
        emojiLabel.font = .systemFont(ofSize: Layout.Photo.emojiFontSize)
        
        emojiLabel.snp.remakeConstraints {
            $0.center.equalTo(emojiCircleView)
        }
        
        ddayLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalTo(finishButton)
        }
        
        if hasTag {
            tagLabel.snp.remakeConstraints {
                $0.leading.equalTo(ddayLabel.snp.trailing).offset(7)
                $0.centerY.height.equalTo(ddayLabel)
            }
        }
        
        titleLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.trailing.equalToSuperview().offset(-14)
            $0.top.equalTo(photoImageView.snp.bottom).offset(Layout.Photo.titleTopSpacing)
            // 두 줄 제목이 뱃지 줄과 겹치면 말줄임한다
            $0.bottom.lessThanOrEqualTo(ddayLabel.snp.top).offset(-4)
        }
        
        stepProgressBar.snp.remakeConstraints {
            $0.leading.equalTo((hasTag ? tagLabel : ddayLabel).snp.trailing).offset(6)
            $0.centerY.equalTo(ddayLabel)
        }
    }
    
    private func setupStepProgress(_ progress: WishStepProgress?) {
        stepProgressBar.isHidden = progress == nil
        stepProgressLabel.isHidden = progress == nil
        guard let progress else { return }
        
        stepProgressBar.bind(progress: progress)
        stepProgressLabel.text = Strings.Home.stepProgressFormat(progress.doneCount, progress.totalCount)
    }
}
