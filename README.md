# ConfigurationBasedButton

Custom button inherited from UIControl, which behavior like UIButton.

- Minimum support for iOS 11

- Flexible configuration

- Configuration reusable

- RTL layout adaptation


### Title/Subtitle/Image/Activity Indicator
![截屏2022-09-01 18 09 24](https://user-images.githubusercontent.com/50986450/187889527-53e16cbf-f685-4673-920a-a83963fdbf77.png)
![截屏2022-09-01 18 10 11](https://user-images.githubusercontent.com/50986450/187889654-866abc68-cb66-45e7-bf18-cb763d9db1bb.png)
![截屏2022-09-01 18 10 38](https://user-images.githubusercontent.com/50986450/187889709-67ef39dc-6e9c-4af1-b0b2-f258878752ad.png)
![截屏2022-09-01 18 11 07](https://user-images.githubusercontent.com/50986450/187889801-8d8d7a34-5b6f-47a9-8fe1-3e674ecb08e8.png)


### Image Placement
![截屏2022-09-01 17 58 24](https://user-images.githubusercontent.com/50986450/187887459-c69adea4-cb8b-45ea-ab66-e4bdd85dd281.png)
![截屏2022-09-01 17 59 09](https://user-images.githubusercontent.com/50986450/187887614-807bff14-dff2-429a-9fc3-39ac0d718ea3.png)
![截屏2022-09-01 17 59 31](https://user-images.githubusercontent.com/50986450/187887678-3a4ee628-9ffa-49c2-a9db-d65431367e43.png)
![截屏2022-09-01 17 59 40](https://user-images.githubusercontent.com/50986450/187887702-c011e8bf-afeb-495c-a4bf-22804d71704e.png)


### Background
![截屏2022-09-01 18 14 55](https://user-images.githubusercontent.com/50986450/187890544-4cf61e6f-586d-4d9a-8017-09af0c2a3cae.png)
![截屏2022-09-01 18 17 27](https://user-images.githubusercontent.com/50986450/187891080-a1a04a82-92e4-489d-8b7a-7a6f1db19127.png)
![截屏2022-09-01 18 20 20](https://user-images.githubusercontent.com/50986450/187891633-a5afdd44-58ff-4573-aa98-a5e23195182d.png)
![截屏2022-09-01 18 22 43](https://user-images.githubusercontent.com/50986450/187892082-0a2bcbd3-4b65-4df5-aa37-ca6459eb94e9.png)


### Start
```swift
// Create base configuration.
var baseConfiguration = ButtonConfiguration()
baseConfiguration.title = "Title"
baseConfiguration.subtitle = "Subtitle"
baseConfiguration.image = UIImage(systemName: "house.circle.fill")
baseConfiguration.imagePadding = 10
baseConfiguration.contentInsets = .nondirectional(.init(top: 10, left: 40, bottom: 10, right: 40))

// Create plain-style configuration provider.
let configurationProvider = PlainButtonConfigurationProvider()

// Create button1 with baseConfiguration, configurationProvider and action for `touchUpInside`.
let button1 = ConfigurationBasedButton(baseConfiguration: baseConfiguration, configurationProvider: configurationProvider) { _ in
    print("Button1 has been tapped")
}

// Create button2 with button1's base configuration.
let button2 = ConfigurationBasedButton()
button2.baseConfiguration = button1.baseConfiguration

// Create button3 with current button1's effective configuration.
button1.isHighlighted = true
let button3 = ConfigurationBasedButton(baseConfiguration: button1.effectiveConfiguration)

// Update configuration.
// The UI will not be updated immediately, multiple requests may be coalesced into a single update at the appropriate time.
button1.baseConfiguration.title = "Update Title"
button1.baseConfiguration.image = nil
button1.baseConfiguration.background?.fillColor = UIColor.white
button1.baseConfiguration.background?.cornerStyle = .capsule
```


### Configuration

```swift
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
    
    /// The base color to use for background elements.
    public var foregroundColor: UIColor?
}
```

```swift
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
}
```

### Custom Configuration Provider
```swift
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

```

## Note

This repository does not provide any installation methods like CocoaPods or Swift Package Manager. You are free to copy the codebase and make any custom modifications as per your requirements.
