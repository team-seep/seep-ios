import UIKit
import Combine

import RxSwift

class BaseCollectionViewCell: UICollectionViewCell {
    var cancellables = Set<AnyCancellable>()
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        bindConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        cancellables = Set<AnyCancellable>()
    }
    
    func setup() { }
    
    func bindConstraints() { }
}
