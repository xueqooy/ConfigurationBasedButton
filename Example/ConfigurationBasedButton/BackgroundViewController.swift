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
    
    public override func viewDidLoad() {
        let imageView1 = UIImageView(image: UIImage(systemName: "house.circle.fill"))
        imageView1.clipsToBounds = false
        let imageView2 = UIImageView(image: UIImage(systemName: "house.circle.fill"))
        imageView2.clipsToBounds = false

        var configuration = UIButton.Configuration.plain()
        var bgConfiguration = UIBackgroundConfiguration.clear()
        bgConfiguration.backgroundColor = UIColor.cyan
        bgConfiguration.strokeColor = UIColor.orange
        bgConfiguration.strokeWidth = 1
        bgConfiguration.strokeOutset = 5
        bgConfiguration.customView = imageView1
        bgConfiguration.image = UIImage(systemName: "house.circle.fill")
        bgConfiguration.visualEffect = UIBlurEffect(style: .light)
        bgConfiguration.cornerRadius = 20
        
        configuration.background = bgConfiguration
        button.configuration = configuration
        
        var bgConfig = BackgroundConfiguration()
        bgConfig.fillColor = UIColor.cyan
        bgConfig.strokeColor = UIColor.orange
        bgConfig.strokeWidth = 1
        bgConfig.strokeOutset = 5
        bgConfig.customView = imageView2
        bgConfig.image = UIImage(systemName: "house.circle.fill")
        bgConfig.visualEffect = UIBlurEffect(style: .light)
        bgConfig.cornerStyle = .fixed(20)

        backgroundView.configuration = bgConfig
    }
}
