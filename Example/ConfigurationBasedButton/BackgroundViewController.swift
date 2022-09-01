//
//  BackgroundViewController.swift
//  ConfigurationBasedButton_Example
//
//  Created by 🌊 薛 on 2022/8/26.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ConfigurationBasedButton

public class BackgroundViewController: UIViewController {
    @IBOutlet var button: UIButton!
    @IBOutlet weak var backgroundView: BackgroundView!
    
    let customView1 = UIImageView(image: UIImage(systemName: "circle"))
    let customView2 = UIImageView(image: UIImage(systemName: "circle"))
    
    let customView3 = UIImageView(image: UIImage(systemName: "circle"))
    let customView4 = UIImageView(image: UIImage(systemName: "circle"))
    
    let image = UIImage(systemName: "paperplane")
    let visualEffect = UIBlurEffect(style: .light)
    
    var apply: ((UIBackgroundConfiguration, BackgroundConfiguration) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Backrgound"
    
        
        let applyButtonBarItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(applyBackground))
        self.navigationItem.rightBarButtonItem = applyButtonBarItem
        
        customView1.contentMode = .scaleAspectFit
        customView2.contentMode = .scaleAspectFit
        
        let fillCollor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        let strokeColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        var configuration = UIButton.Configuration.plain()
        var bgConfiguration = UIBackgroundConfiguration.clear()
        bgConfiguration.backgroundColor = fillCollor
        bgConfiguration.strokeColor = strokeColor
        bgConfiguration.strokeWidth = 1
        bgConfiguration.customView = customView1
        bgConfiguration.image = image
        bgConfiguration.visualEffect = visualEffect
        bgConfiguration.imageContentMode = .scaleAspectFit
        
        configuration.background = bgConfiguration
        button.configuration = configuration
        
        var bgConfig = BackgroundConfiguration()
        bgConfig.fillColor = fillCollor
        bgConfig.strokeColor = strokeColor
        bgConfig.strokeWidth = 1
        bgConfig.customView = customView2
        bgConfig.image = image
        bgConfig.visualEffect = visualEffect
        bgConfig.imageContentMode = .scaleAspectFit

        backgroundView.backgroundColor = .clear
        backgroundView.configuration = bgConfig
        
    }
    
    @objc func applyBackground() {
        if var systemBg = button.configuration?.background {
            var bg = backgroundView.configuration
            
            if systemBg.customView != nil {
                systemBg.customView = customView3
            }
            
            if bg.customView != nil {
                bg.customView = customView4
            }
            
            apply?(systemBg, bg)
            
        }
        
        self.navigationController?.popViewController(animated: true)

    }
    
    enum ColorType {
        case fill
        case stroke
    }
    
    @IBAction func bgTapAction(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    private func changeColor(red: CGFloat? = nil, green: CGFloat? = nil, blue: CGFloat? = nil, alpha: CGFloat? = nil, for type: ColorType) {
        var updatedColor: UIColor?
        switch type {
        case .fill:
            updatedColor = backgroundView.configuration.fillColor
        case .stroke:
            updatedColor = backgroundView.configuration.strokeColor
        }
        
        if let color = updatedColor {
            var oRed: CGFloat = 0
            var oGreen: CGFloat = 0
            var oBlue: CGFloat = 0
            var oAlpha: CGFloat = 1
            color.getRed(&oRed, green: &oGreen, blue: &oBlue, alpha: &oAlpha)
            
            updatedColor = UIColor(red: red ?? oRed, green: green ?? oGreen, blue: blue ?? oBlue, alpha: alpha ?? oAlpha)
        } else {
            updatedColor = UIColor(red: red ?? 0, green: green ?? 0, blue: blue ?? 0, alpha: alpha ?? 1)
        }
        
        switch type {
        case .fill:
            backgroundView.configuration.fillColor = updatedColor
            button.configuration?.background.backgroundColor = updatedColor
        case .stroke:
            backgroundView.configuration.strokeColor = updatedColor
            button.configuration?.background.strokeColor = updatedColor
        }
    
    }
    
    @IBAction func fillRedSliderAction(_ sender: UISlider) {
        changeColor(red: CGFloat(sender.value), for: .fill)
    }
    
    @IBAction func fillGreenSliderAction(_ sender: UISlider) {
        changeColor(green: CGFloat(sender.value), for: .fill)
    }
    
    @IBAction func fillBlueSliderAction(_ sender: UISlider) {
        changeColor(blue: CGFloat(sender.value), for: .fill)
    }
    
    @IBAction func fillAlphaSliderAction(_ sender: UISlider) {
        changeColor(alpha: CGFloat(sender.value), for: .fill)
    }
    
    @IBAction func strokeRedSliderAction(_ sender: UISlider) {
        changeColor(red: CGFloat(sender.value), for: .stroke)
    }
    
    @IBAction func strokeGreenSliderAction(_ sender: UISlider) {
        changeColor(green: CGFloat(sender.value), for: .stroke)
    }
    
    @IBAction func strokeBlueSliderAction(_ sender: UISlider) {
        changeColor(blue: CGFloat(sender.value), for: .stroke)
    }
    
    @IBAction func strokeAlphaSliderAction(_ sender: UISlider) {
        changeColor(alpha: CGFloat(sender.value), for: .stroke)
    }
    
    @IBAction func strokeWidthTextChanged(_ sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Stroke Width")
            return
        }
        
        backgroundView.configuration.strokeWidth = CGFloat(truncating: number)
        button.configuration?.background.strokeWidth =  CGFloat(truncating: number)
    }
    
    @IBAction func strokeOutsetTextChanged(_ sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Stroke Outset")
            return
        }
        
        backgroundView.configuration.strokeOutset = CGFloat(truncating: number)
        button.configuration?.background.strokeOutset =  CGFloat(truncating: number)
    }
    
    private var cornerStyleSegIndex: Int = 0
    @IBAction func cornerStyleSegmentAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            backgroundView.configuration.cornerStyle = .fixed(fixedValue)
            button.configuration?.background.cornerRadius = fixedValue
    
            cornerStyleSegIndex = 0
        case 1:
            backgroundView.configuration.cornerStyle = .capsule
            button.configuration?.background.cornerRadius = 50
            
            cornerStyleSegIndex = 1
        default:
            break
        }
    }
    
    private var fixedValue: CGFloat = 0
    @IBAction func fixCornerRadiusValueChanged(_ sender: UITextField) {
        guard let number = NumberFormatter().number(from: sender.text ?? "0") else {
            print("Wrong Corner Outset")
            return
        }
        
        fixedValue = CGFloat(truncating: number)
        if (cornerStyleSegIndex == 0) {
            backgroundView.configuration.cornerStyle = .fixed(fixedValue)
            backgroundView.configuration.cornerStyle = .capsule
        }
    }
    
    @IBAction func visualEffectSwitchAction(_ sender: UISwitch) {
        backgroundView.configuration.visualEffect = sender.isOn ? visualEffect : nil
        button.configuration?.background.visualEffect = sender.isOn ? visualEffect : nil
    }
    
    @IBAction func customViewSwitchAction(_ sender: UISwitch) {
        backgroundView.configuration.customView = sender.isOn ? customView2 : nil
        button.configuration?.background.customView = sender.isOn ? customView1 : nil
    }
    
    @IBAction func imageSwitchAction(_ sender: UISwitch) {
        backgroundView.configuration.image = sender.isOn ? image : nil
        button.configuration?.background.image = sender.isOn ? image : nil
    }
}
