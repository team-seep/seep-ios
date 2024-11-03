import UIKit

final class HomeDataSource: UICollectionViewDiffableDataSource<HomeSection, HomeSectionItem> {
    private let viewModel: HomeViewModel
    
    init(collectionView: UICollectionView, viewModel: HomeViewModel) {
        self.viewModel = viewModel
        
        collectionView.register([
            HomeOverviewCell.self,
            HomeWishGridCell.self,
            HomeWishListCell.self,
            HomeEmptyCell.self
        ])
        
        collectionView.registerSectionHeader([HomeFilterHeaderView.self])
        
        super.init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .overview(let category, let count):
                let cell: HomeOverviewCell = collectionView.dequeueReusableCell(indexPath: indexPath)
                cell.bind(category: category, count: count)
                return cell
            case .wish(let viewModel):
                switch viewModel.output.viewType {
                case .list:
                    let cell: HomeWishListCell = collectionView.dequeueReusableCell(indexPath: indexPath)
                    cell.bind(viewModel: viewModel)
                    return cell
                case .grid:
                    let cell: HomeWishGridCell = collectionView.dequeueReusableCell(indexPath: indexPath)
                    cell.bind(viewModel: viewModel)
                    return cell
                }
            case .empty:
                let cell: HomeEmptyCell = collectionView.dequeueReusableCell(indexPath: indexPath)
                return cell
            }
        }
        
        supplementaryViewProvider = { [weak self] collectionView, kind, indexPath -> UICollectionReusableView? in
            guard let section = self?.sectionIdentifier(for: indexPath.section) else { return nil }
            
            switch section.type {
            case .overview:
                return nil
            case .wish(let headerViewModel):
                let headerView: HomeFilterHeaderView = collectionView.dequeueReusableSupplementaryView(ofkind: kind, indexPath: indexPath)
                headerView.bind(viewModel: headerViewModel)
                return headerView
            }
        }
    }
    
    func reload(_ sections: [HomeSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeSectionItem>()
        
        sections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.items)
        }
        
        apply(snapshot, animatingDifferences: false)
    }
}

struct HomeSection: Hashable {
    enum SectionType: Hashable {
        case overview
        case wish(HomeFilterHeaderViewModel)
    }
    
    let type: SectionType
    var items: [HomeSectionItem]
}

enum HomeSectionItem: Hashable {
    case overview(category: Category, count: Int)
    case wish(HomeWishCellViewModel)
    case empty
}
