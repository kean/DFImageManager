<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/6745579/db90e29a-ce5c-11e4-941d-405ab6729811.png" height="200"/></p>

<h1 align="center">DFImageManager</h1>

Advanced iOS framework for loading, caching, processing, displaying and preheating images. It uses latest features in iOS SDK and doesn't reinvent existing technologies. It provides a powerful API that will extend the capabilities of your app.

The DFImageManager is not just a loader, it is a pipeline API for managing image requests, and an ability to easily plug-in everything that your application might need. It features [multiple subspecs](#install_using_cocopods) that integrate things like [AFNetworking](https://github.com/AFNetworking/AFNetworking) as a networking stack for fetching images, and [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) as a performant animated GIF engine, and more.

## Features

- Zero config, yet immense customization and extensibility
- Works great with Swift
- Common APIs for different resources (`NSURL`, `PHAsset`, `ALAsset`, and your custom classes)
- Great performance even on outdated devices, asynchronous and thread safe
- Unit tested

##### Loading
- Uses latest advancements in [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) including [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) that supports [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2)
- Has basic built-in networking implementation, and optional [AFNetworking integration](#install_using_cocopods) which should be your primary choice. Combine the power of both frameworks! 
- Show a low-resolution placeholder(s) first and swap to higher-res one when it is loaded
- Groups similar tasks and never executes them twice

##### Caching
- Instead of reinventing a caching methodology it relies on HTTP cache as defined in [HTTP specification](https://tools.ietf.org/html/rfc7234) and caching implementation provided by [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html). The caching and revalidation are completely transparent to the client
- Separate memory cache for decompressed and processed images. Fine grained control over memory cache

##### Image Formats
- Install subspecs to support additional image formats
- Animated GIF support using best-in-class [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) library
- [WebP](https://developers.google.com/speed/webp/) support

##### Advanced
- [Intelligent preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images that are close to the viewport
- [Compose image managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager) into a tree of responsibility
- Customize different parts of the framework using dependency injection

## Getting Started
- Download the latest [release](https://github.com/kean/DFImageManager/releases) version
- Take a look at the comprehensive [demo](https://github.com/kean/DFImageManager/tree/master/Demo), it's easy to install with `pod try DFImageManager` command
- Check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager)
- View the growing project [Wiki](https://github.com/kean/DFImageManager/wiki) and [FAQ](https://github.com/kean/DFImageManager/wiki/FAQ)
- Experiment with the APIs in a Swift playground available in the project
- [Install using CocoaPods](#install_using_cocopods), import `<DFImageManager/DFImageManagerKit.h>` and enjoy!
- Check out [Nuke](https://github.com/kean/Nuke) - experimental Swift framework with similar functionality

## Requirements
iOS 7.0+

## Usage

#### Zero config image fetching

```objective-c
DFImageTask *task = [[DFImageManager sharedManager] imageTaskForResource:[NSURL URLWithString:@"http://..."] completion:^(UIImage *image, NSDictionary *info) {
  // Use decompressed image and inspect info
}];
[task resume];

[task cancel]; // task can be used to cancel the request (and more)
```

#### Add request options

```objective-c
NSURL *imageURL = [NSURL URLWithString:@"http://..."];

DFImageRequestOptions *options = [DFImageRequestOptions new];
options.allowsClipping = YES;
options.progressHandler = ^(double progress){
// Observe progress
};
options.userInfo = @{ DFURLRequestCachePolicyKey : @(NSURLRequestReturnCacheDataDontLoad) };

DFImageRequest *request = [DFImageRequest requestWithResource:imageURL targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:options];

[[[DFImageManager sharedManager] imageTaskForRequest:request completion:^(UIImage *image, NSDictionary *info) {
// Image is resized and clipped to fill 100x100px square
}] resume];
```

#### Use UI components
Use methods from `UIImageView` category for simple cases:
```objective-c
UIImageView *imageView = ...;
[imageView df_setImageWithResource:[NSURL URLWithString:@"http://..."]];
```

Use `DFImageView` for more advanced features:
```objective-c
DFImageView *imageView = ...;
imageView.allowsAnimations = YES; // Animates images when the response isn't fast enough
imageView.allowsAutoRetries = YES; // Retries when network reachability changes

[imageView prepareForReuse];
[imageView setImageWithResource:[NSURL URLWithString:@"http://..."]];
// Or use other APIs, for example, set multiple requests [imageView setImageWithRequests:@[ ... ]];
```

#### Start multiple requests with a single completion handler
The `DFCompositeImageTask` class manages execution of one or many image requests. It also stores execution state for each request.
```objective-c
DFImageRequest *previewRequest = [DFImageRequest requestWithResource:[NSURL URLWithString:@"http://preview"]];
DFImageRequest *fullsizeRequest = [DFImageRequest requestWithResource:[NSURL URLWithString:@"http://fullsize_image"]];

NSArray *requests = @[ previewRequest, fullsizeRequest ];
DFCompositeImageTask *task = [DFCompositeImageTask requestImageForRequests:requests imageHandler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
  // Handler is called at least once
  // For more info see DFCompositeImageTask class
} completionHandler:nil];
```
There are many [ways](https://github.com/kean/DFImageManager/wiki/Advanced-Image-Caching-Guide#custom-revalidation-using-dfcompositeimagefetchoperation) how composite requests can be used.

#### Use the same `DFImageManaging` API for PHAsset, ALAsset and your custom classes
```objective-c
PHAsset *asset = ...;
DFImageRequest *request = [DFImageRequest requestWithResource:asset targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil];
[[[DFImageManager sharedManager] imageTaskForRequest:request completion:^(UIImage *image, NSDictionary *info) {
  // Image resized to 100x100px square
  // Photos Kit image manager does most of the hard work
}] resume];
```

#### Use composite managers
The `DFCompositeImageManager` allows clients to construct a tree of responsibility from multiple image managers, where image requests are dynamically dispatched between them. Each manager should conform to `DFImageManaging` protocol. The `DFCompositeImageManager` also conforms to `DFImageManaging` protocol, which lets clients treat individual objects and compositions uniformly. The default `[DFImageManager sharedManager]` is a composite that contains all built in managers: the ones that support `NSURL` fetching, `PHAsset` objects, etc. 

It's easy for clients to add additional managers to the shared manager. You can either add support for new image requests, or intercept existing ones. For more info see [Composing Image Managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager).

```objective-c
// Implement custom image fetcher that conforms to DFImageFetching protocol,
// including - (BOOL)canHandleRequest:(DFImageRequest *)request; method
id<DFImageFetching> fetcher = [YourImageFetcher new];
id<DFImageProcessing> processor = [YourImageProcessor new];
id<DFImageCaching> cache = [YourImageMemCache new];

// Create DFImageManager with your configuration.
DFImageManagerConfiguration *configuration = [DFImageManagerConfiguration configurationWithFetcher:fetcher processor:processor cache:cache];
id<DFImageManaging> manager = [[DFImageManager alloc] initWithConfiguration:configuration];

// Create composite manager with your custom manager and all built-in managers.
NSArray *managers = @[ manager, [DFImageManager sharedManager] ];
id<DFImageManaging> compositeImageManager = [[DFCompositeImageManager alloc] initWithImageManagers:managers];

// Use dependency injector to set shared manager
[DFImageManager setSharedManager:compositeImageManager];
```

#### What's more

Those were the most common cases. `DFImageManager` is packed with other features. For more info check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager) and project [Wiki](https://github.com/kean/DFImageManager/wiki)

## Supported Resources
- `NSURL` with **http**, **https**, **ftp**, **file**, and **data** schemes (`AFNetworking` or `NSURLSession` subspec)
- `PHAsset`, `NSURL` with **com.github.kean.photos-kit** scheme (`PhotosKit` subspec)
- `DFALAsset`, `ALAsset`, `NSURL` with **assets-library** scheme (`AssetsLibrary` subspec)

## Supported Image Formats
- Everything supported by `UIImage` (jpg, png, bmp, [and more](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImage_Class/))
- gif (`GIF` subspec)
- webp (`WebP` subspec)

## <a name="install_using_cocopods"></a>Installation with [CocoaPods](http://cocoapods.org)

CocoaPods is the dependency manager for Cocoa projects, which automates the process of integrating third-party frameworks like DFImageManager. If you are not familiar with CocoaPods the best place to start would be [official CocoaPods guides](http://guides.cocoapods.org). To install DFImageManager add a dependency in your Podfile:
```ruby
# Podfile
platform :ios, '7.0'
pod 'DFImageManager'
```

By default it will install subspecs:
- `DFImageManager/Core` - core DFImageManager classes
- `DFImageManager/UI` - UI components
- `DFImageManager/NSURLSession` - basic networking on top of NSURLSession
- `DFImageManager/PhotosKit` - Photos Framework support
- `DFImageManager/AssetsLibrary` - ALAssetsLibrary support

There are three more optional subspecs:
- `DFImageManager/AFNetworking` - replaces networking stack with [AFNetworking](https://github.com/AFNetworking/AFNetworking)
- `DFImageManager/GIF` - GIF support with a [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) dependency
- `DFImageManager/WebP` - WebP support with a [libwebp](https://cocoapods.org/pods/libwebp) dependency

To install optional dependencies include them in your Podfile:
```ruby
# Podfile
platform :ios, '7.0'
pod 'DFImageManager'
pod 'DFImageManager/AFNetworking'
pod 'DFImageManager/GIF'
pod 'DFImageManager/WebP'
```

## Contribution
 
- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager). (Tag 'dfimagemanager')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager).
- If you **found a bug**, and can provide steps to reproduce it, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

`DFImageManager` is constantly improving. Help to make it better!

## Contacts

<a href="https://github.com/kean">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521218/9c7e2502-c378-11e4-9431-c7255cf39577.png" height="44" hspace="2"/>
</a>
<a href="https://twitter.com/a_grebenyuk">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521243/fb085da4-c378-11e4-973e-1eeeac4b5ba5.png" height="44" hspace="2"/>
</a>
<a href="https://www.linkedin.com/pub/alexander-grebenyuk/83/b43/3a0">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521256/20247bc2-c379-11e4-8e9e-417123debb8c.png" height="44" hspace="2"/>
</a>

## License

DFImageManager is available under the MIT license. See the LICENSE file for more info.
