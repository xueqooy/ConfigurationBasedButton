//
//  ConfigurationBasedButton.swift
//  ConfigurationBasedButton
//
//  Created by 🌊 薛 on 2022/8/25.
//

import UIKit


public protocol ButtonActivityIndicatorType: UIView {
    var indicatorColor: UIColor? { get set }
    
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: ButtonActivityIndicatorType {
    public var indicatorColor: UIColor? {
        get {
            color
        }
        set {
            color = newValue
        }
    }
}

public enum EdgeInsets {
    case directional(NSDirectionalEdgeInsets), nondirectional(UIEdgeInsets)
}

extension EdgeInsets: Equatable {}


public struct ButtonConfiguration {
    public enum ImagePlacement: Int, Equatable {
        case leading, trailing, top, left, bottom, right
    }
    
    public enum TitleAlignment: Int, Equatable {
        /// Align title & subtitle automatically based on ImagePlacement
        case automatic
        case leading, center, trailing, left, right
    }
    
    public var image: UIImage?

    public var title: String?
    public var titleFont: UIFont?
    public var titleColor: UIColor?
    public var attributedTitle: NSAttributedString?
    
    public var subtitle: String?
    public var subtitleFont: UIFont?
    public var subtitleColor: UIColor?
    public var attributedSubtitle: NSAttributedString?
    
    /// Shows an activity indicator in place of an image. Its placement is controlled by `imagePlacement` .
    public var showsActivityIndicator: Bool = false

    /// Defaults to Leading.
    public var imagePlacement: ButtonConfiguration.ImagePlacement = .leading
    /// The alignment to use for relative layout between title & subtitle.
    public var titleAlignment: ButtonConfiguration.TitleAlignment = .automatic
    
    /// Insets from the bounds of the button to create the content region.
    public var contentInsets: EdgeInsets = .directional(.zero)
    /// When a button has both image and text content, this value is the padding between the image and the text.
    public var imagePadding: CGFloat = 0
    /// When a button has both a title & subtitle, this value is the padding between those titles.
    public var titlePadding: CGFloat = 0
        
    /// A BackgroundConfiguration describing the button's background.
    public var background: BackgroundConfiguration? = BackgroundConfiguration()
    
    /// The base color to use for foreground elements.
    public var foregroundColor: UIColor?

    public init() {
    }
}

extension ButtonConfiguration: Equatable {}


/// The type that provide effective configuration for button.
public protocol ButtonConfigurationProviderType {
    func configuration(for button: ConfigurationBasedButton) -> ButtonConfiguration
}

/// Apply extra transparency on configuration's colors based on the state(normal, disabled, highlighted).
open class PlainButtonConfigurationProvider: ButtonConfigurationProviderType {
    
    public enum State {
        case normal, disabled, highlighted
        
        static func state(from button: ConfigurationBasedButton) -> State {
            if !button.isEnabled {
                return .disabled
            } else if button.isHighlighted {
                return .highlighted
            }
            return .normal
        }
    }
    
    private var latestBaseConfiguration: ButtonConfiguration? {
        didSet {
            if latestBaseConfiguration != oldValue {
                normalConfiguration = nil
                disabledConfiguration = nil
                highlightedConfiguration = nil
            }
        }
    }
    
    // Cache values for states.
    
    private var normalConfiguration: ButtonConfiguration?
    private var disabledConfiguration: ButtonConfiguration?
    private var highlightedConfiguration: ButtonConfiguration?

    public init() {
    }
    
    private func configuration(for state: State) -> ButtonConfiguration? {
        switch state {
        case .normal:
            return normalConfiguration
        case .disabled:
            return disabledConfiguration
        case .highlighted:
            return highlightedConfiguration
        }
    }
    
    private func set(configuration: ButtonConfiguration, for state: State) {
        switch state {
        case .normal:
             normalConfiguration = configuration
        case .disabled:
             disabledConfiguration = configuration
        case .highlighted:
             highlightedConfiguration = configuration
        }
    }
    
    open func configuration(for button: ConfigurationBasedButton) -> ButtonConfiguration {
        self.latestBaseConfiguration = button.baseConfiguration
        
        let state = State.state(from: button)
        if let configuration = configuration(for: state) {
            return configuration
        }
    
        var configuration = button.baseConfiguration
      
        update(&configuration, for: button)
        set(configuration: configuration, for: state)
        
        return configuration
    }

    /// Subclasses can override this function to return the extra transparency in different states.
    open func overlayAlpha(for state: State) -> CGFloat? {
        switch state {
        case .normal:
            return nil
        case .disabled:
            return 0.5
        case .highlighted:
            return 0.75
        }
    }
    
