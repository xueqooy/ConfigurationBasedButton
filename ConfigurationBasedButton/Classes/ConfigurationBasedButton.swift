//
//  ConfigurationBasedButton.swift
//  ConfigurationBasedButton
//
//  Created by 🌊 薛 on 2022/8/25.
//

import UIKit

public enum EdgeInsets: Equatable {
    case directional(NSDirectionalEdgeInsets), nondirectional(UIEdgeInsets)
}

public struct ButtonConfiguration: Equatable {
    public enum ImagePlacement: Int, Equatable {
        case leading, trailing, top, left, bottom, right
    }
    
    public enum TitleAlignment: Int, Equatable {
        // Automatically adjust according to image placement
        case automatic
        case leading, center, trailing, left, right
    }
    
    public var image: UIImage?
    public var title: String?
    public var subtitle: String?
    
    public var imagePlacement: ButtonConfiguration.ImagePlacement = .leading
    public var titleAlignment: ButtonConfiguration.TitleAlignment = .automatic
    
    public var contentInsets: EdgeInsets = .directional(.zero)
    public var imagePadding: CGFloat = 0
    public var titlePadding: CGFloat = 0
    
//    var showsActivityIndicator: Bool = false
    public var background: BackgroundConfiguration?

    public init() {
    }
}

public class ConfigurationBasedButton: UIControl {
        
    public var configuration: ButtonConfiguration {
        didSet {
            if configuration != oldValue {
                update()
            }
        }
    }
    
