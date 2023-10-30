import UIKit

class FilterCell: UICollectionViewCell {
    static let reuseIdentifier = "FilterCell"
    
    let filterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(filterLabel)
        NSLayoutConstraint.activate([
            filterLabel.topAnchor.constraint(equalTo: topAnchor),
            filterLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            filterLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            filterLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
