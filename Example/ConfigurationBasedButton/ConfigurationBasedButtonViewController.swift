//
//  ConfigurationBasedButtonViewController.swift
//  FontPractice
//
//  Created by 🌊 薛 on 2022/8/25.
//

import UIKit
import ConfigurationBasedButton

class MyStyleButtonConfigurationProvider: PlainButtonConfigurationProvider {
    enum Style {
    case primaryOutline
    case primaryFilled
    }
    
    private lazy var primaryOutlineConfiguration: ButtonConfiguration = {
        var config = ButtonConfiguration()
        config.contentInsets = .nondirectional(UIEdgeInsets(top: 10, left: 40, bottom: 10, right: 40))
        config.foregroundColor = UIColor(named: "purple")
        config.imagePadding = 10
        config.background?.fillColor = UIColor.clear
        config.background?.strokeColor = UIColor(named: "purple")
        config.background?.strokeWidth = 1
        config.background?.cornerStyle = .capsule
        return config
    }()
    
    private lazy var primaryFilledConfiguration: ButtonConfiguration = {
        var config = ButtonConfiguration()
        config.contentInsets = .nondirectional(UIEdgeInsets(top: 10, left: 40, bottom: 10, right: 40))
        config.foregroundColor = UIColor.white
        config.imagePadding = 10
        config.background?.fillColor = UIColor(named: "purple")
        config.background?.cornerStyle = .capsule
        return config
    }()
    
  
    public let style: Style
    
    init(style: Style) {
        self.style = style
    }
    
    override func update(_ configuration: inout ButtonConfiguration, for button: ConfigurationBasedButton) {
        switch style {
        case .primaryOutline:
            configuration.contentInsets = primaryOutlineConfiguration.contentInsets
            configuration.foregroundColor = primaryOutlineConfiguration.foregroundColor
            configuration.imagePadding = primaryOutlineConfiguration.imagePadding
            configuration.background?.fillColor = primaryOutlineConfiguration.background?.fillColor
            configuration.background?.strokeColor = primaryOutlineConfiguration.background?.strokeColor
            configuration.background?.strokeWidth = primaryOutlineConfiguration.background?.strokeWidth ?? 1
            configuration.background?.cornerStyle = primaryOutlineConfiguration.background?.cornerStyle
        case .primaryFilled:
            configuration.contentInsets = primaryFilledConfiguration.contentInsets
            configuration.foregroundColor = primaryFilledConfiguration.foregroundColor
            configuration.imagePadding = primaryFilledConfiguration.imagePadding
            configuration.background?.fillColor = primaryFilledConfiguration.background?.fillColor
            configuration.background?.strokeColor = primaryFilledConfiguration.background?.strokeColor
            configuration.background?.strokeWidth = primaryFilledConfiguration.background?.strokeWidth ?? 1
            configuration.background?.cornerStyle = primaryFilledConfiguration.background?.cornerStyle
        }
        super.update(&configuration, for: button)
    }
}


class MyButtonActivityIndicatorView: UIView, ButtonActivityIndicatorType {
    
    var indicatorColor: UIColor?
    
    func startAnimating() {
        print("start animating")
    }
    
    func stopAnimating() {
        print("stop animating")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 30, height: 30)
    }
}


class ConfigurationBasedButtonViewController: UIViewController {
    
    @IBOutlet weak var systemButton: UIButton!
    @IBOutlet var systemButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var systemButtonHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private var button: ConfigurationBasedButton! 
    @IBOutlet var buttonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var buttonHeightConstraint: NSLayoutConstraint!
    
    lazy var backgroundViewController: BackgroundViewController = {
        let backgroundViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BackgroundViewController") as! BackgroundViewController
        backgroundViewController.apply = { [weak self] systemBg, bg in
            if bg.cornerStyle == .capsule {
                self?.systemButton.configuration?.cornerStyle = .capsule
            }
            self?.systemButton.configuration?.background = systemBg
            self?.button.baseConfiguration.background = bg
        }
        return backgroundViewController;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundButtonBarItem = UIBarButtonItem(title: "background", style: .plain, target: self, action: #selector(configureBackground))
        self.navigationItem.rightBarButtonItem = backgroundButtonBarItem

        var configuration = button.baseConfiguration
        configuration.title = "This's title"
        configuration.subtitle = "This's subtitle"
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 28)
        let image = UIImage(systemName: "house.circle.fill", withConfiguration: imageConfig)
        configuration.image = image
        button.baseConfiguration = configuration
        button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)