    public override var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
        didSet {
            if contentVerticalAlignment != oldValue {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }
    
    public override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        didSet {
            if contentHorizontalAlignment != oldValue {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }
    
    public var shouldDisplayBackground: Bool {
        configuration.background != nil
    }
    
    public var shouldDisplayImage: Bool {
       configuration.image != nil
    }
    
    public var shouldDisplayTitle: Bool {
        !(configuration.title ?? "").isEmpty
    }
    
    public var shouldDisplaySubtitle: Bool {
        !(configuration.subtitle ?? "").isEmpty
    }
    
    public var effectiveImagePlacement: ButtonConfiguration.ImagePlacement {
        switch configuration.imagePlacement {
        case .leading:
            return isRTL ? .right : .left
        case .trailing:
            return isRTL ? .left : .right
        default:
            return configuration.imagePlacement
        }
    }
    
    public var effectiveTitleAlignment: ButtonConfiguration.TitleAlignment {
        switch configuration.titleAlignment {
        case .leading:
            return isRTL ? .right : .left
        case .trailing:
            return isRTL ? .left : .right
        case .automatic:
            if shouldDisplayImage {
                switch configuration.imagePlacement {
                case .leading:
                    return isRTL ? .right : .left
                case .trailing:
                    return isRTL ? .left : .right
                case .top, .bottom:
                    return .center
                case .left:
                    return .left
                case .right:
                    return .right
                }
            } else {
                return isRTL ? .right : .left
            }
        default:
            return configuration.titleAlignment
        }
    }
    
    public var effectiveContentInsets: UIEdgeInsets {
        switch configuration.contentInsets {
        case .directional(let insets):
            return UIEdgeInsets(top: insets.top, left: isRTL ? insets.trailing : insets.leading, bottom: insets.bottom, right: isRTL ? insets.leading : insets.trailing)
        case .nondirectional(let insets):
            return insets
        }
    }
    
    private var didAddBackgroundView = false
    private var didAddImageView = false
    private var didAddTitleView = false
    private var didAddSubtitleView = false
    
    private lazy var backgroundView: BackgroundView = {
        let backgroundView = BackgroundView()
        return backgroundView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.backgroundColor = .lightGray
        titleLabel.numberOfLines = 0
        return titleLabel
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.backgroundColor = .lightGray
        subtitleLabel.numberOfLines = 0
        return subtitleLabel
    }()
    
    private var isRTL: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    private var validFitSize: CGSize?
    
    public init(configuration: ButtonConfiguration = ButtonConfiguration()) {
        self.configuration = configuration
        super.init(frame: .zero)
        
        update()
    }
        
    public required init?(coder aDecoder: NSCoder) {
        self.configuration = ButtonConfiguration()
        super.init(coder: aDecoder)
        
        update()
    }
    
    private func update() {
        if shouldDisplayBackground {
            backgroundView.configuration = configuration.background ?? BackgroundConfiguration()
          
            if !backgroundView.isDescendant(of: self) {
                addSubview(backgroundView)
                didAddBackgroundView = true
            }
            sendSubviewToBack(backgroundView)
        } else if didAddBackgroundView {
            backgroundView.removeFromSuperview()
            didAddBackgroundView = false
        }
        
        var textAlignment: NSTextAlignment = .natural
        switch effectiveTitleAlignment {
        case .left:
            textAlignment = .left
        case .right:
            textAlignment = .right
        case .center:
            textAlignment = .center
        default: break
        }
        
        if shouldDisplayImage {
            imageView.image = configuration.image
           
            if !imageView.isDescendant(of: self) {
                addSubview(imageView)
                didAddImageView = true
            }
        } else if didAddImageView {
            imageView.image = nil
            imageView.removeFromSuperview()
            didAddImageView = false
        }
        
        if shouldDisplayTitle {
            titleLabel.text = configuration.title
            titleLabel.textAlignment = textAlignment
          
            if !titleLabel.isDescendant(of: self) {
                addSubview(titleLabel)
                didAddTitleView = true
            }
        } else if didAddTitleView {
            titleLabel.text = nil
            titleLabel.removeFromSuperview()
            didAddTitleView = false
        }
        
        if shouldDisplaySubtitle  {
            subtitleLabel.text = configuration.subtitle
            subtitleLabel.textAlignment = textAlignment

            if !subtitleLabel.isDescendant(of: self) {
                addSubview(subtitleLabel)
                didAddSubtitleView = true
            }
        } else if didAddSubtitleView {
            subtitleLabel.text = nil
            subtitleLabel.removeFromSuperview()
            didAddSubtitleView = false
        }
        
        validFitSize = nil
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundView.frame = bounds
        
        // layout priority: image -> title -> subtitle
                
        let effectiveImagePlacement = self.effectiveImagePlacement
        let effectiveTitleAlignment = self.effectiveTitleAlignment
        let effectiveContentInsets = self.effectiveContentInsets
        let effectiveContentHorizontalAlignment = self.effectiveContentHorizontalAlignment

        let contentSize = CGSize(width: bounds.width - effectiveContentInsets.left - effectiveContentInsets.right, height: bounds.height - effectiveContentInsets.top - effectiveContentInsets.bottom).eraseNegative()

        let shouldDisplayImage = self.shouldDisplayImage
        let shouldDisplayTitle = self.shouldDisplayTitle
        let shouldDisplaySubtitle = self.shouldDisplaySubtitle
    
        let imagePadding = shouldDisplayImage && (shouldDisplayTitle || shouldDisplaySubtitle) ? configuration.imagePadding : 0
        let titlePadding = shouldDisplayTitle && shouldDisplaySubtitle ? configuration.titlePadding : 0
                
        var imageFrame = CGRect.zero
        var titleFrame = CGRect.zero
        var subtitleFrame = CGRect.zero
        
        var imageLimitSize = CGSize.zero
        var titleLimitSize = CGSize.zero
        var subtitleLimitSize = CGSize.zero
        

        if shouldDisplayImage {
            imageLimitSize = contentSize
            imageFrame.size = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
        }
        
        switch effectiveImagePlacement {
        case .top, .bottom:
            if shouldDisplayTitle {
                titleLimitSize = CGSize(width: contentSize.width, height: contentSize.height - imageFrame.height - imagePadding).eraseNegative()
                titleFrame.size = titleLabel.sizeThatFits(titleLimitSize).limit(to: titleLimitSize)
            }
            if shouldDisplaySubtitle {
                subtitleLimitSize = CGSize(width: contentSize.width, height: contentSize.height - imageFrame.height - imagePadding - titleFrame.height - titlePadding).eraseNegative()
                subtitleFrame.size = subtitleLabel.sizeThatFits(subtitleLimitSize).limit(to: subtitleLimitSize)
            }

            switch effectiveContentHorizontalAlignment {
            case .left:
                let maxContentWidth = max(imageFrame.width, max(titleFrame.width, subtitleFrame.width))
                
                if shouldDisplayImage {
                    imageFrame.origin.x = effectiveContentInsets.left + (maxContentWidth - imageFrame.width) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = effectiveContentInsets.left + (maxContentWidth - titleFrame.width) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left + (maxContentWidth - subtitleFrame.width) / 2
                }
            case .center:
                if shouldDisplayImage {
                    imageFrame.origin.x = effectiveContentInsets.left + (imageLimitSize.width - imageFrame.width) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = effectiveContentInsets.left + (titleLimitSize.width - titleFrame.width) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left + (subtitleLimitSize.width - subtitleFrame.width) / 2
                }
            case .right:
                let maxContentWidth = max(imageFrame.width, max(titleFrame.width, subtitleFrame.width))

                if shouldDisplayImage {
                    imageFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width - (maxContentWidth - imageFrame.width) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = bounds.width - effectiveContentInsets.right - titleFrame.width - (maxContentWidth - titleFrame.width) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - subtitleFrame.width - (maxContentWidth - subtitleFrame.width) / 2
                }
            case .fill:
                if shouldDisplayImage {
                    imageFrame.origin.x = effectiveContentInsets.left
                    imageFrame.size.width = imageLimitSize.width
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = effectiveContentInsets.left
                    titleFrame.size.width = titleLimitSize.width
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left
                    subtitleFrame.size.width = subtitleLimitSize.width
                }
            default: break
            }
            
            if effectiveImagePlacement == .top {
                switch contentVerticalAlignment {
                case .top:
                    if shouldDisplayImage {
                        imageFrame.origin.y = effectiveContentInsets.top
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding + titleFrame.height + titlePadding
                    }
                case .center:
                    let contentHeight = imageFrame.height + imagePadding + titleFrame.height + titlePadding + subtitleFrame.height
                    let minY = effectiveContentInsets.top + (contentSize.height - contentHeight) / 2
                  
                    if shouldDisplayImage {
                        imageFrame.origin.y = minY
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = minY + imageFrame.height + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = minY + imageFrame.height + imagePadding + titleFrame.height + titlePadding
                    }
                case .bottom:
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height
                    }
                    if shouldDisplayImage {
                        imageFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height - imagePadding - imageFrame.height
                    }
                case .fill:
                    if shouldDisplayImage && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.y = effectiveContentInsets.top
                        if shouldDisplayTitle {
                            titleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding
                            if !shouldDisplaySubtitle {
                                titleFrame.size.height = max(bounds.height - titleFrame.minY - effectiveContentInsets.bottom, 0)
                            }
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    } else if shouldDisplayImage {
                        imageFrame.origin.y = effectiveContentInsets.top
                        imageFrame.size.height = contentSize.height
                    } else {
                        if shouldDisplayTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !shouldDisplaySubtitle {
                                titleFrame.size.height = contentSize.height
                            }
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    }
                default: break
                }
            } else {
                switch contentVerticalAlignment {
                case .top:
                    if shouldDisplayTitle {
                        titleFrame.origin.y = effectiveContentInsets.top
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                    }
                    if shouldDisplayImage {
                        imageFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding + subtitleFrame.height + imagePadding
                    }
                case .center:
                    let contentHeight = imageFrame.height + imagePadding + titleFrame.height + titlePadding + subtitleFrame.height
                    let minY = effectiveContentInsets.top + (contentSize.height - contentHeight) / 2
                  
                    if shouldDisplayTitle {
                        titleFrame.origin.y = minY
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = minY + titleFrame.height + titlePadding
                    }
                    if shouldDisplayImage {
                        imageFrame.origin.y = minY + titleFrame.height + titlePadding + subtitleFrame.height + imagePadding
                    }
                case .bottom:
                    if shouldDisplayImage {
                        imageFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height - imagePadding - subtitleFrame.height
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height - imagePadding - subtitleFrame.height - titlePadding - titleFrame.height
                    }
                case .fill:
                    if shouldDisplayImage && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.y = bounds.height - effectiveContentInsets.top - imageFrame.height
                        if shouldDisplayTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !shouldDisplaySubtitle {
                                titleFrame.size.height = max(bounds.height - titleFrame.minY - imagePadding - imageFrame.height - effectiveContentInsets.bottom, 0)
                            }
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - imagePadding - imageFrame.height - effectiveContentInsets.bottom, 0)
                        }
                    } else if shouldDisplayImage {
                        imageFrame.origin.y = effectiveContentInsets.top
                        imageFrame.size.height = contentSize.height
                    } else {
                        if shouldDisplayTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !shouldDisplaySubtitle {
                                titleFrame.size.height = contentSize.height
                            }
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    }
                default: break
                }
            }