    open func update(_ configuration: inout ButtonConfiguration, for button: ConfigurationBasedButton) {
        let state = State.state(from: button)
        if let overlayAlpha = overlayAlpha(for: state) {
            if let forgroundColor = configuration.foregroundColor ?? button.tintColor {
                configuration.foregroundColor = forgroundColor.withOverlayAlpha(overlayAlpha)
            }
            
            if let titleColor = configuration.titleColor {
                configuration.titleColor = titleColor.withOverlayAlpha(overlayAlpha)
            }
            
            if let subtitleColor = configuration.subtitleColor {
                configuration.subtitleColor = subtitleColor.withOverlayAlpha(overlayAlpha)
            }
            
            if let backgroundFillColor = configuration.background?.fillColor {
                configuration.background?.fillColor = backgroundFillColor.withOverlayAlpha(overlayAlpha)
            }
            
            if let backgroundStrokeColor = configuration.background?.strokeColor {
                configuration.background?.strokeColor = backgroundStrokeColor.withOverlayAlpha(overlayAlpha)
            }
        }
        
        if state != .normal && configuration.background?.shadowColor != nil {
            configuration.background?.shadowColor = nil
        }
    }
}


open class ConfigurationBasedButton: UIControl {
    /// The base configuration.
    /// It's not used to represent the current UI state of the button, but the effective configuration is.
    open var baseConfiguration: ButtonConfiguration {
        didSet {
            if baseConfiguration != oldValue {
                setNeedsUpdateConfiguration()
            }
        }
    }
    /// The provider of effective configuration.
    /// If value is nil, always use base configuration as effective  configuration.
    open var configurationProvider: ButtonConfigurationProviderType? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    /// The convenience for `touchUpInside` action.
    open var touchUpInsideAction: ((ConfigurationBasedButton) -> Void)?

