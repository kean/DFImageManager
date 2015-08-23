<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/6745579/db90e29a-ce5c-11e4-941d-405ab6729811.png" height="200"/></p>

<h1 align="center">DFImageManager</h1>

<p align="center">
<a href="https://cocoapods.org/pods/DFImageManager"><img src="http://img.shields.io/cocoapods/v/DFImageManager.svg"></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg"></a>
</p>

Advanced iOS framework for loading, caching, processing, displaying and preheating images. It uses latest advancements in iOS SDK and doesn't reinvent existing technologies. It provides a powerful API that will extend the capabilities of your app.

DFImageManager is not just a loader, it's a pipeline for executing image requests using pluggable components. It also features [multiple subspecs](#install_using_cocopods) that automatically integrate things like [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage), [AFNetworking](https://github.com/AFNetworking/AFNetworking), [libwebp](https://developers.google.com/speed/webp/docs/api) and more.

1. [Getting Started](#h_getting_started)
2. [Usage](#h_usage)
3. [Design](#h_design)
4. [Installation](#install_using_cocopods)
5. [Requirements](#h_requirements)
6. [Supported Image Formats](#h_supported_image_formats)
7. [Contribution](#h_contribution)

## <a name="h_features"></a>Features

- Zero config, yet immense customization and flexibility
- Works great with both Objective-C and Swift
- Great performance even on outdated devices, asynchronous and thread safe
- Modular design
- Unit tested

##### Loading
- Uses latest advancements in [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html) including [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) that supports [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2)
- Has basic built-in networking implementation, and optional [AFNetworking integration](#install_using_cocopods) (which should be your primary choice). Combine the power of both frameworks! 
- Groups similar requests and never executes them twice
- [Intelligent preheating](https://github.com/kean/DFImageManager/wiki/Image-Preheating-Guide) of images close to the viewport
- Progress tracking using `NSProgress`

##### Caching
- Instead of reinventing a caching methodology it relies on HTTP cache as defined in [HTTP specification](https://tools.ietf.org/html/rfc7234) and caching implementation provided by [Foundation URL Loading System](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html). The caching and revalidation are completely transparent to the client
- Two cache layers, including [top level memory cache](https://github.com/kean/DFImageManager/wiki/Image-Caching-Guide) for decompressed images

##### Decoding and Processing
- Animated GIF support using best-in-class [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) library
- [WebP](https://developers.google.com/speed/webp/) support
- Progressive image decoding (progressive JPEG and more)
- Background image decompression
- Resize and crop loaded images to [fit displayed size](https://developer.apple.com/library/ios/qa/qa1708/_index.html), add rounded corners or circle

##### Displaying
- Use UI components and UIKit categories
- Automatically manage requests priorities

##### Advanced
- Customize different parts of the framework using dependency injection
- Compose image tasks using `DFCompositeImageTask`. You might use it to show a low-resolution placeholder first and swap to a higher-res one when it is loaded. Or implement custom [revalidation policies](https://github.com/kean/DFImageManager/wiki/Advanced-Image-Caching-Guide#custom-revalidation-using-dfcompositeimagetask)
- Create custom image managers
- [Compose image managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager) into a tree of responsibility
- Extend `DFImageManaging` API using `DFProxyImageManager`

## <a name="h_getting_started"></a>Getting Started
- Download the latest [release](https://github.com/kean/DFImageManager/releases) version
- Take a look at the comprehensive [demo](https://github.com/kean/DFImageManager/tree/master/Demo), it's easy to install with `pod try DFImageManager` command
- Check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager)
- View the growing project [Wiki](https://github.com/kean/DFImageManager/wiki) and [FAQ](https://github.com/kean/DFImageManager/wiki/FAQ)
- Experiment with the APIs in a Swift playground available in the project
- [Install using CocoaPods](#install_using_cocopods), import `<DFImageManager/DFImageManagerKit.h>` and enjoy!
- Check out [Nuke](https://github.com/kean/Nuke) - experimental Swift framework with similar functionality

## <a name="h_usage"></a>Usage

#### Zero Config Image Loading

```objective-c
[[[DFImageManager sharedManager] imageTaskForResource:[NSURL URLWithString:@"http://..."] completion:^(UIImage *image, NSError *error, DFImageResponse *response, DFImageTask *task){
  // Use loaded image
}] resume];
```

#### Adding Request Options

```objective-c
NSURL *imageURL = [NSURL URLWithString:@"http://..."];

DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new]; // builder
options.priority = DFImageRequestPriorityVeryHigh;
options.allowsClipping = YES;

DFImageRequest *request = [DFImageRequest requestWithResource:imageURL targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:options.options];

[[[DFImageManager sharedManager] imageTaskForRequest:request completion:^(UIImage *image, NSError *error, DFImageResponse *response, DFImageTask *imageTask) {
  // Image is resized and clipped to fill 100x100px square
  if (response.isFastResponse) {
    // Image was returned synchronously from the memory cache
  }
}] resume];
```

#### Using Image Task

```objective-c
DFImageTask *imageTask = [[DFImageManager sharedManager] imageTaskForResource:[NSURL URLWithString:@"http://..."] completion:nil];
[imageTask resume];

// Use progress object to track load progress
NSProgress *progress = imageTask.progress;

// Change priority of the already executing task
imageTask.priority = DFImageRequestPriorityHigh;
    
// Cancel image task
[imageTask cancel];
```

#### Progressive Image Decoding

```objective-c
// Create image request that allows progressive image
DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
options.allowsProgressiveImage = YES;
DFImageRequest *request = // Create request with given options

DFImageTask *imageTask = .../ Create image task

// Set progressive image handler
imageTask.progressiveImageHandler = ^(UIImage *__nonnull image){
  imageView.image = image;
};

[imageTask resume]; // Progressive image should also be enabled by DFImageManager
```

#### Preheating Images

```objective-c
NSArray *requestsForAddedItems = ...; // Create image requests
[[DFImageManager sharedManager] startPreheatingImagesForRequests:requestsForAddedItems];
    
NSArray *requestsForRemovedItems = ...; // Create image requests
[[DFImageManager sharedManager] stopPreheatingImagesForRequests:requestsForRemovedItems];
```

#### Using UI Components
Use methods from `UIImageView` category for simple cases:
```objective-c
UIImageView *imageView = ...;
[imageView df_setImageWithResource:[NSURL URLWithString:@"http://..."]];
```

Use `DFImageView` for more advanced features:
```objective-c
DFImageView *imageView = ...;
imageView.allowsAnimations = YES; // Animates images when the response isn't fast enough
imageView.managesRequestPriorities = YES; // Automatically changes current request priority when image view gets added/removed from the window

[imageView prepareForReuse];
[imageView setImageWithResource:[NSURL URLWithString:@"http://..."]];
```

#### Composing Image Tasks
The `DFCompositeImageTask` class manages execution of multiple image requests and provides a single completion block.
```objective-c
DFImageTask *previewImageTask = ...; // Create image task for image preview
DFImageTask *fullsizeImageTask = ...; // Create image task for fullsize image

DFCompositeImageTask *compositeImageTask = [[DFCompositeImageTask alloc] initWithImageTasks:@[previewImageTask, fullsizeImageTask] imageHandler:^(UIImage *image, DFImageTask *completedTask, DFCompositeImageTask *compositeTask){
  // One of the image tasks has completed
} completionHandler:^(DFCompositeImageTask *compositeTask){
  // All tasks has either completed or became obsolete
}];
[compositeImageTask resume];
```
There are many [ways](https://github.com/kean/DFImageManager/wiki/Advanced-Image-Caching-Guide#custom-revalidation-using-dfcompositeimagefetchoperation) how composite requests can be used.

#### Using `DFImageManaging` API for PHAsset

```objective-c
PHAsset *asset = ...;
DFImageRequest *request = [DFImageRequest requestWithResource:asset targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFill options:nil];
[[[DFImageManager sharedManager] imageTaskForRequest:request completion:^(UIImage *image, NSDictionary *info) {
  // Image resized to 100x100px square
}] resume];
```

#### Creating Image Managers
You can either create `DFImageManager` instance with a custom configuration or even provide your own implementation of `DFImageManaging` protocol.
```objective-c
// Create dependencies. You can either use existing classes or provide your own.
id<DFImageFetching> fetcher = ...; // Create image fetcher
id<DFImageDecoding> decoder = ...; // Create image decoder
id<DFImageProcessing> processor = ...; // Create image processor
id<DFImageCaching> cache = ...; // Create image cache

// Create configuration to inject dependencies
DFImageManagerConfiguration *configuration = [[DFImageManagerConfiguration alloc] initWithFetcher:fetcher];
configuration.decoder = decoder;
configuration.processor = processor;
configuration.cache = cache;

// Configure progressive image decoding
configuration.allowsProgressiveImage = YES;
configuration.progressiveImageDecodingThreshold = 0.2;

// Create image manager with configuration
DFImageManager *imageManager = [[DFImageManager alloc] initWithConfiguration:configuration];
```

#### Composing Image Managers
The `DFCompositeImageManager` allows clients to construct a tree of responsibility from multiple image managers, where image requests are dynamically dispatched between them. Each manager should conform to `DFImageManaging` protocol. The `DFCompositeImageManager` also conforms to `DFImageManaging` protocol, which lets clients treat individual objects and compositions uniformly. The default `[DFImageManager sharedManager]` is a composite that contains all built in managers: the ones that support `NSURL` fetching, `PHAsset` objects, etc. 

It's easy for clients to add additional managers to the shared manager. You can either add support for new image requests, or intercept existing ones. For more info see [Composing Image Managers](https://github.com/kean/DFImageManager/wiki/Extending-Image-Manager-Guide#using-dfcompositeimagemanager).

```objective-c
id<DFImageManaging> manager = ...; // Create image manager

// Create composite manager with your custom manager and all built-in managers.
NSArray *managers = @[ manager, [DFImageManager sharedManager] ];
id<DFImageManaging> compositeImageManager = [[DFCompositeImageManager alloc] initWithImageManagers:managers];

// Use dependency injector to set shared manager
[DFImageManager setSharedManager:compositeImageManager];
```

#### What Else

`DFImageManager` is jam-packed with other features. For more info check out the complete [documentation](http://cocoadocs.org/docsets/DFImageManager) and project [Wiki](https://github.com/kean/DFImageManager/wiki)

## <a name="h_design"></a>Design

<img src="https://cloud.githubusercontent.com/assets/1567433/9430006/ee9f9b86-49ec-11e5-9a2b-121d6f6f3384.png" height="420"/>

|Protocol|Description|
|--------|-----------|
|`DFImageManaging`|A high-level API for loading images|
|`DFImageFetching`|Performs fetching of image data (`NSData`)|
|`DFImageDecoding`|Converts `NSData` to `UIImage` objects|
|`DFImageProcessing`|Processes decoded images|
|`DFImageCaching`|Stores processed images into memory cache|

## <a name="install_using_cocopods"></a>Installation with [CocoaPods](http://cocoapods.org)

CocoaPods is the dependency manager for Cocoa projects which automates integration of third-party frameworks. If you are not familiar with CocoaPods the best place to start would be [official CocoaPods guides](http://guides.cocoapods.org). To install DFImageManager add a dependency in your Podfile:
```ruby
# Podfile
platform :ios, '7.0'
pod 'DFImageManager'
```

By default it will install subspecs:
- `DFImageManager/Core` - DFImageManager core classes
- `DFImageManager/UI` - UI components
- `DFImageManager/NSURLSession` - basic networking on top of NSURLSession
- `DFImageManager/PhotosKit` - Photos Framework support

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

## <a name="h_requirements"></a>Requirements
iOS 7.0+

## <a name="h_supported_image_formats"></a>Supported Image Formats
- Image formats supported by `UIImage` (JPEG, PNG, BMP, [and more](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImage_Class/))
- GIF (`GIF` subspec)
- WebP (`WebP` subspec)

## <a name="h_contribution"></a>Contribution
 
- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager). (Tag 'dfimagemanager')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/dfimagemanager).
- If you **found a bug**, and can provide steps to reproduce it, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, branch of the `develop` branch and submit a pull request.

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
