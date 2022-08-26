//
//  ConfigurationBasedButton.swift
//  ConfigurationBasedButton
//
//  Created by 🌊 薛 on 2022/8/25.
//

import UIKit

public enum CornerStyle: Equatable {
    case fixed(CGFloat), capsule
}

public struct BackgroundConfiguration: Equatable {

    public var fillColor: UIColor?

    public var strokeColor: UIColor?
    
    public var strokeWidth: CGFloat = 0
    
    public var strokeOutset: CGFloat = 0
    
    public var cornerStyle: CornerStyle?
            
    public var visualEffect: UIVisualEffect?
    
    public var customView: UIView?
    
    public var image: UIImage?
    
    public var imageContentMode: UIView.ContentMode = .scaleToFill
    
    public init() {}
}

public class BackgroundView: UIView {
    
    private lazy var colorView: UIView = {
        let colorView = UIView()
        colorView.clipsToBounds = true
        return colorView
    }()
    
    private lazy var visualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.contentView.clipsToBounds = true
        return visualEffectView
    }()
        
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private weak var customView: UIView?

    private lazy var strokeView: UIView = {
        let strokeView = UIView()
        strokeView.clipsToBounds = true
        if #available(iOS 13.0, *) {
            strokeView.layer.cornerCurve = .continuous
        }
        return strokeView
    }()
    
    private var isDisplayingColorView: Bool {
        if configuration.visualEffect != nil {
            return false
        } else {
            return configuration.fillColor != nil
        }
    }
        
    private var isDisplayingVisualEffectView: Bool {
        configuration.visualEffect != nil
    }
    
    private var isDisplayingStrokeView: Bool {
        configuration.strokeColor != nil && configuration.strokeWidth > 0
    }
    
    private var isDisplayingImageView: Bool {
        configuration.image != nil
    }
    
    private var isDisplayingCustomView: Bool {
        configuration.customView != nil
    }
    
    public var configuration: BackgroundConfiguration {
        didSet {
            if configuration != oldValue {
                update()
            }
        }
    }
    
    public init(configuration: BackgroundConfiguration = BackgroundConfiguration()) {
        self.configuration = configuration
        super.init(frame: .zero)
        
        self.isUserInteractionEnabled = false
        
        update()
    }
        
    public required init?(coder aDecoder: NSCoder) {
        self.configuration = BackgroundConfiguration()
        super.init(coder: aDecoder)
        
        update()
    }
    
    public func update() {
        if isDisplayingColorView {
            colorView.backgroundColor = configuration.fillColor
            
            if !colorView.isDescendant(of: self) {
                addSubview(colorView)
            }
        } else {
            colorView.removeFromSuperview()
        }
        
        if isDisplayingVisualEffectView {
            visualEffectView.contentView.backgroundColor = configuration.fillColor
            visualEffectView.effect = configuration.visualEffect
            
            if !visualEffectView.isDescendant(of: self) {
                addSubview(visualEffectView)
            }
            bringSubviewToFront(visualEffectView)
        } else {
            visualEffectView.removeFromSuperview()
        }
        
        if isDisplayingImageView {
            imageView.contentMode = configuration.imageContentMode
            imageView.image = configuration.image
            if !imageView.isDescendant(of: self) {
                addSubview(imageView)
            }
            bringSubviewToFront(imageView)
        } else {
            imageView.removeFromSuperview()
        }
        
        if isDisplayingCustomView {
            customView = configuration.customView
            configuration.customView?.clipsToBounds = true
            if let customView = customView {
                if !customView.isDescendant(of: self) {
                    addSubview(customView)
                }
                bringSubviewToFront(customView)
            }
        } else {
            customView?.removeFromSuperview()
            customView = nil
        }
        
        if isDisplayingStrokeView {
            strokeView.layer.borderColor = configuration.strokeColor?.cgColor
            strokeView.layer.borderWidth = configuration.strokeWidth
            
            if !strokeView.isDescendant(of: self) {
                addSubview(strokeView)
            }
            bringSubviewToFront(strokeView)
        } else {
            strokeView.removeFromSuperview()
        }
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let isDisplayingColorView = self.isDisplayingColorView
        let isDisplayingVisualEffectView = self.isDisplayingVisualEffectView
        let isDisplayingStrokeView = self.isDisplayingStrokeView
  
        var cornerRadius: CGFloat = 0
        if let cornerStyle = configuration.cornerStyle {
            switch cornerStyle {
            case .fixed(let value):
                cornerRadius = value
            case .capsule:
                cornerRadius = bounds.height / 2.0
            }
        }
        
        if isDisplayingColorView {
            colorView.frame = bounds
            colorView.layer.cornerRadius = cornerRadius
        }
        
        if isDisplayingVisualEffectView {
            visualEffectView.frame = bounds
            visualEffectView.subviews.forEach { $0.layer.cornerRadius = cornerRadius }
        }
        
        if isDisplayingImageView {
            imageView.frame = bounds
            imageView.layer.cornerRadius = cornerRadius
        }
        
        if isDisplayingCustomView {
            customView?.frame = bounds
            customView?.layer.cornerRadius = cornerRadius
        }
        
        if isDisplayingStrokeView {
            let outset = configuration.strokeOutset
            strokeView.frame = bounds.inset(by: UIEdgeInsets(top: -outset, left: -outset, bottom: -outset, right: -outset))
            if cornerRadius > 0 {
                strokeView.layer.cornerRadius = cornerRadius + outset
            }
        }
        
    }
    
}
