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
    /// Defines which of the four corners receives the masking when using cornerStyle
    public var stylishCorners: UIRectCorner = .allCorners
    /// The visual effect to apply to the background. Default is nil.
    public var visualEffect: UIVisualEffect?
    /// A custom view for the background.
    public var customView: UIView?
    /// The image to use. Default is nil.
    public var image: UIImage?
    /// The content mode to use when rendering the image. Default is UIViewContentModeScaleToFill.
    public var imageContentMode: UIView.ContentMode = .scaleToFill
    /// offset in user space of the shadow
    public var shadowOffset: CGSize = .zero
    /// blur radius of the shadow in default user space units
    public var shadowBlurRadius: CGFloat = 3
    /// color used for the shadow
    public var shadowColor: UIColor?
    
    public init() {}
}

extension BackgroundConfiguration: Equatable {}

public class BackgroundView: UIView {
    
    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.isUserInteractionEnabled = false
        return shadowView
    }()
    
    private lazy var colorView: UIView = {
        let colorView = UIView()
        colorView.isUserInteractionEnabled = false
        colorView.clipsToBounds = true
        return colorView
    }()
    
    private lazy var visualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.isUserInteractionEnabled = false
        visualEffectView.contentView.clipsToBounds = true
        return visualEffectView
    }()
        
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private weak var customView: UIView?

    private lazy var strokeView: UIView = {
        let strokeView = UIView()
        strokeView.isUserInteractionEnabled = false
        strokeView.clipsToBounds = true
        return strokeView
    }()
    
    private var didAddShadowView: Bool = false
    private var didAddColorView: Bool = false
    private var didAddVisualEffectView: Bool = false
    private var didAddStrokeView: Bool = false
    private var didAddImageView: Bool = false
    
    private var shouldDisplayShadowView: Bool {
        configuration.shadowColor != nil
    }
    
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
                layout()
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    
        layout()
    }
    
    public override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        
        if shouldDisplayCustomView && configuration.customView == subview {
            assertionFailure("The configured customView cannot be removed, please use 'self.configuration.customView = nil' instead")
        }
    }
    
    private func update() {
        if shouldDisplayShadowView {
            shadowView.layer.shadowColor = configuration.shadowColor?.cgColor
            shadowView.layer.shadowOffset = configuration.shadowOffset
            shadowView.layer.shadowRadius = configuration.shadowBlurRadius
            shadowView.layer.shadowOpacity = 1
        }
        
        if shouldDisplayColorView {
            colorView.backgroundColor = configuration.fillColor
        }
        
        if shouldDisplayVisualEffectView {
            visualEffectView.contentView.backgroundColor = configuration.fillColor
            visualEffectView.effect = configuration.visualEffect
        }
        
        if shouldDisplayImageView {
            imageView.contentMode = configuration.imageContentMode
            imageView.image = configuration.image
        }
        
        if shouldDisplayCustomView {
            customView = configuration.customView
            configuration.customView?.clipsToBounds = true
        }
        
        if shouldDisplayStrokeView {
            strokeView.layer.borderColor = configuration.strokeColor?.cgColor ?? self.tintColor.cgColor
            strokeView.layer.borderWidth = configuration.strokeWidth
        }
    }
    
    private func layout() {
        
        var cornerRadius: CGFloat = 0
        if let cornerStyle = configuration.cornerStyle {
            switch cornerStyle {
            case .fixed(let value):
                cornerRadius = value
            case .capsule:
                cornerRadius = min(bounds.height, bounds.width) / 2.0
            }
        }
        
        let maskedCorner = configuration.stylishCorners.maskedCorners
        
        if shouldDisplayShadowView {
            shadowView.frame = bounds
            shadowView.layer.shadowPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: configuration.stylishCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
            
            if !shadowView.isDescendant(of: self) {
                addSubview(shadowView)
                didAddShadowView = true
            }
        } else if didAddShadowView {
            shadowView.removeFromSuperview()
            didAddShadowView = false
        }
        
        if shouldDisplayColorView {
            colorView.frame = bounds
            colorView.layer.cornerRadius = cornerRadius
            colorView.layer.maskedCorners = maskedCorner
            
            if !colorView.isDescendant(of: self) {
                addSubview(colorView)
                didAddColorView = true
            }
            bringSubviewToFront(colorView)
        } else if didAddColorView {
            colorView.removeFromSuperview()
            didAddColorView = false
        }
        
        if shouldDisplayVisualEffectView {
            visualEffectView.frame = bounds
            visualEffectView.subviews.forEach {
                $0.layer.cornerRadius = cornerRadius
                $0.layer.maskedCorners = maskedCorner
            }
            
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
            imageView.frame = bounds
            imageView.layer.cornerRadius = cornerRadius
            imageView.layer.maskedCorners = maskedCorner
            
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
            customView?.frame = bounds
            customView?.layer.cornerRadius = cornerRadius
            customView?.layer.maskedCorners = maskedCorner
            
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
            let outset = configuration.strokeOutset
            strokeView.frame = bounds.inset(by: UIEdgeInsets(top: -outset, left: -outset, bottom: -outset, right: -outset))
            if cornerRadius > 0 {
                strokeView.layer.cornerRadius = cornerRadius + outset
                strokeView.layer.maskedCorners = maskedCorner
            }
            
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
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        
        if shouldDisplayStrokeView && configuration.strokeColor == nil {
            strokeView.layer.borderColor = self.tintColor.cgColor
        }
    }
    
}


extension UIRectCorner {
    var maskedCorners: CACornerMask {
        var corners: CACornerMask = []
        if self.contains(.topLeft) {
            corners.insert(.layerMinXMinYCorner)
        }
        if self.contains(.topRight) {
            corners.insert(.layerMaxXMinYCorner)
        }
        if self.contains(.bottomLeft) {
            corners.insert(.layerMinXMaxYCorner)
        }
        if self.contains(.bottomRight) {
            corners.insert(.layerMaxXMaxYCorner)
        }
        return corners
    }
}
