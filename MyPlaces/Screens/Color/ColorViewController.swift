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
        title = "Select Color"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonTapped))
    }

    // MARK: - Actions

    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func doneButtonTapped() {
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
        currentColor = color
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

    private var currentColor: UIColor {
        get {
            return UIColor(red: CGFloat(redSlider.intValue) / 255,
                           green: CGFloat(greenSlider.intValue) / 255,
                           blue: CGFloat(blueSlider.intValue) / 255,
                           alpha: 1)
        }
        set {
            var floatRed: CGFloat = 0
            var floatGreen: CGFloat = 0
            var floatBlue: CGFloat = 0
            newValue.getRed(&floatRed, green: &floatGreen, blue: &floatBlue, alpha: nil)
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

    private func updateColorView() {
        colorView.backgroundColor = currentColor
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
