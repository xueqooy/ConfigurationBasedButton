//
//  ConfigurationBasedButtonViewController.swift
//  FontPractice
//
//  Created by 🌊 薛 on 2022/8/25.
//

import UIKit
import ConfigurationBasedButton

class ConfigurationBasedButtonViewController: UIViewController {
    
    @IBOutlet weak var systemButton: UIButton!
    @IBOutlet var systemButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var systemButtonHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet private var button: ConfigurationBasedButton! 
    @IBOutlet var buttonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var buttonHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var configuration = button.configuration
        configuration.title = "This's title"
        configuration.subtitle = "This's subtitle"
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 28)
        let image = UIImage(systemName: "house.circle.fill", withConfiguration: imageConfig)
        configuration.image = image
        
        button.configuration = configuration
        
        button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        
        var systemButtonConfiguration = UIButton.Configuration.plain()
        systemButtonConfiguration.title = "This's title"
        systemButtonConfiguration.subtitle = "This's subtitle"
        systemButtonConfiguration.image = image
        systemButtonConfiguration.preferredSymbolConfigurationForImage = imageConfig
        systemButtonConfiguration.contentInsets = NSDirectionalEdgeInsets.zero
        systemButton.configuration = systemButtonConfiguration
    }
    
    @IBAction func imagePlacementSegmentAction(sender: UISegmentedControl) {
        button.configuration.imagePlacement = ButtonConfiguration.ImagePlacement(rawValue: sender.selectedSegmentIndex)!
        
        switch button.configuration.imagePlacement {
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
        button.configuration.titleAlignment = ButtonConfiguration.TitleAlignment(rawValue: sender.selectedSegmentIndex)!
        
        switch button.configuration.titleAlignment {
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
        
        button.configuration.imagePadding = CGFloat(truncating: number)
        
        systemButton.configuration?.imagePadding = button.configuration.imagePadding
    }
    
    @IBAction func titlePaddfingTextChanged(sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Title Padding")
            return
        }
        
        button.configuration.titlePadding = CGFloat(truncating: number)
        
        systemButton.configuration?.titlePadding = button.configuration.titlePadding
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
        button.configuration.image = image
        
        systemButton.configuration?.image = image
        systemButton.configuration?.preferredSymbolConfigurationForImage = imageConfig
    }
    
    @IBAction func titleTextChanged(sender: UITextField) {
        button.configuration.title = sender.text
        
        systemButton.configuration?.title = sender.text
    }
    
    @IBAction func subtitleTextChanged(sender: UITextField) {
        button.configuration.subtitle = sender.text
        
        systemButton.configuration?.subtitle = sender.text
    }
    
    @IBAction func imageHiddenSwitchAction(sender: UISwitch) {
        button.configuration.image = sender.isOn ? nil : UIImage(systemName: "house.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: latestImagePointSizeValue))
        
        systemButton.configuration?.image = button.configuration.image
        systemButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: latestImagePointSizeValue)
    }
    
    var latestContentInsetsIsDirectional = true
    @IBAction func contentInsetsSegmentAction(sender: UISegmentedControl) {
        var updatedValue = button.configuration.contentInsets
        if sender.selectedSegmentIndex == 0 {
            if case .nondirectional(let insets) = button.configuration.contentInsets {
                updatedValue = .directional(NSDirectionalEdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right))
            }
            latestContentInsetsIsDirectional = true
        } else {
            if case .directional(let insets) = button.configuration.contentInsets {
                updatedValue = .nondirectional(UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
            }
            latestContentInsetsIsDirectional = false
        }
        button.configuration.contentInsets = updatedValue
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
            button.configuration.contentInsets = .directional(NSDirectionalEdgeInsets(top: values[0], leading: values[1], bottom: values[2], trailing: values[3]))
        } else {
            button.configuration.contentInsets = .nondirectional(UIEdgeInsets(top: values[0], left: values[1], bottom: values[2], right: values[3]))
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
    
    @objc
    private func buttonAction(sender: ConfigurationBasedButton) {
        self.view.endEditing(true)
    }

}