    public init(baseConfiguration: ButtonConfiguration = ButtonConfiguration(), configurationProvider: ButtonConfigurationProviderType? = PlainButtonConfigurationProvider(), touchUpInsideAction: ((ConfigurationBasedButton) -> Void)? = nil) {
        self.baseConfiguration = baseConfiguration
        self.effectiveConfiguration =  baseConfiguration
        self.configurationProvider = configurationProvider
        self.touchUpInsideAction = touchUpInsideAction
        
        super.init(frame: .zero)

        addTarget(self, action: #selector(touchUpInsideTriggered), for: .touchUpInside)
        
        setNeedsUpdateConfiguration()
    }
        
    public required init?(coder aDecoder: NSCoder) {
        let configuration = ButtonConfiguration()
        self.baseConfiguration = configuration
        self.effectiveConfiguration = configuration
        self.configurationProvider = PlainButtonConfigurationProvider()
        super.init(coder: aDecoder)
        
        addTarget(self, action: #selector(touchUpInsideTriggered), for: .touchUpInside)
        
        setNeedsUpdateConfiguration()
    }
    
    @objc private func touchUpInsideTriggered() {
        touchUpInsideAction?(self)
    }
    
    
    // MARK: - Update
    
    // The configuration that represent the current UI state of the button.
    open private(set) var effectiveConfiguration: ButtonConfiguration {
        didSet {
            guard effectiveConfiguration != oldValue else {
                return
            }
            
            if effectiveConfiguration.image != oldValue.image ||
                effectiveConfiguration.title != oldValue.title ||
                effectiveConfiguration.titleFont != oldValue.titleFont ||
                effectiveConfiguration.attributedTitle != oldValue.attributedTitle ||
                effectiveConfiguration.subtitle != oldValue.subtitle ||
                effectiveConfiguration.subtitleFont != oldValue.subtitleFont ||
                effectiveConfiguration.attributedSubtitle != oldValue.attributedSubtitle ||
                effectiveConfiguration.showsActivityIndicator != oldValue.showsActivityIndicator ||
                effectiveConfiguration.contentInsets != oldValue.contentInsets ||
                effectiveConfiguration.imagePlacement != oldValue.imagePlacement ||
                effectiveConfiguration.titleAlignment != oldValue.titleAlignment ||
                effectiveConfiguration.contentInsets != oldValue.contentInsets ||
                effectiveConfiguration.imagePadding != oldValue.imagePadding ||
                effectiveConfiguration.titlePadding != oldValue.titlePadding {
                
                updateForeground()
                layoutForeground()
            }
            
            if effectiveConfiguration.background != oldValue.background {
                updateBackground()
                layoutBackground()
            }
            
            if effectiveConfiguration.foregroundColor != oldValue.foregroundColor ||
                effectiveConfiguration.titleColor != oldValue.titleColor ||
                effectiveConfiguration.subtitleColor != oldValue.subtitleColor {
                updateForegroundColors()
            }
        }
    }
    
    private lazy var updateTransaction = ButtonConfigurationUpdateTransaction { [weak self] in
        guard let self = self else { return }
        
        if self.needsUpdateConfiguration {
            self.updateConfiguration()
        }
    }
    
    private var needsUpdateConfiguration: Bool = false
    
    /// Requests the view update its configuration for its current state. This method is called automatically when the button's state may have changed, as well as in other circumstances where an update may be required. Multiple requests may be coalesced into a single update at the appropriate time.
    open func setNeedsUpdateConfiguration() {
        needsUpdateConfiguration = true
        
        updateTransaction.commit()
    }
    
    /// Update button's `effectiveConfiguration`,  this method should not be called directly, use `setNeedsUpdateConfiguration` to request an update.
    open func updateConfiguration() {
        effectiveConfiguration = configurationProvider?.configuration(for: self) ?? baseConfiguration
        needsUpdateConfiguration = false
    }
    
    private func updateBackground() {
        if shouldDisplayBackground {
            backgroundView.configuration = effectiveConfiguration.background ?? BackgroundConfiguration()
        }
    }
    
    /// Update foreground elements, except for color.
    private func updateForeground() {
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
            imageView.image = effectiveConfiguration.image
        }
        
        if shouldDisplayActivityIndicator {
            activityIndicatorView.startAnimating()
        }
        
        if shouldDisplayTitle {
            if let attributedTitle = effectiveConfiguration.attributedTitle {
                titleLabel.attributedText = attributedTitle
            } else if let title = effectiveConfiguration.title {
                titleLabel.text = title
            }
            titleLabel.font = effectiveConfiguration.titleFont ?? .preferredFont(forTextStyle: .headline)
            titleLabel.textAlignment = textAlignment
        }
        
        if shouldDisplaySubtitle  {
            if let attributedSubtitle = effectiveConfiguration.attributedSubtitle {
                subtitleLabel.attributedText = attributedSubtitle
            } else if let subtitle = effectiveConfiguration.subtitle {
                subtitleLabel.text = subtitle
            }
            subtitleLabel.font = effectiveConfiguration.subtitleFont ?? .preferredFont(forTextStyle: .subheadline)
            subtitleLabel.textAlignment = textAlignment
        }
    }
    
    /// Update color of foreground elements.
    private func updateForegroundColors() {
        let theColor: UIColor = effectiveConfiguration.foregroundColor ?? tintColor
      
        if shouldDisplayImage {
            imageView.tintColor = theColor
        }
        if shouldDisplayActivityIndicator {
            activityIndicatorView.indicatorColor = theColor
        }
        if shouldDisplayTitle {
            titleLabel.textColor = effectiveConfiguration.titleColor ?? theColor
        }
        if shouldDisplaySubtitle {
            subtitleLabel.textColor = effectiveConfiguration.subtitleColor ?? theColor
        }
    }
    
    
    // MARK: - Layout
    
    // Determine the actual layout parameters based on configuration.
        
    private var shouldDisplayBackground: Bool {
        effectiveConfiguration.background != nil
    }
    
    private var shouldDisplayImage: Bool {
        effectiveConfiguration.showsActivityIndicator ? false : effectiveConfiguration.image != nil
    }
    
    private var shouldDisplayActivityIndicator: Bool {
        effectiveConfiguration.showsActivityIndicator
    }
    
    private var shouldDisplayTitle: Bool {
        if let attributedTitle = effectiveConfiguration.attributedTitle {
            return attributedTitle.length > 0
        }
        if let title = effectiveConfiguration.title{
            return !title.isEmpty
        }
        return false
    }
    private var shouldDisplaySubtitle: Bool {
        if let attributedSubtitle = effectiveConfiguration.attributedSubtitle, attributedSubtitle.length > 0 {
            return true
        }
        if let subtitle = effectiveConfiguration.subtitle, !subtitle.isEmpty {
            return true
        }
        return false
    }
    
    private var effectiveImagePlacement: ButtonConfiguration.ImagePlacement {
        switch effectiveConfiguration.imagePlacement {
        case .leading:
            return layoutDirectionIsRTL ? .right : .left
        case .trailing:
            return layoutDirectionIsRTL ? .left : .right
        default:
            return effectiveConfiguration.imagePlacement
        }
    }
    
    private var effectiveTitleAlignment: ButtonConfiguration.TitleAlignment {
        switch effectiveConfiguration.titleAlignment {
        case .leading:
            return layoutDirectionIsRTL ? .right : .left
        case .trailing:
            return layoutDirectionIsRTL ? .left : .right
        case .automatic:
            if shouldDisplayImage {
                switch effectiveConfiguration.imagePlacement {
                case .leading:
                    return layoutDirectionIsRTL ? .right : .left
                case .trailing:
                    return layoutDirectionIsRTL ? .left : .right
                case .top, .bottom:
                    return .center
                case .left:
                    return .left
                case .right:
                    return .right
                }
            } else {
                return layoutDirectionIsRTL ? .right : .left
            }
        default:
            return effectiveConfiguration.titleAlignment
        }
    }
    
    private var effectiveContentInsets: UIEdgeInsets {
        switch effectiveConfiguration.contentInsets {
        case .directional(let insets):
            return UIEdgeInsets(top: insets.top, left: layoutDirectionIsRTL ? insets.trailing : insets.leading, bottom: insets.bottom, right: layoutDirectionIsRTL ? insets.leading : insets.trailing)
        case .nondirectional(let insets):
            return insets
        }
    }
    
    private var layoutDirectionIsRTL: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    
    private var didAddBackgroundView = false
    private var didAddImageView = false
    private var didAddTitleView = false
    private var didAddSubtitleView = false
    private var didAddActivityIndicatorView = false
    
    private func layoutBackground() {
        if shouldDisplayBackground {
            self.backgroundView.frame = bounds
          
            if !backgroundView.isDescendant(of: self) {
                addSubview(backgroundView)
                didAddBackgroundView = true
            }
            sendSubviewToBack(backgroundView)
        } else if didAddBackgroundView {
            backgroundView.removeFromSuperview()
            didAddBackgroundView = false
        }
    }
    
    private func layoutForeground() {
        if shouldDisplayImage {
            if !imageView.isDescendant(of: self) {
                addSubview(imageView)
            }
            didAddImageView = true
        } else if didAddImageView {
            imageView.removeFromSuperview()
            didAddImageView = false
        }
        
        if shouldDisplayActivityIndicator {
            if !activityIndicatorView.isDescendant(of: self) {
                addSubview(activityIndicatorView)
            }
            didAddActivityIndicatorView = true
        } else if didAddActivityIndicatorView {
            activityIndicatorView.stopAnimating()
            activityIndicatorView.removeFromSuperview()
            didAddActivityIndicatorView = false
        }
        
        if shouldDisplayTitle {
            if !titleLabel.isDescendant(of: self) {
                addSubview(titleLabel)
            }
            didAddTitleView = true
        } else if didAddTitleView {
            titleLabel.removeFromSuperview()
            didAddTitleView = false
        }
        
        if shouldDisplaySubtitle  {
            if !subtitleLabel.isDescendant(of: self) {
                addSubview(subtitleLabel)
            }
            didAddSubtitleView = true
        } else if didAddSubtitleView {
            subtitleLabel.removeFromSuperview()
            didAddSubtitleView = false
        }
        
        // layout priority: image/activityIndicator -> title -> subtitle
                
        let effectiveImagePlacement = self.effectiveImagePlacement
        let effectiveTitleAlignment = self.effectiveTitleAlignment
        let effectiveContentInsets = self.effectiveContentInsets
        let effectiveContentHorizontalAlignment = self.effectiveContentHorizontalAlignment

        let contentSize = CGSize(width: bounds.width - effectiveContentInsets.left - effectiveContentInsets.right, height: bounds.height - effectiveContentInsets.top - effectiveContentInsets.bottom).eraseNegative()

        let shouldDisplayActivityIndicator = self.shouldDisplayActivityIndicator
        let shouldDisplayImage = self.shouldDisplayImage
        let shouldDisplayImageOrActivityIndicator = shouldDisplayActivityIndicator || shouldDisplayImage
        let shouldDisplayTitle = self.shouldDisplayTitle
        let shouldDisplaySubtitle = self.shouldDisplaySubtitle
    
        let imagePadding = shouldDisplayImageOrActivityIndicator && (shouldDisplayTitle || shouldDisplaySubtitle) ? effectiveConfiguration.imagePadding : 0
        let titlePadding = shouldDisplayTitle && shouldDisplaySubtitle ? effectiveConfiguration.titlePadding : 0
                
        var imageOrActivityIndicatorFrame = CGRect.zero
        var titleFrame = CGRect.zero
        var subtitleFrame = CGRect.zero
        
        var imageLimitSize = CGSize.zero
        var titleLimitSize = CGSize.zero
        var subtitleLimitSize = CGSize.zero
        
        imageLimitSize = contentSize
        if shouldDisplayActivityIndicator {
            imageOrActivityIndicatorFrame.size = activityIndicatorView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
        } else if shouldDisplayImage {
            imageOrActivityIndicatorFrame.size = imageView.sizeThatFits(imageLimitSize).limit(to: imageLimitSize)
        }
        
        switch effectiveImagePlacement {
        case .top, .bottom:
            if shouldDisplayTitle {
                titleLimitSize = CGSize(width: contentSize.width, height: contentSize.height - imageOrActivityIndicatorFrame.height - imagePadding).eraseNegative()
                titleFrame.size = titleLabel.sizeThatFits(titleLimitSize).limit(to: titleLimitSize)
            }
            if shouldDisplaySubtitle {
                subtitleLimitSize = CGSize(width: contentSize.width, height: contentSize.height - imageOrActivityIndicatorFrame.height - imagePadding - titleFrame.height - titlePadding).eraseNegative()
                subtitleFrame.size = subtitleLabel.sizeThatFits(subtitleLimitSize).limit(to: subtitleLimitSize)
            }

            switch effectiveContentHorizontalAlignment {
            case .left:
                let maxContentWidth = max(imageOrActivityIndicatorFrame.width, max(titleFrame.width, subtitleFrame.width))
                
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left + (maxContentWidth - imageOrActivityIndicatorFrame.width) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = effectiveContentInsets.left + (maxContentWidth - titleFrame.width) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left + (maxContentWidth - subtitleFrame.width) / 2
                }
            case .center:
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left + (imageLimitSize.width - imageOrActivityIndicatorFrame.width) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = effectiveContentInsets.left + (titleLimitSize.width - titleFrame.width) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = effectiveContentInsets.left + (subtitleLimitSize.width - subtitleFrame.width) / 2
                }
            case .right:
                let maxContentWidth = max(imageOrActivityIndicatorFrame.width, max(titleFrame.width, subtitleFrame.width))

                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.x = bounds.width - effectiveContentInsets.right - imageOrActivityIndicatorFrame.width - (maxContentWidth - imageOrActivityIndicatorFrame.width) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.x = bounds.width - effectiveContentInsets.right - titleFrame.width - (maxContentWidth - titleFrame.width) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - subtitleFrame.width - (maxContentWidth - subtitleFrame.width) / 2
                }
            case .fill:
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left
                    imageOrActivityIndicatorFrame.size.width = imageLimitSize.width
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
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = effectiveContentInsets.top + imageOrActivityIndicatorFrame.height + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = effectiveContentInsets.top + imageOrActivityIndicatorFrame.height + imagePadding + titleFrame.height + titlePadding
                    }
                case .center:
                    let contentHeight = imageOrActivityIndicatorFrame.height + imagePadding + titleFrame.height + titlePadding + subtitleFrame.height
                    let minY = effectiveContentInsets.top + (contentSize.height - contentHeight) / 2
                  
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = minY
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = minY + imageOrActivityIndicatorFrame.height + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = minY + imageOrActivityIndicatorFrame.height + imagePadding + titleFrame.height + titlePadding
                    }
                case .bottom:
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height
                    }
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height - imagePadding - imageOrActivityIndicatorFrame.height
                    }
                case .fill:
                    if shouldDisplayImageOrActivityIndicator && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top
                        if shouldDisplayTitle {
                            titleFrame.origin.y = effectiveContentInsets.top + imageOrActivityIndicatorFrame.height + imagePadding
                            if !shouldDisplaySubtitle {
                                titleFrame.size.height = max(bounds.height - titleFrame.minY - effectiveContentInsets.bottom, 0)
                            }
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + imageOrActivityIndicatorFrame.height + imagePadding + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - effectiveContentInsets.bottom, 0)
                        }
                    } else if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top
                        imageOrActivityIndicatorFrame.size.height = contentSize.height
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
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding + subtitleFrame.height + imagePadding
                    }
                case .center:
                    let contentHeight = imageOrActivityIndicatorFrame.height + imagePadding + titleFrame.height + titlePadding + subtitleFrame.height
                    let minY = effectiveContentInsets.top + (contentSize.height - contentHeight) / 2
                  
                    if shouldDisplayTitle {
                        titleFrame.origin.y = minY
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = minY + titleFrame.height + titlePadding
                    }
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = minY + titleFrame.height + titlePadding + subtitleFrame.height + imagePadding
                    }
                case .bottom:
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageOrActivityIndicatorFrame.height
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageOrActivityIndicatorFrame.height - imagePadding - subtitleFrame.height
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageOrActivityIndicatorFrame.height - imagePadding - subtitleFrame.height - titlePadding - titleFrame.height
                    }
                case .fill:
                    if shouldDisplayImageOrActivityIndicator && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageOrActivityIndicatorFrame.origin.y = bounds.height - effectiveContentInsets.top - imageOrActivityIndicatorFrame.height
                        if shouldDisplayTitle {
                            titleFrame.origin.y = effectiveContentInsets.top
                            if !shouldDisplaySubtitle {
                                titleFrame.size.height = max(bounds.height - titleFrame.minY - imagePadding - imageOrActivityIndicatorFrame.height - effectiveContentInsets.bottom, 0)
                            }
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.y = effectiveContentInsets.top + titleFrame.height + titlePadding
                            subtitleFrame.size.height = max(bounds.height - subtitleFrame.minY - imagePadding - imageOrActivityIndicatorFrame.height - effectiveContentInsets.bottom, 0)
                        }
                    } else if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top
                        imageOrActivityIndicatorFrame.size.height = contentSize.height
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
                titleLimitSize = CGSize(width: contentSize.width - imageOrActivityIndicatorFrame.width - imagePadding, height: contentSize.height).eraseNegative()
                titleFrame.size = titleLabel.sizeThatFits(titleLimitSize).limit(to: titleLimitSize)
            }
            if shouldDisplaySubtitle {
                subtitleLimitSize = CGSize(width: contentSize.width - imageOrActivityIndicatorFrame.width - imagePadding, height: contentSize.height - titleFrame.height - titlePadding).eraseNegative()
                subtitleFrame.size = subtitleLabel.sizeThatFits(subtitleLimitSize).limit(to: subtitleLimitSize)
            }
            
            switch contentVerticalAlignment {
            case .top:
                let titleTotalHeight = titleFrame.height + titlePadding + subtitleFrame.height
                let maxContentHeight = max(imageOrActivityIndicatorFrame.height, titleTotalHeight)
                
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top + (maxContentHeight - imageOrActivityIndicatorFrame.height) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.y = effectiveContentInsets.top + (maxContentHeight - titleTotalHeight) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.y = effectiveContentInsets.top + (maxContentHeight - titleTotalHeight) / 2 + titleFrame.height + titlePadding
                }
            case .center:
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top + (contentSize.height - imageOrActivityIndicatorFrame.height) / 2
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
                let maxContentHeight = max(imageOrActivityIndicatorFrame.height, titleTotalHeight)
                
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.y = bounds.height - effectiveContentInsets.bottom - imageOrActivityIndicatorFrame.height - (maxContentHeight - imageOrActivityIndicatorFrame.height) / 2
                }
                if shouldDisplaySubtitle {
                    subtitleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - (maxContentHeight - titleTotalHeight) / 2
                }
                if shouldDisplayTitle {
                    titleFrame.origin.y = bounds.height - effectiveContentInsets.bottom - subtitleFrame.height - titlePadding - titleFrame.height - (maxContentHeight - titleTotalHeight) / 2
                }
            case .fill:
                if shouldDisplayImageOrActivityIndicator {
                    imageOrActivityIndicatorFrame.origin.y = effectiveContentInsets.top
                    imageOrActivityIndicatorFrame.size.height = contentSize.height
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
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = effectiveContentInsets.left + imageOrActivityIndicatorFrame.width + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = effectiveContentInsets.left + imageOrActivityIndicatorFrame.width + imagePadding
                    }
                case .center:
                    let contentWidth = imageOrActivityIndicatorFrame.width + imagePadding + max(titleFrame.width, subtitleFrame.width)
                    let minX = effectiveContentInsets.left + (contentSize.width - contentWidth) / 2
                    
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = minX
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = minX + imageOrActivityIndicatorFrame.width + imagePadding
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = minX + imageOrActivityIndicatorFrame.width + imagePadding
                    }
                case .right:
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = bounds.width - effectiveContentInsets.right - max(titleFrame.width, subtitleFrame.width) - imagePadding - imageOrActivityIndicatorFrame.width
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = bounds.width - effectiveContentInsets.right - titleFrame.width
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - subtitleFrame.width
                    }
                case .fill:
                    if shouldDisplayImageOrActivityIndicator && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left
                        if shouldDisplayTitle {
                            titleFrame.origin.x = effectiveContentInsets.left + imageOrActivityIndicatorFrame.width + imagePadding
                            titleFrame.size.width = contentSize.width - imagePadding - imageOrActivityIndicatorFrame.width
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left + imageOrActivityIndicatorFrame.width + imagePadding
                            subtitleFrame.size.width = contentSize.width - imagePadding - imageOrActivityIndicatorFrame.width
                        }
                    } else if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left
                        imageOrActivityIndicatorFrame.size.width = contentSize.width
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
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left + max(titleFrame.width, subtitleFrame.width) + imagePadding
                    }
                case .center:
                    let contentWidth = imageOrActivityIndicatorFrame.width + imagePadding + max(titleFrame.width, subtitleFrame.width)
                    let minX = effectiveContentInsets.left + (contentSize.width - contentWidth) / 2
                    
                    if shouldDisplayTitle {
                        titleFrame.origin.x = minX
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = minX
                    }
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = minX + max(titleFrame.width, subtitleFrame.width) + imagePadding
                    }
                case .right:
                    if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = bounds.width - effectiveContentInsets.right - imageOrActivityIndicatorFrame.width
                    }
                    if shouldDisplayTitle {
                        titleFrame.origin.x = bounds.width - effectiveContentInsets.right - imageOrActivityIndicatorFrame.width - imagePadding - titleFrame.width
                    }
                    if shouldDisplaySubtitle {
                        subtitleFrame.origin.x = bounds.width - effectiveContentInsets.right - imageOrActivityIndicatorFrame.width - imagePadding - subtitleFrame.width
                    }
                case .fill:
                    if shouldDisplayImageOrActivityIndicator && (shouldDisplayTitle || shouldDisplaySubtitle) {
                        // Layout image first, the remaining space is reserved for title
                        imageOrActivityIndicatorFrame.origin.x = bounds.width - effectiveContentInsets.right - imageOrActivityIndicatorFrame.width
                        if shouldDisplayTitle {
                            titleFrame.origin.x = effectiveContentInsets.left
                            titleFrame.size.width = imageOrActivityIndicatorFrame.minX - imagePadding - titleFrame.minX
                        }
                        if shouldDisplaySubtitle {
                            subtitleFrame.origin.x = effectiveContentInsets.left
                            subtitleFrame.size.width = imageOrActivityIndicatorFrame.minX - imagePadding - titleFrame.minX
                        }
                    } else if shouldDisplayImageOrActivityIndicator {
                        imageOrActivityIndicatorFrame.origin.x = effectiveContentInsets.left
                        imageOrActivityIndicatorFrame.size.width = contentSize.width
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
        
        if shouldDisplayActivityIndicator {
            activityIndicatorView.frame = imageOrActivityIndicatorFrame
        } else if shouldDisplayImage {
            imageView.frame = imageOrActivityIndicatorFrame
        }
        if shouldDisplayTitle {
            titleLabel.frame = titleFrame
        }
        if shouldDisplaySubtitle {
            subtitleLabel.frame = subtitleFrame
        }
        
        bestSize = nil
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - UI Elements
    
    /// After setting, it can only be called once at most, reassign to refresh the indicator.
    /// A nil value uses `UIActivityIndicatorView`
    open var activityIndicatorProvider: (() -> ButtonActivityIndicatorType)? {
        didSet {
            if oldValue == nil && activityIndicatorProvider == nil { return }
            
            currentActivityIndicatorView?.removeFromSuperview()
            currentActivityIndicatorView = nil
            
            if shouldDisplayActivityIndicator {
                updateForeground()
                layoutForeground()
            }
        }
    }
    
    private var currentActivityIndicatorView: ButtonActivityIndicatorType?
    
    private var activityIndicatorView: ButtonActivityIndicatorType {
        if let currentActivityIndicatorView = currentActivityIndicatorView {
            return currentActivityIndicatorView
        }
        
        let activityIndicatorView = activityIndicatorProvider?() ?? UIActivityIndicatorView()
        activityIndicatorView.indicatorColor = effectiveConfiguration.foregroundColor ?? tintColor
        currentActivityIndicatorView = activityIndicatorView
        return activityIndicatorView
    }
    
    
    private lazy var backgroundView: BackgroundView = {
        let backgroundView = BackgroundView()
        return backgroundView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = effectiveConfiguration.foregroundColor ?? tintColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = effectiveConfiguration.foregroundColor ?? tintColor
        titleLabel.numberOfLines = 0
        return titleLabel
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.textColor = effectiveConfiguration.foregroundColor ?? tintColor
        subtitleLabel.numberOfLines = 0
        return subtitleLabel
    }()
    
    
    // MARK: - Size
    
    // Support for constraint-based layout (auto layout)
    // If not nil, this is used when determining -intrinsicContentSize
    open var preferredMaxLayoutWidthProvider: (() -> CGFloat)? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    private var bestSize: CGSize?
    private var isFittingSize: Bool = false
    
    open override func updateConstraints() {
        super.updateConstraints()
        invalidateIntrinsicContentSize()
    }

    open override var intrinsicContentSize: CGSize {
        if let preferredMaxLayoutWidthProvider = preferredMaxLayoutWidthProvider {
            let limitWidth = preferredMaxLayoutWidthProvider()
            return sizeThatFits(CGSize(width: limitWidth, height: .greatestFiniteMagnitude))
        } else {
            return sizeThatFits(.max)
        }
    }
    
    /// Always set the appropriate size.
    open override func sizeToFit() {
        isFittingSize = true
        super.sizeToFit()
        isFittingSize = false
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var limitSize = size
        if bounds.size.equalTo(size) && isFittingSize {
            limitSize = CGSize.max
        }
        
        // return cached size
        if let bestSize = bestSize, limitSize == CGSize.max {
            return bestSize
        }
        
        var resultSize = CGSize.zero
        
        let shouldDisplayActivityIndicator = self.shouldDisplayActivityIndicator
        let shouldDisplayImage = self.shouldDisplayImage
        let shouldDisplayImageOrActivityIndicator = shouldDisplayActivityIndicator || shouldDisplayImage
        let shouldDisplayTitle = self.shouldDisplayTitle
        let shouldDisplaySubtitle = self.shouldDisplaySubtitle
        
        let imagePadding = shouldDisplayImageOrActivityIndicator && (shouldDisplayTitle || shouldDisplaySubtitle) ? effectiveConfiguration.imagePadding : 0
        let titlePadding = shouldDisplayTitle && shouldDisplaySubtitle ? effectiveConfiguration.titlePadding : 0
        
        let horizontalInset: CGFloat
        let verticalInset: CGFloat
        
        switch effectiveConfiguration.contentInsets {
        case .directional(let insets):
            horizontalInset = insets.leading + insets.trailing
            verticalInset = insets.top + insets.bottom
        case .nondirectional(let insets):
            horizontalInset = insets.left + insets.right
            verticalInset = insets.top + insets.bottom
        }
        
        let contentLimitSize = CGSize(width: limitSize.width - horizontalInset, height: limitSize.height - verticalInset).eraseNegative()
        var imageOrActivityIndicatorSize = CGSize.zero
        var titleSize = CGSize.zero
        var subtitleSize = CGSize.zero
        
        switch effectiveImagePlacement {
        case .top, .bottom:
            if shouldDisplayImageOrActivityIndicator {
                let imageOrActivityIndicatorLimitSize = CGSize(width: contentLimitSize.width, height: CGFloat.greatestFiniteMagnitude)
                if shouldDisplayActivityIndicator {
                    imageOrActivityIndicatorSize = activityIndicatorView.sizeThatFits(imageOrActivityIndicatorLimitSize).limit(to: imageOrActivityIndicatorLimitSize)
                } else if shouldDisplayImage {
                    imageOrActivityIndicatorSize = imageView.sizeThatFits(imageOrActivityIndicatorLimitSize).limit(to: imageOrActivityIndicatorLimitSize)
                }
            }
            if shouldDisplayTitle {
                let titleLimitSize = CGSize(width: contentLimitSize.width, height: contentLimitSize.height - imageOrActivityIndicatorSize.height - imagePadding).eraseNegative()
                titleSize = titleLabel.sizeThatFits(titleLimitSize)
                titleSize.height = min(titleSize.height, titleLimitSize.height)
            }
            if shouldDisplaySubtitle {
                let subtitleLimitSize = CGSize(width: contentLimitSize.width, height: contentLimitSize.height - imageOrActivityIndicatorSize.height - imagePadding - titleSize.height - titlePadding).eraseNegative()
                subtitleSize = subtitleLabel.sizeThatFits(subtitleLimitSize)
                subtitleSize.height = min(subtitleSize.height, subtitleLimitSize.height)
            }
            resultSize.width = horizontalInset + max(imageOrActivityIndicatorSize.width, max(titleSize.width, subtitleSize.width))
            resultSize.height = verticalInset + imageOrActivityIndicatorSize.height + imagePadding + titleSize.height + titlePadding + subtitleSize.height
        case .left, .right, .leading, .trailing:
            if shouldDisplayImageOrActivityIndicator {
                let imageOrActivityIndicatorLimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: contentLimitSize.height)
                if shouldDisplayActivityIndicator {
                    imageOrActivityIndicatorSize = activityIndicatorView.sizeThatFits(imageOrActivityIndicatorLimitSize).limit(to: imageOrActivityIndicatorLimitSize)
                } else if shouldDisplayImage {
                    imageOrActivityIndicatorSize = imageView.sizeThatFits(imageOrActivityIndicatorLimitSize).limit(to: imageOrActivityIndicatorLimitSize)
                }
            }
            if shouldDisplayTitle {
                let titleLimitSize = CGSize(width: contentLimitSize.width - imageOrActivityIndicatorSize.width - imagePadding, height: contentLimitSize.height).eraseNegative()
                titleSize = titleLabel.sizeThatFits(titleLimitSize)
                titleSize.height = min(titleSize.height, titleLimitSize.height)
            }
            if shouldDisplaySubtitle {
                let subtitleLimitSize = CGSize(width: contentLimitSize.width - imageOrActivityIndicatorSize.width - imagePadding, height: contentLimitSize.height).eraseNegative()
                subtitleSize = subtitleLabel.sizeThatFits(subtitleLimitSize)
                subtitleSize.height = min(subtitleSize.height, subtitleLimitSize.height)
            }
            resultSize.width = horizontalInset + imageOrActivityIndicatorSize.width + imagePadding + max(titleSize.width, subtitleSize.width)
            resultSize.height = verticalInset + max(imageOrActivityIndicatorSize.height, titleSize.height + titlePadding + subtitleSize.height)
        }
        
        if limitSize == CGSize.max {
            bestSize = resultSize
        }
        
        return resultSize
    }
    
    
    // MARK: - Override
    
    open override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        super.removeTarget(target, action: action, for: controlEvents)
        
        // Prevent internal target-action from being removed
        let sel = #selector(touchUpInsideTriggered)
        if let actions = actions(forTarget: self, forControlEvent: .touchUpInside) {
            if !actions.contains(NSStringFromSelector(sel)) {
                addTarget(self, action: sel, for: .touchUpInside)
            }
        } else {
            addTarget(self, action: sel, for: .touchUpInside)
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            if isEnabled != oldValue {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            if isSelected != oldValue {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutBackground()
        layoutForeground()
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        updateForegroundColors()
    }
    
    open override var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
        didSet {
            if contentVerticalAlignment != oldValue {
                setNeedsLayout()
            }
        }
    }
    
    open override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        didSet {
            if contentHorizontalAlignment != oldValue {
                setNeedsLayout()
            }
        }
    }
}


