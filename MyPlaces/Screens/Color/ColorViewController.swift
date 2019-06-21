import UIKit
import CoreData

/// View allowing the user to select a map marker color
class ColorViewController: UIViewController {

    // MARK: - Public

    init(item: NSManagedObject) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    // MARK: - Overrides

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        if let startingColor = colorFromItem {
            updateViewWithColor(startingColor)
        }
    }

    // MARK: - Actions

    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func doneButtonTapped() {
        let hexColor = Int32(redSlider.intValue << 16 + greenSlider.intValue << 8 + blueSlider.intValue)
        if let place = item as? Place {
            place.hexColor = hexColor
        } else if let folder = item as? Folder {
            folder.flattenedPlacesArray.forEach({ $0.hexColor = hexColor })
        }
        DataManager.sharedDataManager.saveContext()
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func redSliderValueChanged() {
        redField.text = "\(redSlider.intValue)"
        updateColorView()
    }

    @IBAction private func redFieldValueChanged() {
        redSlider.value = Float(redField.intValueOfText)
        updateColorView()
    }

    @IBAction private func greenSliderValueChanged() {
        greenField.text = "\(greenSlider.intValue)"
        updateColorView()
    }

    @IBAction private func greenFieldValueChanged() {
        greenSlider.value = Float(greenField.intValueOfText)
        updateColorView()
    }

    @IBAction private func blueSliderValueChanged() {
        blueField.text = "\(blueSlider.intValue)"
        updateColorView()
    }

    @IBAction private func blueFieldValueChanged() {
        blueSlider.value = Float(blueField.intValueOfText)
        updateColorView()
    }

    @IBAction private func presetColorTapped(_ presetColorView: UIView) {
        guard let color = presetColorView.backgroundColor else { return }
        updateViewWithColor(color)
    }

    // MARK: - Private

    @IBOutlet private var colorView: UIView!
    @IBOutlet private var redSlider: UISlider!
    @IBOutlet private var redField: UITextField!
    @IBOutlet private var greenSlider: UISlider!
    @IBOutlet private var greenField: UITextField!
    @IBOutlet private var blueSlider: UISlider!
    @IBOutlet private var blueField: UITextField!

    private let item: NSManagedObject

    private var colorFromItem: UIColor? {
        if let place = item as? Place {
            return UIColor(hex: place.hexColor)
        } else if let folder = item as? Folder {
            // Only return a nonnull color if all places in the folder have the same color
            let hexColorSet = Set(folder.flattenedPlacesArray.map({ $0.hexColor }))
            return hexColorSet.count == 1 ? UIColor(hex: hexColorSet.first!) : nil
        }
        return nil
    }

    private func setupNavigationBar() {
        title = "Select Color"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonTapped))
    }

    /// Updates the background color of `colorView`
    private func updateColorView() {
        colorView.backgroundColor = UIColor(red: CGFloat(redSlider.intValue) / 255,
                                            green: CGFloat(greenSlider.intValue) / 255,
                                            blue: CGFloat(blueSlider.intValue) / 255,
                                            alpha: 1)
    }

    /// Updates the state of all controls to match the given color.
    private func updateViewWithColor(_ color: UIColor) {
        var floatRed: CGFloat = 0
        var floatGreen: CGFloat = 0
        var floatBlue: CGFloat = 0
        color.getRed(&floatRed, green: &floatGreen, blue: &floatBlue, alpha: nil)
        let (red, green, blue) = (Int(round(floatRed * 255)), Int(round(floatGreen * 255)), Int(round(floatBlue * 255)))
        redSlider.value = Float(red)
        redField.text = "\(red)"
        greenSlider.value = Float(green)
        greenField.text = "\(green)"
        blueSlider.value = Float(blue)
        blueField.text = "\(blue)"
        updateColorView()
    }
}

private extension UISlider {

    var intValue: Int {
        return Int(roundf(value))
    }
}

private extension UITextField {

    var intValueOfText: Int {
        guard let text = text else { return 0 }
        return Int(text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    }
}
