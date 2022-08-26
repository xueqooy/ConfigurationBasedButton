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
    
    public var isDisplayingImage: Bool {
       configuration.image != nil
    }
    
    public var isDisplayingTitle: Bool {
        !(configuration.title ?? "").isEmpty
    }
    
    public var isDisplayingSubtitle: Bool {
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
            if isDisplayingImage {
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
        
        if isDisplayingImage {
            imageView.image = configuration.image
            if !imageView.isDescendant(of: self) {
                addSubview(imageView)
            }
        } else {
            imageView.image = nil
            imageView.removeFromSuperview()
        }
        
        if isDisplayingTitle {
            titleLabel.text = configuration.title
            titleLabel.textAlignment = textAlignment
            
            if !titleLabel.isDescendant(of: self) {
                addSubview(titleLabel)
            }
        } else {
            titleLabel.text = nil
            titleLabel.removeFromSuperview()
        }
        
        if isDisplayingSubtitle  {
            subtitleLabel.text = configuration.subtitle
            subtitleLabel.textAlignment = textAlignment

            if !subtitleLabel.isDescendant(of: self) {
                addSubview(subtitleLabel)
            }
        } else {
            subtitleLabel.text = nil
            subtitleLabel.removeFromSuperview()
        }
        
        invalidateIntrinsicContentSize()
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // layout priority: image -> title -> subtitle
                
        let effectiveImagePlacement = self.effectiveImagePlacement
        let effectiveTitleAlignment = self.effectiveTitleAlignment
        let effectiveContentInsets = self.effectiveContentInsets
        let effectiveContentHorizontalAlignment = self.effectiveContentHorizontalAlignment

        let contentSize = CGSize(width: bounds.width - effectiveContentInsets.left - effectiveContentInsets.right, height: bounds.height - effectiveContentInsets.top - effectiveContentInsets.bottom).eraseNegative()

        let isDisplayingImage = self.isDisplayingImage
        let isDisplayingTitle = self.isDisplayingTitle
        let isDisplayingSubtitle = self.isDisplayingSubtitle
    
        let imagePadding = isDisplayingImage && (isDisplayingTitle || isDisplayingSubtitle) ? configuration.imagePadding : 0
        let titlePadding = isDisplayingTitle && isDisplayingSubtitle ? configuration.titlePadding : 0
                
        var imageFrame = CGRect.zero
        var titleFrame = CGRect.zero
        var subtitleFrame = CGRect.zero
        
        var imageLimitSize = CGSize.zero
        var titleLimitSize = CGSize.zero
        var subtitleLimitSize = CGSize.zero
        

        if isDisplayingImage {
            imageLimitSize = contentSize
            imageFrame.size = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
        }
        
        switch effectiveImagePlacement {
        case .top, .bottom:
            if isDisplayingTitle {
                titleLimitSize = CGSize(width: contentSize.width, height: contentSize.height - imageFrame.height - imagePadding).eraseNegative()
                titleFrame.size = titleLabel.sizeThatFits(titleLimitSize).limit(to: titleLimitSize)
            }
            if isDisplayingSubtitle {
                subtitleLimitSize = CGSize(width: contentSize.width, height: contentSize.height - imageFrame.height - imagePadding - titleFrame.height - titlePadding).eraseNegative()
                subtitleFrame.size = subtitleLabel.sizeThatFits(subtitleLimitSize).limit(to: subtitleLimitSize)
            }

            switch effectiveContentHorizontalAlignment {
            case .left:
                if isDisplayingImage {
                    imageFrame.origin.x = effectiveContentInsets.left
                }
                if isDisplayingTitle {
                    titleFrame.origin.x = effectiveContentInsets.left
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left
                }
            case .center:
                if isDisplayingImage {
                    imageFrame.origin.x = effectiveContentInsets.left + (imageLimitSize.width - imageFrame.width) / 2
                }
                if isDisplayingTitle {
                    titleFrame.origin.x = effectiveContentInsets.left + (titleLimitSize.width - titleFrame.width) / 2
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left + (subtitleLimitSize.width - subtitleFrame.width) / 2
                }
            case .right:
                if isDisplayingImage {
                    imageFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width
                }
                if isDisplayingTitle {
                    titleFrame.origin.x = bounds.width - effectiveContentInsets.right - titleFrame.width
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - subtitleFrame.width
                }
            case .fill:
                if isDisplayingImage {
                    imageFrame.origin.x = effectiveContentInsets.left
                    imageFrame.size.width = imageLimitSize.width
                }
                if isDisplayingTitle {
                    titleFrame.origin.x = effectiveContentInsets.left
                    titleFrame.size.width = titleLimitSize.width
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left
                    subtitleFrame.size.width = subtitleLimitSize.width
                }
            default: break
            }
            
            if effectiveImagePlacement == .top {
                switch contentVerticalAlignment {
                case .top:
                    if isDisplayingImage {
                        imageFrame.origin.y = effectiveContentInsets.top
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding + titleFrame.height + titlePadding
                    }
                case .center:
                    let contentHeight = imageFrame.height + imagePadding + titleFrame.height + titlePadding + subtitleFrame.height
                    let minY = effectiveContentInsets.top + (contentSize.height - contentHeight) / 2
                  
                    if isDisplayingImage {
                        imageFrame.origin.y = minY
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.y = minY + imageFrame.height + imagePadding
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.y = minY + imageFrame.height + imagePadding + titleFrame.height + titlePadding
                    }
                case .bottom:
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height
                    }
                    if isDisplayingImage {
                        imageFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height - imagePadding - imageFrame.height
                    }
                case .fill:
                    if isDisplayingImage && (isDisplayingTitle || isDisplayingSubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.y = effectiveContentInsets.top
                        if isDisplayingTitle {
                            titleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding
                            if !isDisplayingSubtitle {
                                titleFrame.size.height = max(bounds.height - titleFrame.minY - effectiveContentInsets.bottom, 0)
                            }
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + imageFrame.height + imagePadding + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    } else if isDisplayingImage {
                        imageFrame.origin.y = effectiveContentInsets.top
                        imageFrame.size.height = contentSize.height
                    } else {
                        if isDisplayingTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !isDisplayingSubtitle {
                                titleFrame.size.height = contentSize.height
                            }
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    }
                default: break
                }
            } else {
                switch contentVerticalAlignment {
                case .top:
                    if isDisplayingTitle {
                        titleFrame.origin.y = effectiveContentInsets.top
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                    }
                    if isDisplayingImage {
                        imageFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding + subtitleFrame.height + imagePadding
                    }
                case .center:
                    let contentHeight = imageFrame.height + imagePadding + titleFrame.height + titlePadding + subtitleFrame.height
                    let minY = effectiveContentInsets.top + (contentSize.height - contentHeight) / 2
                  
                    if isDisplayingTitle {
                        titleFrame.origin.y = minY
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.y = minY + titleFrame.height + titlePadding
                    }
                    if isDisplayingImage {
                        imageFrame.origin.y = minY + titleFrame.height + titlePadding + subtitleFrame.height + imagePadding
                    }
                case .bottom:
                    if isDisplayingImage {
                        imageFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height - imagePadding - subtitleFrame.height
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height - imagePadding - subtitleFrame.height - titlePadding - titleFrame.height
                    }
                case .fill:
                    if isDisplayingImage && (isDisplayingTitle || isDisplayingSubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.y = bounds.height - effectiveContentInsets.top - imageFrame.height
                        if isDisplayingTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !isDisplayingSubtitle {
                                titleFrame.size.height = max(bounds.height - titleFrame.minY - imagePadding - imageFrame.height - effectiveContentInsets.bottom, 0)
                            }
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - imagePadding - imageFrame.height - effectiveContentInsets.bottom, 0)
                        }
                    } else if isDisplayingImage {
                        imageFrame.origin.y = effectiveContentInsets.top
                        imageFrame.size.height = contentSize.height
                    } else {
                        if isDisplayingTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !isDisplayingSubtitle {
                                titleFrame.size.height = contentSize.height
                            }
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    }
                default: break
                }
            }

        case .left, .right:
            if isDisplayingTitle {
                titleLimitSize = CGSize(width: contentSize.width - imageFrame.width - imagePadding, height: contentSize.height).eraseNegative()
                titleFrame.size = titleLabel.sizeThatFits(titleLimitSize).limit(to: titleLimitSize)
            }
            if isDisplayingSubtitle {
                subtitleLimitSize = CGSize(width: contentSize.width - imageFrame.width - imagePadding, height: contentSize.height - titleFrame.height - titlePadding).eraseNegative()
                subtitleFrame.size = subtitleLabel.sizeThatFits(subtitleLimitSize).limit(to: subtitleLimitSize)
            }
            
            switch contentVerticalAlignment {
            case .top:
                if isDisplayingImage {
                    imageFrame.origin.y = effectiveContentInsets.top
                }
                if isDisplayingTitle {
                    titleFrame.origin.y = effectiveContentInsets.top
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                }
            case .center:
                if isDisplayingImage {
                    imageFrame.origin.y = effectiveContentInsets.top + (contentSize.height - imageFrame.height) / 2
                }
                
                let titleTotalHeight = titleFrame.height + titlePadding + subtitleFrame.height
                let minY = effectiveContentInsets.top + (contentSize.height - titleTotalHeight) / 2
            
                if isDisplayingTitle {
                    titleFrame.origin.y = minY
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.y = minY + titleFrame.height + titlePadding
                }
            case .bottom:
                if isDisplayingImage {
                    imageFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageFrame.height
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height
                }
                if isDisplayingTitle {
                    titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height
                }
            case .fill:
                if isDisplayingImage {
                    imageFrame.origin.y = effectiveContentInsets.top
                    imageFrame.size.height = contentSize.height
                }
                if isDisplayingTitle {
                    titleFrame.origin.y = effectiveContentInsets.top
                    if !isDisplayingSubtitle {
                        titleFrame.size.height = contentSize.height
                    }
                }
                if isDisplayingSubtitle {
                    subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                    subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                }
            default: break
            }
            
            if effectiveImagePlacement == .left {
                switch effectiveContentHorizontalAlignment {
                case .left:
                    if isDisplayingImage {
                        imageFrame.origin.x = effectiveContentInsets.left
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                    }
                case .center:
                    let contentWidth = imageFrame.width + imagePadding + max(titleFrame.width, subtitleFrame.width)
                    let minX = effectiveContentInsets.left + (contentSize.width - contentWidth) / 2
                    
                    if isDisplayingImage {
                        imageFrame.origin.x = minX
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.x = minX + imageFrame.width + imagePadding
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.x = minX + imageFrame.width + imagePadding
                    }
                case .right:
                    if isDisplayingImage {
                        imageFrame.origin.x = bounds.width - effectiveContentInsets.right - max(titleFrame.width, subtitleFrame.width) - imagePadding - imageFrame.width
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.x = bounds.width - effectiveContentInsets.right - titleFrame.width
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - subtitleFrame.width
                    }
                case .fill:
                    if isDisplayingImage && (isDisplayingTitle || isDisplayingSubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.x = effectiveContentInsets.left
                        if isDisplayingTitle {
                            titleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                            titleFrame.size.width = contentSize.width - imagePadding - imageFrame.width
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left + imageFrame.width + imagePadding
                            subtitleFrame.size.width = contentSize.width - imagePadding - imageFrame.width
                        }
                    } else if isDisplayingImage {
                        imageFrame.origin.x = effectiveContentInsets.left
                        imageFrame.size.width = contentSize.width
                    } else {
                        if isDisplayingTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = contentSize.width
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left
                            subtitleFrame.size.width = contentSize.width
                        }
                    }
                default: break
                }
            } else {
                switch effectiveContentHorizontalAlignment {
                case .left:
                    if isDisplayingTitle {
                        titleFrame.origin.x = effectiveContentInsets.left
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.x = effectiveContentInsets.left
                    }
                    if isDisplayingImage {
                        imageFrame.origin.x = effectiveContentInsets.left + max(titleFrame.width, subtitleFrame.width) + imagePadding
                    }
                case .center:
                    let contentWidth = imageFrame.width + imagePadding + max(titleFrame.width, subtitleFrame.width)
                    let minX = effectiveContentInsets.left + (contentSize.width - contentWidth) / 2
                    
                    if isDisplayingTitle {
                        titleFrame.origin.x = minX
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.x = minX
                    }
                    if isDisplayingImage {
                        imageFrame.origin.x = minX + max(titleFrame.width, subtitleFrame.width) + imagePadding
                    }
                case .right:
                    if isDisplayingImage {
                        imageFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width
                    }
                    if isDisplayingTitle {
                        titleFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width - imagePadding - titleFrame.width
                    }
                    if isDisplayingSubtitle {
                        subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width - imagePadding - subtitleFrame.width
                    }
                case .fill:
                    if isDisplayingImage && (isDisplayingTitle || isDisplayingSubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageFrame.origin.x = bounds.width - effectiveContentInsets.right - imageFrame.width
                        if isDisplayingTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = imageFrame.minX - imagePadding - titleFrame.minX
                        }
                        if isDisplayingSubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left
                            subtitleFrame.size.width = imageFrame.minX - imagePadding - titleFrame.minX
                        }
                    } else if isDisplayingImage {
                        imageFrame.origin.x = effectiveContentInsets.left
                        imageFrame.size.width = contentSize.width
                    } else {
                        if isDisplayingTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = contentSize.width
                        }
                        if isDisplayingSubtitle {
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
        if isDisplayingTitle && isDisplayingSubtitle && titleFrame.width != subtitleFrame.width {
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
        
        
        if isDisplayingImage {
            imageView.frame = imageFrame
        }
        if isDisplayingTitle {
            titleLabel.frame = titleFrame
        }
        if isDisplayingSubtitle {
            subtitleLabel.frame = subtitleFrame
        }
    }
    
    public override func updateConstraints() {
        invalidateIntrinsicContentSize()
        super.updateConstraints()
    }

    private var isCallingSystemLayoutSizeFitting = false
    public override var intrinsicContentSize: CGSize {
        // Make instrinsic height adapt to constrained width.
        //
        // (1) If constrained width was set, call systemLayoutSizeFitting() can return the limit/constrained width, then use this width to calculate fit height (if the contrained height was not set, will use this height).
        // (2) If not set, system will use instrinsic width, call systemLayoutSizeFitting() return the fit width (is result of sizeThatFits(CGSize.max))
        
        if isCallingSystemLayoutSizeFitting {
            return sizeThatFits(CGSize.max)
        }
        
        isCallingSystemLayoutSizeFitting = true
        let size = super.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        isCallingSystemLayoutSizeFitting = false
        
        return sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
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
        
        var resultSize = CGSize.zero
        
        let isDisplayingImage = self.isDisplayingImage
        let isDisplayingTitle = self.isDisplayingTitle
        let isDisplayingSubtitle = self.isDisplayingSubtitle
        
        let imagePadding = isDisplayingImage && (isDisplayingTitle || isDisplayingSubtitle) ? configuration.imagePadding : 0
        let titlePadding = isDisplayingTitle && isDisplayingSubtitle ? configuration.titlePadding : 0
        
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
            if isDisplayingImage {
                let imageLimitSize = CGSize(width: contentLimitSize.width, height: CGFloat.greatestFiniteMagnitude)
                imageSize = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
            }
            if isDisplayingTitle {
                let titleLimitSize = CGSize(width: contentLimitSize.width, height: contentLimitSize.height - imageSize.height - imagePadding).eraseNegative()
                titleSize = titleLabel.sizeThatFits(titleLimitSize)
                titleSize.height = min(titleSize.height, titleLimitSize.height)
            }
            if isDisplayingSubtitle {
                let subtitleLimitSize = CGSize(width: contentLimitSize.width, height: contentLimitSize.height - imageSize.height - imagePadding - titleSize.height - titlePadding).eraseNegative()
                subtitleSize = subtitleLabel.sizeThatFits(subtitleLimitSize)
                subtitleSize.height = min(subtitleSize.height, subtitleLimitSize.height)
            }
            resultSize.width = horizontalInset + max(imageSize.width, max(titleSize.width, subtitleSize.width))
            resultSize.height = verticalInset + imageSize.height + imagePadding + titleSize.height + titlePadding + subtitleSize.height
        case .left, .right, .leading, .trailing:
            if isDisplayingImage {
                let imageLimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: contentLimitSize.height)
                imageSize = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
            }
            if isDisplayingTitle {
                let titleLimitSize = CGSize(width: contentLimitSize.width - imageSize.width - imagePadding, height: contentLimitSize.height).eraseNegative()
                titleSize = titleLabel.sizeThatFits(titleLimitSize)
                titleSize.height = min(titleSize.height, titleLimitSize.height)
            }
            if isDisplayingSubtitle {
                let subtitleLimitSize = CGSize(width: contentLimitSize.width - imageSize.width - imagePadding, height: contentLimitSize.height).eraseNegative()
                subtitleSize = subtitleLabel.sizeThatFits(subtitleLimitSize)
                subtitleSize.height = min(subtitleSize.height, subtitleLimitSize.height)
            }
            resultSize.width = horizontalInset + imageSize.width + imagePadding + max(titleSize.width, subtitleSize.width)
            resultSize.height = verticalInset + max(imageSize.height, titleSize.height + titlePadding + subtitleSize.height)
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