        case .left, .right:
            if shouldDisplayTitle {
                titleLimitSize = CGSize(width: contentSize.width - imageFrame.width - imagePadding, height: contentSize.height).eraseNegative()
                titleFrame.size = titleLabel.sizeThatFits(titleLimitSize).limit(to: titleLimitSize)
            }
            if shouldDisplaySubtitle {
                subtitleLimitSize = CGSize(width: contentSize.width - imageFrame.width - imagePadding, height: contentSize.height - titleFrame.height - titlePadding).eraseNegative()
                subtitleFrame.size = subtitleLabel.sizeThatFits(subtitleLimitSize).limit(to: subtitleLimitSize)
            }
            
            switch contentVerticalAlignment {
            case .top:
                let titleTotalHeight = titleFrame.height + titlePadding + subtitleFrame.height
                let maxContentHeight = max(imageFrame.height, titleTotalHeight)
                
                if shouldDisplayImage {
                    imageFrame.origin.y = effectiveContentInsets.top + (maxContentHeight - imageFrame.height) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.y = effectiveContentInsets.top + (maxContentHeight - titleTotalHeight) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.y = effectiveContentInsets.top + (maxContentHeight - titleTotalHeight) / 2 + titleFrame.height + titlePadding
                }
            case .center:
                if shouldDisplayImage {
                    imageFrame.origin.y = effectiveContentInsets.top + (contentSize.height - imageFrame.height) / 2
                }
                
                let titleTotalHeight = titleFrame.height + titlePadding + subtitleFrame.height
                let minY = effectiveContentInsets.top + (contentSize.height - titleTotalHeight) / 2
            
                if shouldDisplayTitle {
                    titleFrame.origin.y = minY
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.y = minY + titleFrame.height + titlePadding
                }
            case .bottom:
                let titleTotalHeight = titleFrame.height + titlePadding + subtitleFrame.height
                let maxContentHeight = max(imageFrame.height, titleTotalHeight)
                
                if shouldDisplayImage {
                    imageFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height - (maxContentHeight - imageFrame.height) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - (maxContentHeight - titleTotalHeight) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height - (maxContentHeight - titleTotalHeight) / 2
                }
            case .fill:
                if shouldDisplayImage {
                    imageFrame.origin.y = effectiveContentInsets.top
                    imageFrame.size.height = contentSize.height
                }
                if shouldDisplayTitle {
                    titleFrame.origin.y = effectiveContentInsets.top
                    if !shouldDisplaySubtitle {
                        titleFrame.size.height = contentSize.height
                    }
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                    subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                }
            default: break
            }
            
