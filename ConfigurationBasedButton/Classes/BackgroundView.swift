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

public struct BackgroundConfiguration {
    /// Configures the color of the background
    public var fillColor: UIColor?
    /// Configures the color of the stroke. A nil value uses the view's tint color.
    public var strokeColor: UIColor?
    /// The width of the stroke. Default is 0.
    public var strokeWidth: CGFloat = 0
    /// Outset (or inset, if negative) for the stroke. Default is 0.
    /// The corner radius of the stroke is adjusted for any outset to remain concentric with the background.
    public var strokeOutset: CGFloat = 0
    /// The corner style for the background and stroke. This is also applied to the custom view. Default is .fixed(0).
    public var cornerStyle: CornerStyle?
    /// The visual effect to apply to the background. Default is nil.
    public var visualEffect: UIVisualEffect?
    /// A custom view for the background.
    public var customView: UIView?
    /// The image to use. Default is nil.
    public var image: UIImage?
    /// The content mode to use when rendering the image. Default is UIViewContentModeScaleToFill.
    public var imageContentMode: UIView.ContentMode = .scaleToFill
    
    public init() {}
}

extension BackgroundConfiguration: Equatable {}

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
        return strokeView
    }()
    
    private var didAddColorView: Bool = false
    private var didAddVisualEffectView: Bool = false
    private var didAddStrokeView: Bool = false
    private var didAddImageView: Bool = false
    
    private var shouldDisplayColorView: Bool {
        if configuration.visualEffect != nil {
            return false
        } else {
            return configuration.fillColor != nil
        }
    }
        
    private var shouldDisplayVisualEffectView: Bool {
        configuration.visualEffect != nil
    }
    
    private var shouldDisplayStrokeView: Bool {
        configuration.strokeWidth > 0
    }
    
    private var shouldDisplayImageView: Bool {
        configuration.image != nil
    }
    
    private var shouldDisplayCustomView: Bool {
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
        if shouldDisplayColorView {
            colorView.backgroundColor = configuration.fillColor
            
            if !colorView.isDescendant(of: self) {
                addSubview(colorView)
                didAddColorView = true
            }
            sendSubviewToBack(colorView)
        } else if didAddColorView {
            colorView.removeFromSuperview()
            didAddColorView = false
        }
        
        if shouldDisplayVisualEffectView {
            visualEffectView.contentView.backgroundColor = configuration.fillColor
            visualEffectView.effect = configuration.visualEffect
            
            if !visualEffectView.isDescendant(of: self) {
                addSubview(visualEffectView)
                didAddVisualEffectView = true
            }
            bringSubviewToFront(visualEffectView)
        } else if didAddVisualEffectView {
            visualEffectView.removeFromSuperview()
            didAddVisualEffectView = false
        }
        
        if shouldDisplayImageView {
            imageView.contentMode = configuration.imageContentMode
            imageView.image = configuration.image
           
            if !imageView.isDescendant(of: self) {
                addSubview(imageView)
                didAddImageView = true
            }
            bringSubviewToFront(imageView)
        } else if didAddImageView {
            imageView.removeFromSuperview()
            didAddImageView = false
        }
        
        if shouldDisplayCustomView {
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
        
        if shouldDisplayStrokeView {
            strokeView.layer.borderColor = configuration.strokeColor?.cgColor ?? self.tintColor.cgColor
            strokeView.layer.borderWidth = configuration.strokeWidth
            
            if !strokeView.isDescendant(of: self) {
                addSubview(strokeView)
                didAddStrokeView = true
            }
            bringSubviewToFront(strokeView)
        } else if didAddStrokeView {
            strokeView.removeFromSuperview()
            didAddStrokeView = false
        }
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    
        var cornerRadius: CGFloat = 0
        if let cornerStyle = configuration.cornerStyle {
            switch cornerStyle {
            case .fixed(let value):
                cornerRadius = value
            case .capsule:
                cornerRadius = min(bounds.height, bounds.width) / 2.0
            }
        }
        
        if shouldDisplayColorView {
            colorView.frame = bounds
            colorView.layer.cornerRadius = cornerRadius
        }
        
        if shouldDisplayVisualEffectView {
            visualEffectView.frame = bounds
            visualEffectView.subviews.forEach { $0.layer.cornerRadius = cornerRadius }
        }
        
        if shouldDisplayStrokeView {
            imageView.frame = bounds
            imageView.layer.cornerRadius = cornerRadius
        }
        
        if shouldDisplayCustomView {
            customView?.frame = bounds
            customView?.layer.cornerRadius = cornerRadius
        }
        
        if shouldDisplayStrokeView {
            let outset = configuration.strokeOutset
            strokeView.frame = bounds.inset(by: UIEdgeInsets(top: -outset, left: -outset, bottom: -outset, right: -outset))
            if cornerRadius > 0 {
                strokeView.layer.cornerRadius = cornerRadius + outset
            }
        }
    }
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        
        if shouldDisplayStrokeView && configuration.strokeColor == nil {
            strokeView.layer.borderColor = self.tintColor.cgColor
        }
    }
    
}
