<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/5850067/82dd907c-a192-11e4-9735-52401d761b29.png" height="200"/>

</p>
<h1 align="center">DFImageManager</h1>

Modern iOS framework for fetching, caching, processing, displaying and preheating images from various sources. It uses latest advancements in iOS SDK and doesn't reinvent existing technologies. It provides a powerful API that will extend the capabilities of your app.

#### Supported Resources
- `NSURL` with **http**, **https**, **ftp**, **file**, and **data** schemes
- `PHAsset` and `NSURL` with **com.github.kean.photos-kit** scheme
- `DFALAsset`, `ALAsset` and `NSURL` with **assets-library** scheme

## Features
- Zero config, yet immense customization and extensibility.
- Uses latest advancements in [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) including [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) that supports [SPDY](http://en.wikipedia.org/wiki/SPDY) protocol.
- Instead of reinventing a caching methodology it relies on HTTP cache as defined in [HTTP specification](https://tools.ietf.org/html/rfc7234) and caching implementation provided by [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html). The caching and revalidation are completely transparent to the client. [Read more](https://github.com/kean/DFImageManager/wiki/Image-Caching-Guide)
- The same APIs for different resources (`NSURL`, `PHAsset`, `ALAsset` etc).
- Animated GIF support using best-in-class [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) library.
- Centralized image decompression, resizing and processing. Resizing provides a lack of misaligned images and lower memory footprint. Fully customizable.
- Separate memory cache for decompressed and processed images. Fine grained control over memory cache.
- [Compose image managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager) into a tree of responsibility.
- [Automatic preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images that are close to the viewport.
- Groups similar requests and never executes them twice. This is true for both fetching and processing. Intelligent control over which requests are considered equivalent (both in terms of fetching and processing).
- High quality code base. Follows best design principles and patterns, including _dependency injection_ used throughout.
- Extreme performance even on outdated devices. Asynchronous and thread safe.
- Unit tests help to maintain the project and ensure its future growth.

## Getting Started
- Download the latest [release](https://github.com/kean/DFImageManager/releases) version
- Take a look at the comprehensive [demo projects](https://github.com/kean/DFImageManager/tree/master/DFImageManagerSample)
- Check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager)
- Experiment with the APIs in a Swift playground available in the project
- View growing project [Wiki](https://github.com/kean/DFImageManager/wiki)
- [Install using CocoaPods](#install_using_cocopods), import `<DFImageManager/DFImageManagerKit.h>` and enjoy!

## Requirements
iOS 7.0+

## Usage

#### Zero config image fetching

```objective-c
DFImageRequestID *requestID = [[DFImageManager sharedManager] requestImageForResource:[NSURL URLWithString:@"http://..."] completion:^(UIImage *image, NSDictionary *info) {
  // Use decompressed image and inspect info
}];

[requestID cancel]; // requestID can be used to cancel the request
```

#### Add request options

```objective-c
DFImageRequestOptions *options = [DFImageRequestOptions new];
options.allowsClipping = YES;
options.progressHandler = ^(double progress){
  // Observe progress
};

NSURL *imageURL = [NSURL URLWithString:@"http://..."];
[[DFImageManager sharedManager] requestImageForResource:imageURL targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:options completion:^(UIImage *image, NSDictionary *info) {
  // Image is resized and clipped to fill 100x100px square
}];
```

#### Options can be specialized and packed into `DFImageRequest`

Use `DFURLImageRequestOptions` (`DFImageRequestOptions` subclass) to set request cache policy. Create instance of `DFImageRequest` to pack all request parameters.
```objective-c
DFURLImageRequestOptions *options = [DFURLImageRequestOptions new];
options.allowsClipping = YES;
options.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
options.progressHandler = ^(double progress){
  // Observe progress
};
    
// Use universal image request container
DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://..."] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:options];
    
[[DFImageManager sharedManager] requestImageForRequest:request completion:^(UIImage *image, NSDictionary *info) {
  // Image is resized and clipped to 100x100 px square
}];
```

#### Create composite requests from multiple `DFImageRequest` objects
```objective-c
DFImageRequest *previewRequest = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://preview"]];
DFImageRequest *fullsizeImageRequest = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://fullsize_image"]];

NSArray *requests = @[ previewRequest, fullsizeImageRequest ];
[DFCompositeImageFetchOperation requestImageForRequests:requests handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
  // Handler does just what you would expect
  // For more info see DFCompositeImageFetchOperation docs
}];
```
There are many [smart ways](https://github.com/kean/DFImageManager/wiki/Advanced-Image-Caching-Guide#custom-revalidation-using-dfcompositeimagefetchoperation) how composite requests can be used.

#### Use UI components
Use methods from `UIImageView` category for simple cases:
```objective-c
UIImageView *imageView = ...;
[imageView df_setImageWithResource:[NSURL URLWithString:@"http://..."]];
```

Use `DFImageView` for more advanced features:
```objective-c
DFImageView *imageView = ...;
// All options are enabled be default
imageView.managesRequestPriorities = YES;
imageView.allowsAnimations = YES; // Animates images when the response isn't fast enough
imageView.allowsAutoRetries = YES; // Retries when network reachability changes

[imageView prepareForReuse];
[imageView setImageWithResource:[NSURL URLWithString:@"http://..."]];
// Or use other APIs, for example, set multiple requests [imageView setImageWithRequests:@[ ... ]];
```

#### Use the same `DFImageManaging` APIs for PHAsset, ALAsset and other classes
```objective-c
PHAsset *asset = ...;
[[DFImageManager sharedManager] requestImageForResource:asset targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil completion:^(UIImage *image, NSDictionary *info) {
  // Image resized to 100x100px square
  // Photos Kit image manager does most of the hard work
}];
```

```objective-c
// You can use easily serializable asset NSURL for fetching too
NSURL *assetURL = [NSURL df_assetURLWithAsset:asset];
    
// There are Photos Kit-specific options as well
DFPhotosKitImageRequestOptions *options = [DFPhotosKitImageRequestOptions new];
options.version = PHImageRequestOptionsVersionUnadjusted;
options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

// Use full power of polymorphism
DFImageRequest *request = [[DFImageRequest alloc] initWithResource:assetURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options];
```

#### Leverage power of composite managers
The `DFCompositeImageManager` allows clients to construct a tree of responsibility from multiple image managers, where image requests are dynamically dispatched between them. Each manager should conform to `DFImageManaging` protocol. The `DFCompositeImageManager` also conforms to `DFImageManaging` protocol, which lets clients treat individual objects and compositions uniformly. The default `[DFImageManager sharedManager]` is a composite that contains all built in managers: the ones that support `NSURL` fetching, `PHAsset` objects, etc. 

It's easy for clients to add additional managers to the shared manager. You can either add support for new image requests, or intercept existing onces. For more info see [Composing Image Managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager).

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

Those were the most common cases. `DFImageManager` is packed with features. There are much more options for customization and room for extension. For more info check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager) and project [Wiki](https://github.com/kean/DFImageManager/wiki)

## <a name="install_using_cocopods"></a>Installation with [CocoaPods](http://cocoapods.org)

CocoaPods is the dependency manager for Cocoa projects, which automates the process of integrating third-party frameworks like DFImageManager. If you are not familiar with CocoaPods the best place to start would be [official CocoaPods guides](http://guides.cocoapods.org).
```ruby
# Podfile
platform :ios, '7.0'
pod 'DFImageManager'
```

## Contribution
 
- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager). (Tag 'dfimagemanager')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager).
- If you **found a bug**, and can provide steps to reproduce it, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

`DFImageManager` is constantly improving. Help to make it better!

## Contacts
[Alexander Grebenyuk](https://github.com/kean) ([@a_grebenyuk](https://twitter.com/a_grebenyuk))

## License
DFImageManager is available under the MIT license. See the LICENSE file for more info.