        var systemButtonConfiguration = UIButton.Configuration.plain()
        systemButtonConfiguration.title = "This's title"
        systemButtonConfiguration.subtitle = "This's subtitle"
        systemButtonConfiguration.image = image
        systemButtonConfiguration.preferredSymbolConfigurationForImage = imageConfig
        systemButtonConfiguration.contentInsets = NSDirectionalEdgeInsets.zero
        systemButton.configuration = systemButtonConfiguration
        
        button.baseConfiguration.foregroundColor = UIColor.white
         
//      button.configurationProvider = MyStyleButtonConfigurationProvider(style: .primaryOutline)
        
        // Create base configuration.
//        var baseConfiguration = ButtonConfiguration()
//        baseConfiguration.title = "Title"
//        baseConfiguration.subtitle = "Subtitle"
//        baseConfiguration.image = UIImage(systemName: "house.circle.fill")
//        baseConfiguration.imagePadding = 10
//        baseConfiguration.contentInsets = .nondirectional(.init(top: 10, left: 40, bottom: 10, right: 40))
//
//        // Create plain-style configuration provider.
//        let configurationProvider = PlainButtonConfigurationProvider()
//
//        // Create button1 with baseConfiguration, configurationProvider and action for `touchUpInside`.
//        let button1 = ConfigurationBasedButton(baseConfiguration: baseConfiguration, configurationProvider: configurationProvider) { _ in
//            print("Button1 has been tapped")
//        }
//
//        // Create button2 with button1's base configuration.
//        let button2 = ConfigurationBasedButton()
//        button2.baseConfiguration = button1.baseConfiguration
//
//        // Create button3 with current button1's effective configuration.
//        button1.isHighlighted = true
//        let button3 = ConfigurationBasedButton(baseConfiguration: button1.effectiveConfiguration)
//
//        // Update configuration.
//        // The UI will not be updated immediately, multiple requests may be coalesced into a single update at the appropriate time.
//        button1.baseConfiguration.title = "Update Title"
//        button1.baseConfiguration.image = nil
//        button1.baseConfiguration.background?.fillColor = UIColor.white
//        button1.baseConfiguration.background?.cornerStyle = .capsule
        
        
    }
    
    @objc func configureBackground() {
        self.navigationController?.pushViewController(backgroundViewController, animated: true)
    }
    
    @IBAction func imagePlacementSegmentAction(sender: UISegmentedControl) {
        button.baseConfiguration.imagePlacement = ButtonConfiguration.ImagePlacement(rawValue: sender.selectedSegmentIndex)!
        
        switch button.baseConfiguration.imagePlacement {
        case .leading, .left:
            systemButton.configuration?.imagePlacement = .leading
        case .trailing, .right:
            systemButton.configuration?.imagePlacement = .trailing
        case .top:
            systemButton.configuration?.imagePlacement = .top
        case .bottom:
            systemButton.configuration?.imagePlacement = .bottom
        }
    }
    
    @IBAction func titleAlignmentSegmentAction(sender: UISegmentedControl) {
        button.baseConfiguration.titleAlignment = ButtonConfiguration.TitleAlignment(rawValue: sender.selectedSegmentIndex)!
        
        switch button.baseConfiguration.titleAlignment {
        case .automatic:
            systemButton.configuration?.titleAlignment = .automatic
        case .leading, .left:
            systemButton.configuration?.titleAlignment = .leading
        case .trailing, .right:
            systemButton.configuration?.titleAlignment = .trailing
        case .center:
            systemButton.configuration?.titleAlignment = .center
        }
    }
    
    @IBAction func contentHASegmentAction(sender: UISegmentedControl) {
        button.contentHorizontalAlignment =  UIControl.ContentHorizontalAlignment(rawValue: sender.selectedSegmentIndex)!
        
        systemButton.contentHorizontalAlignment = button.contentHorizontalAlignment
    }
    
    @IBAction func contentVASegmentAction(sender: UISegmentedControl) {
        button.contentVerticalAlignment =  UIControl.ContentVerticalAlignment(rawValue: sender.selectedSegmentIndex)!
        
        systemButton.contentVerticalAlignment = button.contentVerticalAlignment
    }
    
    @IBAction func imagePaddingTextChanged(sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Image Padding")
            return
        }
        
        button.baseConfiguration.imagePadding = CGFloat(truncating: number)
        
        systemButton.configuration?.imagePadding = button.baseConfiguration.imagePadding
    }
    
    @IBAction func titlePaddfingTextChanged(sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Title Padding")
            return
        }
        
        button.baseConfiguration.titlePadding = CGFloat(truncating: number)
        
        systemButton.configuration?.titlePadding = button.baseConfiguration.titlePadding
    }
    
    var latestImagePointSizeValue: CGFloat = 28
    @IBAction func imagePointSizeTextChanged(sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Image Point Size")
            return
        }
        
        latestImagePointSizeValue = CGFloat(truncating: number)
        let imageConfig = UIImage.SymbolConfiguration(pointSize: latestImagePointSizeValue)
        let image = UIImage(systemName: "house.circle.fill", withConfiguration: imageConfig)
        button.baseConfiguration.image = image
        
        systemButton.configuration?.image = image
        systemButton.configuration?.preferredSymbolConfigurationForImage = imageConfig
    }
    
    @IBAction func titleTextChanged(sender: UITextField) {
        button.baseConfiguration.title = sender.text
        
        systemButton.configuration?.title = sender.text
    }
    
    @IBAction func subtitleTextChanged(sender: UITextField) {
        button.baseConfiguration.subtitle = sender.text
        
        systemButton.configuration?.subtitle = sender.text
    }
    
    @IBAction func imageHiddenSwitchAction(sender: UISwitch) {
        button.baseConfiguration.image = !sender.isOn ? nil : UIImage(systemName: "house.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: latestImagePointSizeValue))
        
        systemButton.configuration?.image = button.baseConfiguration.image
        systemButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: latestImagePointSizeValue)
    }
    @IBAction func activityIndicatorHiddenSwitchAction(_ sender: UISwitch) {
        button.baseConfiguration.showsActivityIndicator = sender.isOn
        
        systemButton.configuration?.showsActivityIndicator = sender.isOn
    }
    
    var latestContentInsetsIsDirectional = true
    @IBAction func contentInsetsSegmentAction(sender: UISegmentedControl) {
        var updatedValue = button.baseConfiguration.contentInsets
        if sender.selectedSegmentIndex == 0 {
            if case .nondirectional(let insets) = button.baseConfiguration.contentInsets {
                updatedValue = .directional(NSDirectionalEdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right))
            }
            latestContentInsetsIsDirectional = true
        } else {
            if case .directional(let insets) = button.baseConfiguration.contentInsets {
                updatedValue = .nondirectional(UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
            }
            latestContentInsetsIsDirectional = false
        }
        button.baseConfiguration.contentInsets = updatedValue
    }
    
    @IBAction func contentInsetsTextChanged(sender: UITextField) {
        let values = (sender.text ?? "0,0,0,0").components(separatedBy: ",").compactMap { (value) -> CGFloat? in
            guard let number = NumberFormatter().number(from: value) else {
                return nil
            }
            return CGFloat(truncating: number)
        }
        
        guard values.count == 4 else {
            print("Wrong Content Insets")
            return
        }
        
        if latestContentInsetsIsDirectional {
            button.baseConfiguration.contentInsets = .directional(NSDirectionalEdgeInsets(top: values[0], leading: values[1], bottom: values[2], trailing: values[3]))
        } else {
            button.baseConfiguration.contentInsets = .nondirectional(UIEdgeInsets(top: values[0], left: values[1], bottom: values[2], right: values[3]))
        }
        
        systemButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: values[0], leading: values[1], bottom: values[2], trailing: values[3])
    }
    
    @IBAction func buttonWidthConstraintSwitchAction(_ sender: UISwitch) {
        buttonWidthConstraint.isActive = sender.isOn
        button.setNeedsUpdateConstraints()
        
        systemButtonWidthConstraint.isActive = sender.isOn
        systemButton.setNeedsUpdateConstraints()
    }
    
    @IBAction func buttonHeightConstraintSwitchAction(_ sender: UISwitch) {
        buttonHeightConstraint.isActive = sender.isOn
        button.setNeedsUpdateConstraints()
        
        systemButtonHeightConstraint.isActive = sender.isOn
        systemButton.setNeedsUpdateConstraints()
    }
    
    @IBAction func buttonWidthTextChanged(_ sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Button Width")
            return
        }
        buttonWidthConstraint.constant = CGFloat(truncating: number)
        button.setNeedsUpdateConstraints()
        
        systemButtonWidthConstraint.constant = buttonWidthConstraint.constant
        systemButton.setNeedsUpdateConstraints()
    }
    
    @IBAction func buttonHeightTextChanged(_ sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Button Height")
            return
        }
        buttonHeightConstraint.constant = CGFloat(truncating: number)
        button.setNeedsUpdateConstraints()
        
        systemButtonHeightConstraint.constant = buttonHeightConstraint.constant
        systemButton.setNeedsUpdateConstraints()
    }
    
    @IBAction func enabledSwitchAction(_ sender: UISwitch) {
        button.isEnabled = sender.isOn
        systemButton.isEnabled = sender.isOn
    }
    
    @objc
    private func buttonAction(sender: ConfigurationBasedButton) {
        self.view.endEditing(true)
    }

}
