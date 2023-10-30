import UIKit

protocol FilterSelectionDelegate: AnyObject {
    func didSelectFilter(at index: Int)
}

class FilterCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var filterDelegate: FilterSelectionDelegate?
    
    private let filters = ["Contrast", "Brightness", "Saturation", "Blur", "Sharpness"]
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(frame: .zero, collectionViewLayout: layout)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.reuseIdentifier)
        delegate = self
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: FilterCell.reuseIdentifier, for: indexPath) as? FilterCell else {
            fatalError("Unable to dequeue FilterCell")
        }
        cell.filterLabel.text = filters[indexPath.item]
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        filterDelegate?.didSelectFilter(at: indexPath.item)
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 50)
    }
}
