import UIKit
import CoreData

class CellAccessoryView: UIView {

    // MARK: - Public

    init(item: NSManagedObject) {
        if let place = item as? Place {
            colors = [UIColor(hex: place.hexColor)]
        } else if let folder = item as? Folder {
            let hexColors = folder.flattenedPlacesArray.map({ $0.hexColor })
            var frequency: [Int32: Int] = [:]
            hexColors.forEach { frequency[$0] = (frequency[$0] ?? 0) + 1 }
            let uniqueSortedHexColors = Set(hexColors).sorted(by: { (hexColor1, hexColor2) -> Bool in
                return frequency[hexColor1]! > frequency[hexColor2]!
            })
            colors = uniqueSortedHexColors.prefix(3).map({ UIColor.init(hex: $0) })
        } else {
            colors = []
        }
        super.init(frame: CGRect(x: 0, y: 0, width: (colors.count * 24) - 8, height: 16))
        createSubviews()
    }

    // MARK: - Overrides

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private let colors: [UIColor]

    private func createSubviews() {
        let stackView = UIStackView(arrangedSubviews: colors.map({ dotView(withColor: $0) }))
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func dotView(withColor color: UIColor) -> UIView {
        let dot = UIView.init(frame: .zero)
        dot.backgroundColor = color
        dot.layer.cornerRadius = 8
        dot.widthAnchor.constraint(equalToConstant: 16).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return dot
    }
}