private class ButtonConfigurationUpdateTransaction {
   
    private static var observer: CFRunLoopObserver?
    private static var transactionSet: Set<ButtonConfigurationUpdateTransaction>?
    private static func setupMainRunloopObserverIfNecessary() {
        if let _ = observer {
            return
        }
        
        transactionSet = Set<ButtonConfigurationUpdateTransaction>()
        
        observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue, true, 0) { _, _ in
            guard let currentSet = transactionSet, !currentSet.isEmpty else { return }
            transactionSet?.removeAll()
            
            currentSet.forEach { transaction in
                transaction.block()
            }
            
        }
        if let observer = observer {
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, CFRunLoopMode.defaultMode)
        }
    }
    
    
    private let block: () -> Void
    
    public init(_ block: @escaping () -> Void) {
        self.block = block
    }
    
    func commit() {
        Self.setupMainRunloopObserverIfNecessary()
        Self.transactionSet?.insert(self)
    }

}


extension ButtonConfigurationUpdateTransaction: Hashable {
    public static func == (lhs: ButtonConfigurationUpdateTransaction, rhs: ButtonConfigurationUpdateTransaction) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
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

private extension UIColor {
    func withOverlayAlpha(_ alpha: CGFloat) -> UIColor {
        var originalAlpha: CGFloat = 0
        if !self.getRed(nil, green: nil, blue: nil, alpha: &originalAlpha) {
            originalAlpha = 0
        }
        
        return self.withAlphaComponent(originalAlpha * alpha)
    }
}