            if effectiveImagePlacement == .left {
                switch effectiveContentHorizontalAlignment {
                case .left:
                    if shouldDisplayImage {
                        imageFrame.origin.x = effectiveContentInsets.left
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                    }
                case .center:
                    let contentWidth = imageFrame.width + imagePadding + max(titleFrame.width, subtitleFrame.width)
                    let minX = effectiveContentInsets.left + (contentSize.width - contentWidth) / 2
                    
                    if shouldDisplayImage {
                        imageFrame.origin.x = minX
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = minX + imageFrame.width + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = minX + imageFrame.width + imagePadding
                    }
                case .right:
                    if shouldDisplayImage {
                        imageFrame.origin.x = bounds.width - effectiveContentInsets.right - max(titleFrame.width, subtitleFrame.width) - imagePadding - imageFrame.width
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = bounds.width - effectiveContentInsets.right - titleFrame.width
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - subtitleFrame.width
                    }
                case .fill:
                    if shouldDisplayImage && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.x = effectiveContentInsets.left
                        if shouldDisplayTitle {
                            titleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                            titleFrame.size.width = contentSize.width - imagePadding - imageFrame.width
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                            subtitleFrame.size.width = contentSize.width - imagePadding - imageFrame.width
                        }
                    } else if shouldDisplayImage {
                        imageFrame.origin.x = effectiveContentInsets.left
                        imageFrame.size.width = contentSize.width
                    } else {
                        if shouldDisplayTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = contentSize.width
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left
                            subtitleFrame.size.width = contentSize.width
                        }
                    }
                default: break
                }
            } else {
                switch effectiveContentHorizontalAlignment {
                case .left:
                    if shouldDisplayTitle {
                        titleFrame.origin.x = effectiveContentInsets.left
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = effectiveContentInsets.left
                    }
                    if shouldDisplayImage {
                        imageFrame.origin.x = effectiveContentInsets.left + max(titleFrame.width, subtitleFrame.width) + imagePadding
                    }
                case .center:
                    let contentWidth = imageFrame.width + imagePadding + max(titleFrame.width, subtitleFrame.width)
                    let minX = effectiveContentInsets.left + (contentSize.width - contentWidth) / 2
                    
                    if shouldDisplayTitle {
                        titleFrame.origin.x = minX
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = minX
                    }
                    if shouldDisplayImage {
                        imageFrame.origin.x = minX + max(titleFrame.width, subtitleFrame.width) + imagePadding
                    }
                case .right:
                    if shouldDisplayImage {
                        imageFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width - imagePadding - titleFrame.width
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width - imagePadding - subtitleFrame.width
                    }
                case .fill:
                    if shouldDisplayImage && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width
                        if shouldDisplayTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = imageFrame.minX - imagePadding - titleFrame.minX
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left
                            subtitleFrame.size.width = imageFrame.minX - imagePadding - titleFrame.minX
                        }
                    } else if shouldDisplayImage {
                        imageFrame.origin.x = effectiveContentInsets.left
                        imageFrame.size.width = contentSize.width
                    } else {
                        if shouldDisplayTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = contentSize.width
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left
                            subtitleFrame.size.width = contentSize.width
                        }
                    }
                default: break
                }
            }
        default: break
        }

        // Adjust frame based on title alignment
        if shouldDisplayTitle && shouldDisplaySubtitle && titleFrame.width != subtitleFrame.width {
            let isSubtitleFrameUpdated: Bool
            let widerFrame: CGRect
            var updatedFrame: CGRect
            
            if titleFrame.width > subtitleFrame.width {
                isSubtitleFrameUpdated = true
                widerFrame = titleFrame
                updatedFrame = subtitleFrame
            } else {
                isSubtitleFrameUpdated = false
                widerFrame = subtitleFrame
                updatedFrame = titleFrame
            }
        
            switch effectiveTitleAlignment {
            case .left:
                updatedFrame.origin.x = widerFrame.origin.x
            case .center:
                updatedFrame.origin.x = widerFrame.midX - updatedFrame.width / 2
            case .right:
                updatedFrame.origin.x = widerFrame.maxX - updatedFrame.width
            default: break
            }
            
            if isSubtitleFrameUpdated {
                subtitleFrame = updatedFrame
            } else {
                titleFrame = updatedFrame
            }
        }
        
        
        if shouldDisplayImage {
            imageView.frame = imageFrame
        }
        if shouldDisplayTitle {
            titleLabel.frame = titleFrame
        }
        if shouldDisplaySubtitle {
            subtitleLabel.frame = subtitleFrame
        }
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
        invalidateIntrinsicContentSize()
    }

    private var isCallingSystemLayoutSizeFitting = false
    public override var intrinsicContentSize: CGSize {
        // TODO:
        
//        var limitWidth: CGFloat?
//        for constraint in constraintsAffectingLayout(for: .horizontal) {
//            if constraint.firstItem === self && constraint.firstAttribute == .width && NSStringFromClass(type(of: constraint)) != "NSContentSizeLayoutConstraint"  {
//                limitWidth = constraint.constant
//            }
//        }
//        
//        if let limitWidth = limitWidth {
//            return sizeThatFits(CGSize(width: limitWidth, height: .greatestFiniteMagnitude))
//        } else {
//            return sizeThatFits(.max)
//        }
        
        // Make instrinsic height adapt to constrained width.
        //
        // (1) If constrained width was set, call systemLayoutSizeFitting() can return the limit/constrained width, then use this width to calculate fit height (if the contrained height was not set, will use this height).
        // (2) If not set, system will use instrinsic width, call systemLayoutSizeFitting() return the fit width (is result of sizeThatFits(CGSize.max))
        
//        if isCallingSystemLayoutSizeFitting {
//            return sizeThatFits(CGSize.max)
//        }
//
//        isCallingSystemLayoutSizeFitting = true
//        var limitWidth = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
//        limitWidth = min(sizeThatFits(CGSize.max).width, limitWidth)
//        isCallingSystemLayoutSizeFitting = false
//
//        return sizeThatFits(CGSize(width: limitWidth, height: CGFloat.greatestFiniteMagnitude))
    }
    
    private var isFittingSize: Bool = false
    public override func sizeToFit() {
        isFittingSize = true
        super.sizeToFit()
        isFittingSize = false
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        var limitSize = size
        if bounds.size.equalTo(size) && isFittingSize { // Call sizeToFit(), always not limit size.
            limitSize = CGSize.max
        }
        
        // return cached size
        if let validFitSize = validFitSize, limitSize == CGSize.max {
            return validFitSize
        }
        
        var resultSize = CGSize.zero
        
        let shouldDisplayImage = self.shouldDisplayImage
        let shouldDisplayTitle = self.shouldDisplayTitle
        let shouldDisplaySubtitle = self.shouldDisplaySubtitle
        
        let imagePadding = shouldDisplayImage && (shouldDisplayTitle || shouldDisplaySubtitle) ? configuration.imagePadding : 0
        let titlePadding = shouldDisplayTitle && shouldDisplaySubtitle ? configuration.titlePadding : 0
        
        let horizontalInset: CGFloat
        let verticalInset: CGFloat
        
        switch configuration.contentInsets {
        case .directional(let insets):
            horizontalInset = insets.leading + insets.trailing
            verticalInset = insets.top + insets.bottom
        case .nondirectional(let insets):
            horizontalInset = insets.left + insets.right
            verticalInset = insets.top + insets.bottom
        }
        
        let contentLimitSize = CGSize(width: limitSize.width - horizontalInset, height: limitSize.height - verticalInset).eraseNegative()
        var imageSize = CGSize.zero
        var titleSize = CGSize.zero
        var subtitleSize = CGSize.zero
        
        switch configuration.imagePlacement {
        case .top, .bottom:
            if shouldDisplayImage {
                let imageLimitSize = CGSize(width: contentLimitSize.width, height: CGFloat.greatestFiniteMagnitude)
                imageSize = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
            }
            if shouldDisplayTitle {
                let titleLimitSize = CGSize(width: contentLimitSize.width, height: contentLimitSize.height - imageSize.height - imagePadding).eraseNegative()
                titleSize = titleLabel.sizeThatFits(titleLimitSize)
                titleSize.height = min(titleSize.height, titleLimitSize.height)
            }
            if shouldDisplaySubtitle {
                let subtitleLimitSize = CGSize(width: contentLimitSize.width, height: contentLimitSize.height - imageSize.height - imagePadding - titleSize.height - titlePadding).eraseNegative()
                subtitleSize = subtitleLabel.sizeThatFits(subtitleLimitSize)
                subtitleSize.height = min(subtitleSize.height, subtitleLimitSize.height)
            }
            resultSize.width = horizontalInset + max(imageSize.width, max(titleSize.width, subtitleSize.width))
            resultSize.height = verticalInset + imageSize.height + imagePadding + titleSize.height + titlePadding + subtitleSize.height
        case .left, .right, .leading, .trailing:
            if shouldDisplayImage {
                let imageLimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: contentLimitSize.height)
                imageSize = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
            }
            if shouldDisplayTitle {
                let titleLimitSize = CGSize(width: contentLimitSize.width - imageSize.width - imagePadding, height: contentLimitSize.height).eraseNegative()
                titleSize = titleLabel.sizeThatFits(titleLimitSize)
                titleSize.height = min(titleSize.height, titleLimitSize.height)
            }
            if shouldDisplaySubtitle {
                let subtitleLimitSize = CGSize(width: contentLimitSize.width - imageSize.width - imagePadding, height: contentLimitSize.height).eraseNegative()
                subtitleSize = subtitleLabel.sizeThatFits(subtitleLimitSize)
                subtitleSize.height = min(subtitleSize.height, subtitleLimitSize.height)
            }
            resultSize.width = horizontalInset + imageSize.width + imagePadding + max(titleSize.width, subtitleSize.width)
            resultSize.height = verticalInset + max(imageSize.height, titleSize.height + titlePadding + subtitleSize.height)
        }
        
        if limitSize == CGSize.max {
            validFitSize = resultSize
        }
        
        return resultSize
    }
}

private extension CGSize {
    static let max = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    
    func limit(to size: CGSize) -> CGSize {
        var result = self
        result.width = min(result.width, size.width)
        result.height = min(result.height, size.height)
        return result
    }
    
    func eraseNegative() -> CGSize {
        var result = self
        result.width = Swift.max(result.width, 0)
        result.height = Swift.max(result.height, 0)
        return result
    }
}
