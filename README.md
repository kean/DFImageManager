<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/5850067/82dd907c-a192-11e4-9735-52401d761b29.png" height="200"/>

</p>
<h1 align="center">DFImageManager</h1>

Modern iOS framework for fetching, caching, processing, and preheating images from various sources. It uses latest advancements in iOS SDK and doesn't reinvent existing technologies. It provides a powerful API that will extend the capabilities of your app.

#### Supported resources
- NSURL with http, https, ftp, file, and data schemes
- PHAsset and NSURL with com.github.kean.photos-kit scheme
- DFALAsset, ALAsset and NSURL with assets-library scheme

## Features
- Zero config yet immense customization and extensibility.
- Uses latest advancements in [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) including [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/). 
- Extreme performance even on outdated devices. Completely asynchronous and thread safe. Performance-critical subsystems run entirely on the background threads.
- Instead of reinventing a caching methodology it relies on HTTP cache as defined in [HTTP specification](https://tools.ietf.org/html/rfc7234) and caching implementation provided by [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html). The caching and revalidation are completely transparent to the client. [Read more](https://github.com/kean/DFImageManager/wiki/Image-Caching-Guide)
- Memory cache layer that stores decompressed and processed images with fine grained control.
- Centralized image decompression, resizing and processing. Image resizing results in a lack of misaligned images and lower memory footprint. Image processing is fully customizable.
- [Automatic preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images that are close to the viewport.
- Groups same requests and never executes them twice. This is true for both fetching and processing. For example, the user creates three requests for the same URL, two of the requests want the image to be resized to the same target size while the other one wants the original image. `DFImageManager` will fetch the original image once, then it will resize it once. `DFImageManager` provides a fine grained control over which requests should be considered equivalent (both in terms of fetching and processing).
- High quality source code base that successfully manages complexity and follows best design principles and patterns, including dependency injection that is used throughout.

## Getting Started
- Download the [latest DFImageManager version](https://github.com/kean/DFImageManager/releases)
- Take a look at the comprehensive [demo projects](https://github.com/kean/DFImageManager/tree/master/DFImageManagerSample)
- Check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager)
- Try `DFImageManager` API in a Swift playground available in the project
- Read guides on project [Wiki](https://github.com/kean/DFImageManager/wiki)
- Install `DFImageManager` using [CocoaPods](http://cocoapods.org), import `<DFImageManager/DFImageManagerKit.h>` and enjoy!

## Requirements
iOS 7.0+

## Installation with [CocoaPods](http://cocoapods.org)

CocoaPods is the dependency manager for Cocoa projects, which automates the process of integrating thrid-party frameworks like DFImageManager. If you are not familiar with CocoaPods the best place to start would be [official CocoaPods guides](http://guides.cocoapods.org).
```ruby
# Podfile example
platform :ios, '7.0'
pod 'DFImageManager'
```

## Examples

#### Zero config image fetching

```objective-c
[[DFImageManager sharedManager] requestImageForResource:[NSURL URLWithString:@"http://..."] completion:^(UIImage *image, NSDictionary *info) {
  // Use decompressed image and inspect info
}];
```

#### Add some options

```objective-c
DFImageRequestOptions *options = [DFImageRequestOptions new];
options.allowsClipping = YES;
options.progressHandler = ^(double progress){
  // Observe progress
};
    
[[DFImageManager sharedManager] requestImageForResource:[NSURL URLWithString:@"http://..."] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:options completion:^(UIImage *image, NSDictionary *info) {
  // Image is resized and clipped to 100x100px square
}];
```

#### Options can be specialized and packed into `DFImageRequest`

Use `DFURLImageRequestOptions` (`DFImageRequestOptions` subclass) to set request cache policy. Create instance of `DFImageRequest` to pack all parameters.
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

#### Create composite requests
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
```objective-c
UIImageView *imageView = ...;
[imageView df_setImageWithResource:[NSURL URLWithString:@"http://..."]];
```

```objective-c
DFImageView *imageView = ...;
// All options are enabled be default
imageView.managesRequestPriorities = YES;
imageView.allowsAnimations = YES; // Animates images when the response isn't fast enough
imageView.allowsAutoRetries = YES; // Retries when network reachability changes
[imageView setImageWithResource:[NSURL URLWithString:@"http://..."]];
```

#### Leverage power of composite managers
The `sharedManager` provided by `DFImageManager` is an instance of `DFCompositeImageManager` class that implements `DFImageManaging` protocol. It dynamically dispatches image requests between multiple image managers that construct a chain of responsibility. What it means is that `sharedManager` doesn't only support URL image fetching, it also supports assets (`PHAsset`, `ALAsset` and their URLs) and it can be easily extended to support your custom classes. For more info see [Using DFCompositeImageManager](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager).
```objective-c
// Use the same `DFImageManaging` API for PHAsset
PHAsset *asset = ...;
[[DFImageManager sharedManager] requestImageForResource:asset targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil completion:^(UIImage *image, NSDictionary *info) {
  // Image resized to 100x100px square
  // Photos Kit image manager does most of the hard work
}];
```

```objective-c
// You can use easily serializable NSURL for fetching too
NSURL *assetURL = [NSURL df_assetURLWithAsset:asset];
    
// And there are Photos Kit-specific options as well
DFPhotosKitImageRequestOptions *options = [DFPhotosKitImageRequestOptions new];
options.version = PHImageRequestOptionsVersionUnadjusted;
options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

// Use full power of polymorphism
DFImageRequest *request = [[DFImageRequest alloc] initWithResource:assetURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options];
```

#### What's more

Those were the most common features. `DFImageManager` jam-packed with features, there are much more options for customization and room for extension. Fore more info check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager) and project [Wiki](https://github.com/kean/DFImageManager/wiki)

## Contribution

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager). (Tag 'dfimagemanager')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager).
- If you **found a bug**, and can provide steps to reliably reproduce it, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Contacts
[Alexander Grebenyuk](https://github.com/kean)

## License
DFImageManager is available under the MIT license. See the LICENSE file for more info.
